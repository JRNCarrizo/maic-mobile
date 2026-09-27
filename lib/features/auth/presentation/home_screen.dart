import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../data/storage/local_settings.dart';
import '../../../ui/theme/maic_colors.dart';
import '../../../ui/widgets/maic_chrome.dart';
import '../../connection/application/connection_controller.dart';
import '../application/session_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionStoreProvider).session;
    final pulse = ref.watch(sessionControllerProvider);
    final connection = ref.watch(connectionControllerProvider);
    final isDemo = connection.kind == DataSourceKind.mock;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: MaicColors.bgTop,
        title: const Text('SESIÓN'),
      ),
      body: MaicBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              MaicPanel(
                child: Row(
                  children: [
                    const MaicIconBadge(icon: Icons.person_outline),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session?.displayName.isNotEmpty == true
                                ? session!.displayName
                                : (session?.loginName ?? 'Sin usuario'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            session?.roleLabel ?? 'Sin rol',
                            style: const TextStyle(color: MaicColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const MaicSectionTitle('CONEXIÓN'),
              const SizedBox(height: 10),
              MaicPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _InfoRow(
                      icon: Icons.dns_outlined,
                      label: 'Servidor',
                      value: connection.endpoint?.display ?? '—',
                    ),
                    const SizedBox(height: 14),
                    _InfoRow(
                      icon: Icons.hub_outlined,
                      label: 'Origen',
                      value: isDemo ? 'Modo demo' : 'MAIC Server',
                    ),
                    const SizedBox(height: 14),
                    _InfoRow(
                      icon: Icons.favorite_outline,
                      label: 'Heartbeat',
                      value: pulse.heartbeatOk
                          ? 'Activo'
                          : 'Sin red (la sesión se mantiene)',
                      color: pulse.heartbeatOk
                          ? MaicColors.accent
                          : MaicColors.offline,
                    ),
                    if (pulse.lastHeartbeatUtc != null) ...[
                      const SizedBox(height: 14),
                      _InfoRow(
                        icon: Icons.schedule_outlined,
                        label: 'Último pulso',
                        value: pulse.lastHeartbeatUtc.toString(),
                      ),
                    ],
                  ],
                ),
              ),
              if (pulse.message != null) ...[
                const SizedBox(height: 12),
                Text(
                  pulse.message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: MaicColors.muted),
                ),
              ],
              if (isDemo) ...[
                const SizedBox(height: 24),
                const MaicSectionTitle('PRUEBA'),
                const SizedBox(height: 10),
                MaicPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'SessionClosed es cuando el servidor echa esta sesión '
                        '(otro ingreso, cierre remoto o licencia). Acá se simula.',
                        style: TextStyle(color: MaicColors.muted),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                        ),
                        onPressed: () => ref
                            .read(sessionControllerProvider.notifier)
                            .handleSessionClosed(),
                        child: const Text('Simular SessionClosed'),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const MaicSectionTitle('CUENTA'),
              const SizedBox(height: 10),
              MaicPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                      ),
                      onPressed: () async {
                        await ref
                            .read(sessionControllerProvider.notifier)
                            .logout();
                        if (context.mounted) context.go('/login');
                      },
                      child: const Text('Cambiar servidor'),
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                      ),
                      onPressed: () =>
                          ref.read(sessionControllerProvider.notifier).logout(),
                      child: const Text('Cerrar sesión'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MaicIconBadge(icon: icon, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: MaicColors.muted,
                  fontSize: 12,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(value),
            ],
          ),
        ),
      ],
    );
  }
}
