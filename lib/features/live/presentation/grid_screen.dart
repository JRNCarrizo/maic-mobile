import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/player/maic_vlc_view.dart';
import '../../../data/storage/local_settings.dart';
import '../../../domain/units/video_channel.dart';
import '../../../domain/video/stream_request.dart';
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
    final cells = state.items.isEmpty
        ? widget.channels.take(4).toList()
        : state.items;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: state.opening && state.items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 16 / 11,
                    ),
                    itemCount: cells.length,
                    itemBuilder: (context, index) {
                      if (state.items.isEmpty) {
                        final channel = widget.channels[index];
                        return _Cell(
                          title: channel.name,
                          child: const Center(child: Text('Sin ticket')),
                        );
                      }
                      return _resultCell(state.items[index]);
                    },
                  ),
          ),
          if (isDemo)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Modo demo: cada celda es un ticket. Una puede fallar sin tumbar el resto.',
              ),
            ),
          if (state.message != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(state.message!),
            ),
        ],
      ),
    );
  }

  Widget _resultCell(StreamOpenResult item) {
    String? title;
    for (final channel in widget.channels) {
      if (channel.requestChannel == item.channel) {
        title = channel.name;
        break;
      }
    }
    if (!item.success || item.ticket == null) {
      return _Cell(
        title: title ?? item.key,
        child: Center(
          child: Text(item.userMessage ?? 'Falló', textAlign: TextAlign.center),
        ),
      );
    }
    final ticket = item.ticket!;
    return _Cell(
      title: title ?? 'Canal ${item.channel}',
      child: MaicVlcView(
        key: ValueKey(ticket.leaseId),
        streamUrl: ticket.streamUrl,
        startOffset: Duration(milliseconds: 700 * item.channel),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ColoredBox(
        color: const Color(0xFF1A2026),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
