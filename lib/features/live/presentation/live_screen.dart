import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/player/maic_vlc_view.dart';
import '../../../data/storage/local_settings.dart';
import '../../../ui/theme/maic_colors.dart';
import '../../../ui/widgets/maic_chrome.dart';
import '../../connection/application/connection_controller.dart';
import '../../snapshot/presentation/snapshot_view_screen.dart';
import '../application/live_controller.dart';

class LiveScreen extends ConsumerStatefulWidget {
  const LiveScreen({
    super.key,
    required this.unitId,
    required this.channel,
    required this.title,
  });

  final String unitId;
  final int channel;
  final String title;

  @override
  ConsumerState<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends ConsumerState<LiveScreen> {
  final _stageKey = GlobalKey();
  var _fullscreen = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(liveControllerProvider.notifier).start(
        unitId: widget.unitId,
        channel: widget.channel,
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_restoreChrome());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveControllerProvider);
    final isDemo =
        ref.watch(connectionControllerProvider).kind == DataSourceKind.mock;
    final streamLabel = state.isMain ? 'Main' : 'Sub';
    final stage = _videoStage(state);

    return PopScope(
      canPop: !_fullscreen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _fullscreen) unawaited(_setFullscreen(false));
      },
      child: _fullscreen
          ? Scaffold(
              backgroundColor: Colors.black,
              body: stage,
            )
          : Scaffold(
              appBar: AppBar(
                backgroundColor: MaicColors.bgTop,
                title: Text(widget.title.toUpperCase()),
                actions: [
                  IconButton(
                    tooltip: 'Pantalla completa',
                    onPressed: () => unawaited(_setFullscreen(true)),
                    icon: const Icon(Icons.fullscreen),
                  ),
                  IconButton(
                    tooltip: 'Snapshot',
                    onPressed: state.capturing ? null : _snapshot,
                    icon: const Icon(Icons.photo_camera_outlined),
                  ),
                ],
              ),
              body: MaicBackdrop(
                child: SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    children: [
                      MaicPanel(
                        padding: const EdgeInsets.all(8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: stage,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      MaicPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const MaicIconBadge(icon: Icons.videocam_outlined),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Canal ${widget.channel} · $streamLabel',
                                        style: const TextStyle(
                                          color: MaicColors.muted,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const MaicSectionTitle('CALIDAD'),
                            const SizedBox(height: 10),
                            SegmentedButton<int>(
                              showSelectedIcon: false,
                              segments: const [
                                ButtonSegment(value: 1, label: Text('Sub')),
                                ButtonSegment(value: 0, label: Text('Main')),
                              ],
                              selected: {state.subtype},
                              onSelectionChanged: (value) {
                                if (state.opening) return;
                                ref
                                    .read(liveControllerProvider.notifier)
                                    .selectSubtype(value.first);
                              },
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(46),
                              ),
                              onPressed: state.capturing ? null : _snapshot,
                              child: state.capturing
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Snapshot'),
                            ),
                            if (state.snapshotMessage != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                state.snapshotMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: MaicColors.muted),
                              ),
                            ],
                            if (state.message != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                state.message!,
                                textAlign: TextAlign.center,
                              ),
                              if (!state.opening) ...[
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () => ref
                                      .read(liveControllerProvider.notifier)
                                      .retry(),
                                  child: const Text('Reintentar'),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                      if (isDemo) ...[
                        const SizedBox(height: 16),
                        const MaicPanel(
                          child: Text(
                            'Modo demo: clip local en Sub y Main. El snapshot lo pide el server; no es un fotograma del clip.',
                            style: TextStyle(color: MaicColors.muted),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _videoStage(LiveViewState state) {
    return KeyedSubtree(
      key: _stageKey,
      child: ColoredBox(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _player(state),
            Positioned(
              left: 10,
              top: 10,
              child: _fullscreen
                  ? SafeArea(child: _LiveBadge(state: state))
                  : _LiveBadge(state: state),
            ),
            Positioned(
              right: 6,
              top: 6,
              child: _fullscreen
                  ? SafeArea(child: _overlayActions(state))
                  : _overlayActions(state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _overlayActions(LiveViewState state) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_fullscreen)
          _OverlayButton(
            tooltip: 'Snapshot',
            icon: Icons.photo_camera_outlined,
            onPressed: state.capturing ? null : _snapshot,
          ),
        _OverlayButton(
          tooltip: _fullscreen
              ? 'Salir de pantalla completa'
              : 'Pantalla completa',
          icon: _fullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
          onPressed: () => unawaited(_setFullscreen(!_fullscreen)),
        ),
      ],
    );
  }

  Future<void> _setFullscreen(bool enabled) async {
    if (_fullscreen == enabled) return;
    setState(() => _fullscreen = enabled);
    if (enabled) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      return;
    }
    await _restoreChrome();
  }

  Future<void> _restoreChrome() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);
  }

  Future<void> _snapshot() async {
    final image =
        await ref.read(liveControllerProvider.notifier).captureSnapshot();
    if (image == null || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SnapshotViewScreen(image: image, title: widget.title),
      ),
    );
  }

  Widget _player(LiveViewState state) {
    if (state.opening && state.ticket == null) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final ticket = state.ticket;
    if (ticket == null) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.videocam_off_outlined,
                size: 40,
                color: MaicColors.muted,
              ),
              SizedBox(height: 8),
              Text(
                'Sin señal',
                style: TextStyle(color: MaicColors.muted),
              ),
            ],
          ),
        ),
      );
    }
    return MaicVlcView(
      key: ValueKey(ticket.leaseId.isEmpty ? ticket.streamUrl : ticket.leaseId),
      streamUrl: ticket.streamUrl,
      onPlaying: () => ref.read(liveControllerProvider.notifier).markPlaying(),
      onError: () => ref.read(liveControllerProvider.notifier).onPlayerFailed(),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  const _OverlayButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xCC0B1210),
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.state});

  final LiveViewState state;

  @override
  Widget build(BuildContext context) {
    final label = state.playing
        ? 'EN VIVO'
        : state.opening
        ? 'ABRIENDO'
        : state.ticket == null
        ? 'SIN SEÑAL'
        : 'LISTO';
    final color = state.playing ? MaicColors.accent : MaicColors.muted;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCC0B1210),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
