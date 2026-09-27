import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/errors/app_failure.dart';
import '../../../domain/snapshot/snapshot_image.dart';
import '../../../domain/video/video_ticket.dart';
import '../../connection/application/connection_controller.dart';

class LiveViewState {
  const LiveViewState({
    this.ticket,
    this.subtype = 1,
    this.opening = false,
    this.playing = false,
    this.capturing = false,
    this.message,
    this.snapshotMessage,
  });

  final VideoTicket? ticket;

  /// 0 = Main, 1 = Substream.
  final int subtype;
  final bool opening;
  final bool playing;
  final bool capturing;
  final String? message;
  final String? snapshotMessage;

  bool get isMain => subtype == 0;

  LiveViewState copyWith({
    VideoTicket? ticket,
    int? subtype,
    bool? opening,
    bool? playing,
    bool? capturing,
    String? message,
    String? snapshotMessage,
    bool clearMessage = false,
    bool clearSnapshotMessage = false,
  }) {
    return LiveViewState(
      ticket: ticket ?? this.ticket,
      subtype: subtype ?? this.subtype,
      opening: opening ?? this.opening,
      playing: playing ?? this.playing,
      capturing: capturing ?? this.capturing,
      message: clearMessage ? null : (message ?? this.message),
      snapshotMessage: clearSnapshotMessage
          ? null
          : (snapshotMessage ?? this.snapshotMessage),
    );
  }
}

class LiveController extends AutoDisposeNotifier<LiveViewState> {
  String? _unitId;
  int _channel = 1;
  var _subtype = 1;
  var _autoRetries = 0;
  var _fellBackFromMain = false;

  @override
  LiveViewState build() {
    ref.onDispose(_release);
    return const LiveViewState();
  }

  Future<void> start({required String unitId, required int channel}) async {
    _unitId = unitId;
    _channel = channel;
    _subtype = 1;
    _autoRetries = 0;
    _fellBackFromMain = false;
    await _open();
  }

  Future<void> retry() async {
    _autoRetries = 0;
    await _open();
  }

  Future<void> selectSubtype(int subtype) async {
    if (subtype != 0 && subtype != 1) return;
    if (subtype == _subtype && state.ticket != null && !state.opening) return;
    _subtype = subtype;
    _autoRetries = 0;
    if (subtype == 0) _fellBackFromMain = false;
    await _open();
  }

  void markPlaying() {
    if (state.playing) return;
    state = state.copyWith(playing: true);
  }

  Future<SnapshotImage?> captureSnapshot() async {
    final unitId = _unitId;
    final endpoint = ref.read(localSettingsProvider).read();
    if (unitId == null || endpoint == null) {
      state = state.copyWith(snapshotMessage: 'No hay servidor configurado.');
      return null;
    }
    state = state.copyWith(capturing: true, clearSnapshotMessage: true);
    try {
      final image = await ref.read(snapshotRepositoryProvider).capture(
        endpoint: endpoint,
        unitId: unitId,
        channel: _channel,
        subtype: _subtype,
      );
      state = state.copyWith(capturing: false);
      return image;
    } on AppFailure catch (failure) {
      if (failure.kind == FailureKind.unauthorized) {
        ref.read(sessionStoreProvider).clear();
      }
      state = state.copyWith(
        capturing: false,
        snapshotMessage: failure.userMessage,
      );
      return null;
    } catch (_) {
      state = state.copyWith(
        capturing: false,
        snapshotMessage: 'No se pudo capturar el snapshot.',
      );
      return null;
    }
  }

  Future<void> onPlayerFailed() async {
    if (_subtype == 0 && !_fellBackFromMain) {
      _fellBackFromMain = true;
      _subtype = 1;
      _autoRetries = 0;
      await _open(
        becauseBroken: true,
        message:
            'No se pudo reproducir el Main Stream (suele ser H.265). Pasamos a Substream.',
      );
      return;
    }

    if (_autoRetries >= 2) {
      await _closeCurrent();
      state = LiveViewState(
        subtype: _subtype,
        message: 'El video se cortó. Pedí un ticket nuevo con Reintentar.',
      );
      return;
    }
    _autoRetries += 1;
    await _open(becauseBroken: true);
  }

  Future<void> _open({bool becauseBroken = false, String? message}) async {
    final unitId = _unitId;
    final endpoint = ref.read(connectionControllerProvider).endpoint ??
        ref.read(localSettingsProvider).read();
    if (unitId == null || endpoint == null) {
      state = const LiveViewState(
        message: 'No hay servidor o unidad para abrir el video.',
      );
      return;
    }

    await _closeCurrent();
    state = LiveViewState(
      subtype: _subtype,
      opening: true,
      message: message ?? (becauseBroken ? 'Reconectando…' : null),
    );

    try {
      final ticket = await ref.read(videoTicketPortProvider).open(
        endpoint: endpoint,
        unitId: unitId,
        channel: _channel,
        subtype: _subtype,
      );
      state = LiveViewState(
        ticket: ticket,
        subtype: ticket.subtype,
        message: message,
      );
    } on AppFailure catch (failure) {
      if (failure.kind == FailureKind.unauthorized) {
        ref.read(sessionStoreProvider).clear();
      }
      state = LiveViewState(subtype: _subtype, message: failure.userMessage);
    } catch (_) {
      state = LiveViewState(
        subtype: _subtype,
        message: 'No se pudo abrir el video.',
      );
    }
  }

  Future<void> _closeCurrent() async {
    final ticket = state.ticket;
    final unitId = _unitId;
    final endpoint = ref.read(localSettingsProvider).read();
    if (ticket == null || unitId == null || endpoint == null) return;
    await ref.read(videoTicketPortProvider).close(
      endpoint: endpoint,
      unitId: unitId,
      leaseId: ticket.leaseId,
    );
  }

  void _release() {
    final ticket = state.ticket;
    final unitId = _unitId;
    final endpoint = ref.read(localSettingsProvider).read();
    if (ticket == null || unitId == null || endpoint == null) return;
    ref.read(videoTicketPortProvider).close(
      endpoint: endpoint,
      unitId: unitId,
      leaseId: ticket.leaseId,
    );
  }
}

final liveControllerProvider =
    NotifierProvider.autoDispose<LiveController, LiveViewState>(
      LiveController.new,
    );
