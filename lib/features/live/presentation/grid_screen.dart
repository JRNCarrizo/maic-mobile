import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/player/maic_vlc_view.dart';
import '../../../data/storage/local_settings.dart';
import '../../../domain/units/video_channel.dart';
import '../../../domain/video/stream_request.dart';
import '../../../ui/theme/maic_colors.dart';
import '../../../ui/widgets/maic_chrome.dart';
import '../../connection/application/connection_controller.dart';
import '../application/grid_controller.dart';

class GridScreen extends ConsumerStatefulWidget {
  const GridScreen({
    super.key,
    required this.unitId,
    required this.title,
    required this.channels,
  });

  final String unitId;
  final String title;
  final List<VideoChannel> channels;

  @override
  ConsumerState<GridScreen> createState() => _GridScreenState();
}

class _GridScreenState extends ConsumerState<GridScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(gridControllerProvider.notifier).start(
        unitId: widget.unitId,
        channels: widget.channels,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gridControllerProvider);
    final isDemo =
        ref.watch(connectionControllerProvider).kind == DataSourceKind.mock;
    final visible = widget.channels.take(4).toList();
    final count = state.items.isEmpty ? visible.length : state.items.length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: MaicColors.bgTop,
        title: Text(widget.title.toUpperCase()),
      ),
      body: MaicBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                child: MaicPanel(
                  child: Row(
                    children: [
                      const MaicIconBadge(icon: Icons.grid_view_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'En vivo',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$count canales · Sub',
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
                ),
              ),
              if (state.message != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    state.message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: MaicColors.muted),
                  ),
                ),
              Expanded(
                child: state.opening && state.items.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(6, 2, 6, 8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 8,
                          childAspectRatio: 16 / 13,
                        ),
                        itemCount: count,
                        itemBuilder: (context, index) {
                          if (state.items.isEmpty) {
                            final channel = visible[index];
                            return _GridCell(
                              title: channel.name,
                              subtitle: 'Canal ${channel.requestChannel}',
                              onOpen: () => _openLive(channel),
                              child: const _CellPlaceholder(
                                label: 'Abriendo…',
                              ),
                            );
                          }
                          return _resultCell(state.items[index]);
                        },
                      ),
              ),
              if (isDemo)
                const Padding(
                  padding: EdgeInsets.fromLTRB(8, 0, 8, 12),
                  child: MaicPanel(
                    child: Text(
                      'Modo demo: cada celda es un ticket. Una puede fallar sin tumbar el resto.',
                      style: TextStyle(color: MaicColors.muted),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultCell(StreamOpenResult item) {
    VideoChannel? channel;
    for (final candidate in widget.channels) {
      if (candidate.requestChannel == item.channel) {
        channel = candidate;
        break;
      }
    }
    final title = channel?.name ?? 'Canal ${item.channel}';
    if (!item.success || item.ticket == null) {
      return _GridCell(
        title: title,
        subtitle: item.userMessage ?? 'Sin señal',
        failed: true,
        onOpen: channel == null ? null : () => _openLive(channel!),
        child: const _CellPlaceholder(
          icon: Icons.videocam_off_outlined,
          label: 'Sin señal',
        ),
      );
    }
    final ticket = item.ticket!;
    return _GridCell(
      title: title,
      subtitle: 'Canal ${item.channel} · Sub',
      live: true,
      onOpen: channel == null ? null : () => _openLive(channel!),
      child: MaicVlcView(
        key: ValueKey(ticket.leaseId),
        streamUrl: ticket.streamUrl,
        startOffset: Duration(milliseconds: 700 * item.channel),
      ),
    );
  }

  void _openLive(VideoChannel channel) {
    context.push(
      Uri(
        path: '/live/${widget.unitId}',
        queryParameters: {
          'channel': '${channel.requestChannel}',
          'name': channel.name,
        },
      ).toString(),
    );
  }
}

class _GridCell extends StatelessWidget {
  const _GridCell({
    required this.title,
    required this.subtitle,
    required this.child,
    this.onOpen,
    this.live = false,
    this.failed = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onOpen;
  final bool live;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    return MaicPanel(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        splashFactory: NoSplash.splashFactory,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: Colors.black, child: child),
                    Positioned(
                      left: 6,
                      top: 6,
                      child: _StatusChip(
                        live: live,
                        failed: failed,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: MaicColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.live, required this.failed});

  final bool live;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final label = failed
        ? 'SIN SEÑAL'
        : live
        ? 'EN VIVO'
        : 'ABRIENDO';
    final color = failed
        ? MaicColors.offline
        : live
        ? MaicColors.accent
        : MaicColors.muted;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCC0B1210),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            letterSpacing: 0.7,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _CellPlaceholder extends StatelessWidget {
  const _CellPlaceholder({
    this.label = 'Sin ticket',
    this.icon = Icons.hourglass_empty,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: MaicColors.muted, size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: MaicColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
