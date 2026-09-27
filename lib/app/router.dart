import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/session/session_store.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/connection/presentation/connection_screen.dart';
import '../features/shell/presentation/app_shell.dart';
import '../domain/units/video_channel.dart';
import '../features/live/presentation/grid_screen.dart';
import '../features/live/presentation/live_screen.dart';
import '../features/units/presentation/unit_detail_screen.dart';
import 'providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sessionStoreProvider);
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: session,
    redirect: (context, state) {
      return _redirect(session, state.matchedLocation);
    },
    routes: [
      GoRoute(
        path: '/connection',
        builder: (context, state) => const ConnectionScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const AppShell(),
      ),
      GoRoute(
        path: '/units/:id',
        builder: (context, state) => UnitDetailScreen(
          unitId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/grid/:unitId',
        builder: (context, state) {
          final extra = state.extra;
          final channels = extra is List<VideoChannel>
              ? extra
              : const <VideoChannel>[];
          return GridScreen(
            unitId: state.pathParameters['unitId'] ?? '',
            title: state.uri.queryParameters['name'] ?? 'Grilla',
            channels: channels,
          );
        },
      ),
      GoRoute(
        path: '/live/:unitId',
        builder: (context, state) {
          final channel = int.tryParse(
            state.uri.queryParameters['channel'] ?? '',
          );
          return LiveScreen(
            unitId: state.pathParameters['unitId'] ?? '',
            channel: channel ?? 1,
            title: state.uri.queryParameters['name'] ?? 'Live',
          );
        },
      ),
    ],
  );
});

String? _redirect(SessionStore session, String location) {
  final authed = session.isAuthenticated;

  if (!authed) {
    return location == '/login' ? null : '/login';
  }
  if (location == '/login' || location == '/connection') return '/home';
  return null;
}
