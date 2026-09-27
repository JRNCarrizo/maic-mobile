import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/events/maic_event.dart';
import '../../../ui/theme/maic_colors.dart';
import '../../../ui/widgets/maic_chrome.dart';
import '../application/events_controller.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(eventsControllerProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(eventsControllerProvider);
    final notifier = ref.read(eventsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: MaicColors.bgTop,
        title: const Text('ALARMAS'),
      ),
      body: MaicBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: MaicPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SegmentedButton<int>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: 0, label: Text('Alarmas')),
                          ButtonSegment(value: 1, label: Text('Eventos')),
                        ],
                        selected: {state.section},
                        onSelectionChanged: (value) =>
                            notifier.showSection(value.first),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        state.section == 0
                            ? 'Avisos que piden reconocimiento.'
                            : 'Registro de avisos. No es reproducción de grabación.',
                        style: const TextStyle(
                          color: MaicColors.muted,
                          fontSize: 13,
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
                child: RefreshIndicator(
                  color: MaicColors.accent,
                  onRefresh: notifier.load,
                  child: state.loading &&
                          state.alarms.isEmpty &&
                          state.events.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            Center(child: CircularProgressIndicator()),
                          ],
                        )
                      : ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                          children: state.section == 0
                              ? _alarms(state, notifier)
                              : _events(state.events),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _alarms(EventsViewState state, EventsController notifier) {
    if (state.alarms.isEmpty) {
      return const [
        MaicPanel(
          child: Text(
            'No hay alarmas.',
            style: TextStyle(color: MaicColors.muted),
          ),
        ),
      ];
    }
    return [
      for (final alarm in state.alarms) ...[
        _AlarmTile(
          alarm: alarm,
          acting: state.acting,
          onAck: () => notifier.ack(alarm.id),
        ),
        const SizedBox(height: 10),
      ],
    ];
  }

  List<Widget> _events(List<MaicEvent> events) {
    if (events.isEmpty) {
      return const [
        MaicPanel(
          child: Text(
            'No hay eventos.',
            style: TextStyle(color: MaicColors.muted),
          ),
        ),
      ];
    }
    return [
      for (final event in events) ...[
        _EventTile(event: event),
        const SizedBox(height: 10),
      ],
    ];
  }
}

class _AlarmTile extends StatelessWidget {
  const _AlarmTile({
    required this.alarm,
    required this.acting,
    required this.onAck,
  });

  final MaicAlarm alarm;
  final bool acting;
  final VoidCallback onAck;

  @override
  Widget build(BuildContext context) {
    final active = alarm.isActive;
    return MaicPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              MaicIconBadge(
                icon: active
                    ? Icons.notification_important_outlined
                    : Icons.check,
                color: active ? MaicColors.offline : MaicColors.accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alarm.message,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (alarm.alarmType.isNotEmpty) alarm.alarmType,
                        if (alarm.severity.isNotEmpty) alarm.severity,
                        active ? 'Activa' : 'Reconocida',
                      ].join(' · '),
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
          if (active) ...[
            const SizedBox(height: 14),
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(42),
              ),
              onPressed: acting ? null : onAck,
              child: const Text('Reconocer'),
            ),
          ],
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final MaicEvent event;

  @override
  Widget build(BuildContext context) {
    return MaicPanel(
      child: Row(
        children: [
          const MaicIconBadge(icon: Icons.event_note_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.message,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (event.type.isNotEmpty) event.type,
                    if (event.severity.isNotEmpty) event.severity,
                    if (event.timestampUtc != null)
                      event.timestampUtc.toString(),
                  ].join(' · '),
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
    );
  }
}
