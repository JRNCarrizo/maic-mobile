import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/units/unit.dart';
import '../../../domain/units/video_channel.dart';
import '../../../ui/theme/maic_colors.dart';
import '../../../ui/widgets/maic_chrome.dart';
import '../../snapshot/presentation/snapshot_view_screen.dart';
import '../application/unit_detail_controller.dart';

class UnitDetailScreen extends ConsumerStatefulWidget {
  const UnitDetailScreen({super.key, required this.unitId});

  final String unitId;

  @override
  ConsumerState<UnitDetailScreen> createState() => _UnitDetailScreenState();
}

class _UnitDetailScreenState extends ConsumerState<UnitDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(unitDetailControllerProvider(widget.unitId).notifier)
          .refresh(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(unitDetailControllerProvider(widget.unitId));
    final unit = state.unit;
    final notifier = ref.read(unitDetailControllerProvider(widget.unitId).notifier);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: MaicColors.bgTop,
        title: Text(unit?.displayName.toUpperCase() ?? 'UNIDAD'),
      ),
      body: MaicBackdrop(
        child: SafeArea(
          child: RefreshIndicator(
            color: MaicColors.accent,
            onRefresh: notifier.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                if (unit != null) ...[
                  MaicPanel(
                    child: Row(
                      children: [
                        MaicIconBadge(
                          icon: unit.isRecorder
                              ? Icons.dns_outlined
                              : Icons.videocam_outlined,
                          color: _statusColor(unit.online),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                unit.kindLabel,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _statusLabel(unit.online),
                                style: const TextStyle(color: MaicColors.muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                const MaicSectionTitle('CANALES'),
                const SizedBox(height: 10),
                if (state.loading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: LinearProgressIndicator(),
                  ),
                if (state.message != null) ...[
                  Text(state.message!),
                  const SizedBox(height: 8),
                ],
                if (!state.loading &&
                    state.channels.isEmpty &&
                    state.message == null)
                  const MaicPanel(
                    child: Text('El servidor no publicó canales para esta unidad.'),
                  ),
                for (final channel in state.channels) ...[
                  _ChannelTile(
                    channel: channel,
                    acting: state.acting,
                    onSnapshot: () => _snapshot(channel),
                    onLive: () => context.push(
                      Uri(
                        path: '/live/${widget.unitId}',
                        queryParameters: {
                          'channel': '${channel.requestChannel}',
                          'name': channel.name,
                        },
                      ).toString(),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (state.channels.length >= 2) ...[
                  const SizedBox(height: 4),
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                    ),
                    onPressed: () => context.push(
                      Uri(
                        path: '/grid/${widget.unitId}',
                        queryParameters: {
                          'name': unit?.displayName ?? 'Grilla',
                        },
                      ).toString(),
                      extra: state.channels,
                    ),
                    child: Text('Ver ${state.channels.length} en vivo'),
                  ),
                ],
                if (unit?.isRecorder == true) ...[
                  const SizedBox(height: 24),
                  const MaicSectionTitle('ACCIONES'),
                  const SizedBox(height: 10),
                  MaicPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Salida del grabador. Un pulso corto, no por cámara.',
                          style: TextStyle(color: MaicColors.muted),
                        ),
                        const SizedBox(height: 14),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(46),
                          ),
                          onPressed:
                              state.acting ? null : () => notifier.pulseRelay(),
                          child: const Text('Pulso de relé'),
                        ),
                      ],
                    ),
                  ),
                ],
                if (state.actionMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(state.actionMessage!, textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _snapshot(VideoChannel channel) async {
    final image = await ref
        .read(unitDetailControllerProvider(widget.unitId).notifier)
        .captureSnapshot(channel.requestChannel);
    if (image == null || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SnapshotViewScreen(image: image, title: channel.name),
      ),
    );
  }

  Color _statusColor(OnlineKind online) {
    return switch (online) {
      OnlineKind.online => MaicColors.accent,
      OnlineKind.offline => MaicColors.offline,
      OnlineKind.unknown => MaicColors.muted,
    };
  }

  String _statusLabel(OnlineKind online) {
    return switch (online) {
      OnlineKind.online => 'En línea',
      OnlineKind.offline => 'Sin conexión',
      OnlineKind.unknown => 'Estado desconocido',
    };
  }
}

class _ChannelTile extends StatelessWidget {
  const _ChannelTile({
    required this.channel,
    required this.acting,
    required this.onSnapshot,
    required this.onLive,
  });

  final VideoChannel channel;
  final bool acting;
  final VoidCallback onSnapshot;
  final VoidCallback onLive;

  @override
  Widget build(BuildContext context) {
    return MaicPanel(
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
      child: Row(
        children: [
          const MaicIconBadge(icon: Icons.videocam_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(channel.name),
                const SizedBox(height: 2),
                Text(
                  [
                    'Canal ${channel.requestChannel}',
                    if (channel.state.isNotEmpty) channel.state,
                  ].join(' · '),
                  style: const TextStyle(color: MaicColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Snapshot',
            onPressed: acting ? null : onSnapshot,
            icon: const Icon(Icons.photo_camera_outlined),
          ),
          IconButton(
            tooltip: 'Live',
            onPressed: onLive,
            icon: const Icon(Icons.play_circle_outline),
          ),
        ],
      ),
    );
  }
}
