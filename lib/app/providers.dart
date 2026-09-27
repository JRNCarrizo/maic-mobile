import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/session/session_store.dart';
import '../data/actions/unit_action_repository.dart';
import '../data/api/dio_maic_client.dart';
import '../data/auth/auth_repository.dart';
import '../data/health/health_repository.dart';
import '../data/storage/local_settings.dart';
import '../data/units/unit_catalog_repository.dart';
import '../domain/ports/auth_port.dart';
import '../domain/ports/health_port.dart';
import '../data/layouts/layout_repository.dart';
import '../data/realtime/mock_realtime.dart';
import '../data/realtime/signalr_realtime.dart';
import '../domain/ports/layout_port.dart';
import '../domain/ports/realtime_port.dart';
import '../data/events/event_repository.dart';
import '../domain/ports/event_port.dart';
import '../data/actuators/actuator_repository.dart';
import '../data/snapshot/snapshot_repository.dart';
import '../data/video/video_ticket_repository.dart';
import '../domain/ports/unit_action_port.dart';
import '../domain/ports/unit_catalog_port.dart';
import '../domain/video/video_ticket.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences se inyecta en bootstrap.');
});

final localSettingsProvider = Provider<LocalSettings>((ref) {
  return LocalSettings(ref.watch(sharedPreferencesProvider));
});

final sessionStoreProvider = ChangeNotifierProvider<SessionStore>((ref) {
  return SessionStore();
});

final apiClientProvider = Provider<DioMaicClient>((ref) {
  return DioMaicClient(ref.watch(sessionStoreProvider));
});

final healthPortProvider = Provider<HealthPort>((ref) {
  return HealthRepository(ref.watch(apiClientProvider));
});

final authPortProvider = Provider<AuthPort>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(localSettingsProvider),
  );
});

final unitActionPortProvider = Provider<UnitActionPort>((ref) {
  return UnitActionRepository(
    ref.watch(apiClientProvider),
    ref.watch(localSettingsProvider),
  );
});

final unitCatalogPortProvider = Provider<UnitCatalogPort>((ref) {
  return UnitCatalogRepository(
    ref.watch(apiClientProvider),
    ref.watch(localSettingsProvider),
    ref.watch(unitActionPortProvider),
  );
});

final videoTicketPortProvider = Provider<VideoTicketPort>((ref) {
  return VideoTicketRepository(ref.watch(unitActionPortProvider));
});

final snapshotRepositoryProvider = Provider<SnapshotRepository>((ref) {
  return SnapshotRepository(ref.watch(unitActionPortProvider));
});

final actuatorRepositoryProvider = Provider<ActuatorRepository>((ref) {
  return ActuatorRepository(ref.watch(unitActionPortProvider));
});

final eventPortProvider = Provider<EventPort>((ref) {
  return EventRepository(
    ref.watch(apiClientProvider),
    ref.watch(localSettingsProvider),
  );
});

final mockRealtimeProvider = Provider<MockRealtime>((ref) => MockRealtime());

final realtimePortProvider = Provider<RealtimePort>((ref) {
  if (ref.watch(localSettingsProvider).readDataSource() == DataSourceKind.mock) {
    return ref.watch(mockRealtimeProvider);
  }
  return SignalRRealtime();
});

final layoutPortProvider = Provider<LayoutPort>((ref) {
  return LayoutRepository(
    ref.watch(apiClientProvider),
    ref.watch(localSettingsProvider),
  );
});
