import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/errors/app_failure.dart';
import '../../../domain/units/video_channel.dart';
import '../../../domain/video/stream_request.dart';
import '../../connection/application/connection_controller.dart';

class GridViewState {
  const GridViewState({
    this.items = const [],
    this.opening = false,
    this.message,
  });

  final List<StreamOpenResult> items;
  final bool opening;
  final String? message;
}

class GridController extends AutoDisposeNotifier<GridViewState> {
  String? _unitId;

  @override
  GridViewState build() {
    ref.onDispose(_release);
    return const GridViewState();
  }

  Future<void> start({
    required String unitId,
    required List<VideoChannel> channels,
  }) async {
    _unitId = unitId;
    final endpoint = ref.read(connectionControllerProvider).endpoint ??
        ref.read(localSettingsProvider).read();
    if (endpoint == null) {
      state = const GridViewState(message: 'No hay servidor configurado.');
      return;
    }

    final requests = [
      for (final channel in channels.take(4))
        StreamRequest(
          key: 'ch-${channel.requestChannel}',
          channel: channel.requestChannel,
        ),
    ];
    if (requests.isEmpty) {
      state = const GridViewState(message: 'No hay canales para la grilla.');
      return;
    }

    await _closeAll();
    state = const GridViewState(opening: true);

    try {
      final items = await ref.read(videoTicketPortProvider).openMany(
        endpoint: endpoint,
        unitId: unitId,
        streams: requests,
      );
      state = GridViewState(items: items);
    } on AppFailure catch (failure) {
      if (failure.kind == FailureKind.unauthorized) {
        ref.read(sessionStoreProvider).clear();
      }
      state = GridViewState(message: failure.userMessage);
    } catch (_) {
      state = const GridViewState(message: 'No se pudieron abrir los streams.');
    }
  }

  Future<void> _closeAll() async {
    final unitId = _unitId;
    final endpoint = ref.read(localSettingsProvider).read();
    if (unitId == null || endpoint == null) return;
    for (final item in state.items) {
      final lease = item.ticket?.leaseId;
      if (lease == null || lease.isEmpty) continue;
      await ref.read(videoTicketPortProvider).close(
        endpoint: endpoint,
        unitId: unitId,
        leaseId: lease,
      );
    }
  }

  void _release() {
    final unitId = _unitId;
    final endpoint = ref.read(localSettingsProvider).read();
    if (unitId == null || endpoint == null) return;
    for (final item in state.items) {
      final lease = item.ticket?.leaseId;
      if (lease == null || lease.isEmpty) continue;
      ref.read(videoTicketPortProvider).close(
        endpoint: endpoint,
        unitId: unitId,
        leaseId: lease,
      );
    }
  }
}

final gridControllerProvider =
    NotifierProvider.autoDispose<GridController, GridViewState>(
      GridController.new,
    );
