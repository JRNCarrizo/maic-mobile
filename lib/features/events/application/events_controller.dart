import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/errors/app_failure.dart';
import '../../../domain/events/maic_event.dart';
import '../../connection/application/connection_controller.dart';

class EventsViewState {
  const EventsViewState({
    this.alarms = const [],
    this.events = const [],
    this.section = 0,
    this.loading = false,
    this.acting = false,
    this.message,
  });

  final List<MaicAlarm> alarms;
  final List<MaicEvent> events;
  final int section;
  final bool loading;
  final bool acting;
  final String? message;

  EventsViewState copyWith({
    List<MaicAlarm>? alarms,
    List<MaicEvent>? events,
    int? section,
    bool? loading,
    bool? acting,
    String? message,
    bool clearMessage = false,
  }) {
    return EventsViewState(
      alarms: alarms ?? this.alarms,
      events: events ?? this.events,
      section: section ?? this.section,
      loading: loading ?? this.loading,
      acting: acting ?? this.acting,
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

class EventsController extends Notifier<EventsViewState> {
  @override
  EventsViewState build() => const EventsViewState();

  void showSection(int section) {
    state = state.copyWith(section: section);
  }

  Future<void> load() async {
    final endpoint = ref.read(connectionControllerProvider).endpoint ??
        ref.read(localSettingsProvider).read();
    if (endpoint == null) {
      state = state.copyWith(message: 'No hay servidor configurado.');
      return;
    }
    state = state.copyWith(loading: true, clearMessage: true);
    try {
      final events = await ref.read(eventPortProvider).listEvents(endpoint);
      final alarms = await ref.read(eventPortProvider).listAlarms(endpoint);
      state = state.copyWith(
        events: events,
        alarms: alarms,
        loading: false,
      );
    } on AppFailure catch (failure) {
      if (failure.kind == FailureKind.unauthorized) {
        ref.read(sessionStoreProvider).clear();
      }
      state = state.copyWith(loading: false, message: failure.userMessage);
    } catch (_) {
      state = state.copyWith(
        loading: false,
        message: 'No se pudieron cargar alarmas o eventos.',
      );
    }
  }

  Future<void> ack(String alarmId) async {
    final endpoint = ref.read(localSettingsProvider).read();
    if (endpoint == null) return;
    state = state.copyWith(acting: true, clearMessage: true);
    try {
      await ref.read(eventPortProvider).ackAlarm(endpoint, alarmId);
      final now = DateTime.now().toUtc();
      state = state.copyWith(
        acting: false,
        alarms: [
          for (final alarm in state.alarms)
            if (alarm.id == alarmId)
              alarm.acknowledged(at: now)
            else
              alarm,
        ],
        message: 'Alarma reconocida.',
      );
    } on AppFailure catch (failure) {
      if (failure.kind == FailureKind.unauthorized) {
        ref.read(sessionStoreProvider).clear();
      }
      state = state.copyWith(acting: false, message: failure.userMessage);
    } catch (_) {
      state = state.copyWith(
        acting: false,
        message: 'No se pudo reconocer la alarma.',
      );
    }
  }
}

final eventsControllerProvider =
    NotifierProvider<EventsController, EventsViewState>(EventsController.new);
