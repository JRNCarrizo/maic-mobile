import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/errors/app_failure.dart';
import '../../../domain/layouts/last_view.dart';
import '../../../domain/units/unit.dart';
import '../../connection/application/connection_controller.dart';

class UnitsViewState {
  const UnitsViewState({
    this.units = const [],
    this.query = '',
    this.loading = false,
    this.message,
    this.lastUnit,
  });

  final List<MaicUnit> units;
  final String query;
  final bool loading;
  final String? message;
  final MaicUnit? lastUnit;

  List<MaicUnit> get visible {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return units;
    return units
        .where((unit) => unit.displayName.toLowerCase().contains(needle))
        .toList();
  }

  UnitsViewState copyWith({
    List<MaicUnit>? units,
    String? query,
    bool? loading,
    String? message,
    MaicUnit? lastUnit,
    bool clearMessage = false,
    bool clearLast = false,
  }) {
    return UnitsViewState(
      units: units ?? this.units,
      query: query ?? this.query,
      loading: loading ?? this.loading,
      message: clearMessage ? null : (message ?? this.message),
      lastUnit: clearLast ? null : (lastUnit ?? this.lastUnit),
    );
  }
}

class UnitsController extends Notifier<UnitsViewState> {
  @override
  UnitsViewState build() => const UnitsViewState();

  Future<void> load() async {
    final endpoint = ref.read(connectionControllerProvider).endpoint ??
        ref.read(localSettingsProvider).read();
    if (endpoint == null) {
      state = const UnitsViewState(message: 'No hay servidor configurado.');
      return;
    }

    state = state.copyWith(loading: true, clearMessage: true);
    try {
      final units = await ref.read(unitCatalogPortProvider).listViewerUnits(
        endpoint,
      );
      MaicUnit? lastUnit;
      try {
        final last = await ref.read(layoutPortProvider).readLast(endpoint);
        if (last != null) {
          for (final unit in units) {
            if (unit.id == last.unitId) {
              lastUnit = unit;
              break;
            }
          }
        }
      } catch (_) {}
      state = UnitsViewState(
        units: units,
        query: state.query,
        lastUnit: lastUnit,
      );
    } on AppFailure catch (failure) {
      if (failure.kind == FailureKind.unauthorized) {
        ref.read(sessionStoreProvider).clear();
      }
      state = state.copyWith(loading: false, message: failure.userMessage);
    } catch (_) {
      state = state.copyWith(
        loading: false,
        message: 'No se pudieron cargar las unidades.',
      );
    }
  }

  void search(String query) {
    state = state.copyWith(query: query);
  }

  Future<void> remember(MaicUnit unit) async {
    final endpoint = ref.read(localSettingsProvider).read();
    if (endpoint == null) return;
    await ref.read(layoutPortProvider).saveLast(
      endpoint,
      LastView(unitId: unit.id),
    );
    state = state.copyWith(lastUnit: unit);
  }
}

final unitsControllerProvider =
    NotifierProvider<UnitsController, UnitsViewState>(UnitsController.new);
