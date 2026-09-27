import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/errors/app_failure.dart';
import '../../../domain/snapshot/snapshot_image.dart';
import '../../../domain/units/unit.dart';
import '../../../domain/units/video_channel.dart';
import '../../connection/application/connection_controller.dart';
import 'units_controller.dart';

class UnitDetailState {
  const UnitDetailState({
    this.unit,
    this.channels = const [],
    this.loading = false,
    this.acting = false,
    this.message,
    this.actionMessage,
  });

  final MaicUnit? unit;
  final List<VideoChannel> channels;
  final bool loading;
  final bool acting;
  final String? message;
  final String? actionMessage;

  UnitDetailState copyWith({
    MaicUnit? unit,
    List<VideoChannel>? channels,
    bool? loading,
    bool? acting,
    String? message,
    String? actionMessage,
    bool clearMessage = false,
    bool clearActionMessage = false,
  }) {
    return UnitDetailState(
      unit: unit ?? this.unit,
      channels: channels ?? this.channels,
      loading: loading ?? this.loading,
      acting: acting ?? this.acting,
      message: clearMessage ? null : (message ?? this.message),
      actionMessage: clearActionMessage
          ? null
          : (actionMessage ?? this.actionMessage),
    );
  }
}

class UnitDetailController extends FamilyNotifier<UnitDetailState, String> {
  @override
  UnitDetailState build(String unitId) {
    return UnitDetailState(unit: _cached(unitId), loading: true);
  }

  Future<void> refresh() async {
    final endpoint = ref.read(connectionControllerProvider).endpoint ??
        ref.read(localSettingsProvider).read();
    final cached = _cached(arg);
    if (endpoint == null) {
      state = UnitDetailState(
        unit: cached,
        loading: false,
        message: 'No hay servidor configurado.',
      );
      return;
    }

    state = state.copyWith(unit: cached, loading: true, clearMessage: true);
    try {
      final channels = await ref.read(unitCatalogPortProvider).refreshChannels(
        endpoint: endpoint,
        unitId: arg,
        defaultCameraChannel: cached?.isCamera ?? false,
      );
      state = UnitDetailState(
        unit: cached?.copyWith(channels: channels),
        channels: channels,
        loading: false,
      );
    } on AppFailure catch (failure) {
      _onFailure(failure);
      state = state.copyWith(
        unit: cached,
        loading: false,
        message: failure.userMessage,
      );
    } catch (_) {
      state = state.copyWith(
        unit: cached,
        loading: false,
        message: 'No se pudo leer el inventario de canales.',
      );
    }
  }

  Future<SnapshotImage?> captureSnapshot(int channel) async {
    final endpoint = ref.read(localSettingsProvider).read();
    if (endpoint == null) {
      state = state.copyWith(actionMessage: 'No hay servidor configurado.');
      return null;
    }
    state = state.copyWith(acting: true, clearActionMessage: true);
    try {
      final image = await ref.read(snapshotRepositoryProvider).capture(
        endpoint: endpoint,
        unitId: arg,
        channel: channel,
      );
      state = state.copyWith(acting: false);
      return image;
    } on AppFailure catch (failure) {
      _onFailure(failure);
      state = state.copyWith(acting: false, actionMessage: failure.userMessage);
      return null;
    } catch (_) {
      state = state.copyWith(
        acting: false,
        actionMessage: 'No se pudo capturar el snapshot.',
      );
      return null;
    }
  }

  Future<void> pulseRelay() async {
    final endpoint = ref.read(localSettingsProvider).read();
    if (endpoint == null) {
      state = state.copyWith(actionMessage: 'No hay servidor configurado.');
      return;
    }
    state = state.copyWith(acting: true, clearActionMessage: true);
    try {
      final message = await ref.read(actuatorRepositoryProvider).pulseRelay(
        endpoint: endpoint,
        unitId: arg,
      );
      state = state.copyWith(acting: false, actionMessage: message);
    } on AppFailure catch (failure) {
      _onFailure(failure);
      state = state.copyWith(acting: false, actionMessage: failure.userMessage);
    } catch (_) {
      state = state.copyWith(
        acting: false,
        actionMessage: 'No se pudo pulsar el relé.',
      );
    }
  }

  void _onFailure(AppFailure failure) {
    if (failure.kind == FailureKind.unauthorized) {
      ref.read(sessionStoreProvider).clear();
    }
  }

  MaicUnit? _cached(String unitId) {
    for (final unit in ref.read(unitsControllerProvider).units) {
      if (unit.id == unitId) return unit;
    }
    return null;
  }
}

final unitDetailControllerProvider = NotifierProvider.family<
  UnitDetailController,
  UnitDetailState,
  String
>(UnitDetailController.new);
