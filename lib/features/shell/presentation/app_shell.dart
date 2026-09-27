import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/theme/maic_colors.dart';
import '../../auth/presentation/home_screen.dart';
import '../../events/application/events_controller.dart';
import '../../events/presentation/events_screen.dart';
import '../../units/presentation/units_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final activeAlarms = ref.watch(
      eventsControllerProvider.select((state) => state.activeAlarmCount),
    );

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [UnitsScreen(), EventsScreen(), HomeScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF0D1518),
        animationDuration: const Duration(milliseconds: 100),
        selectedIndex: _index,
        onDestinationSelected: (value) {
          if (value == _index) return;
          setState(() => _index = value);
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.videocam_outlined),
            selectedIcon: Icon(Icons.videocam),
            label: 'Cámaras',
          ),
          NavigationDestination(
            icon: _AlarmIcon(count: activeAlarms, selected: false),
            selectedIcon: _AlarmIcon(count: activeAlarms, selected: true),
            label: 'Alarmas',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Sesión',
          ),
        ],
      ),
    );
  }
}

class _AlarmIcon extends StatelessWidget {
  const _AlarmIcon({required this.count, required this.selected});

  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      selected ? Icons.notifications : Icons.notifications_outlined,
    );
    if (count <= 0) return icon;
    return Badge(
      backgroundColor: MaicColors.offline,
      textColor: Colors.white,
      label: Text(count > 99 ? '99+' : '$count'),
      child: icon,
    );
  }
}
