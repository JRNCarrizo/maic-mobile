import 'package:flutter/material.dart';

import '../../auth/presentation/home_screen.dart';
import '../../events/presentation/events_screen.dart';
import '../../units/presentation/units_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.videocam_outlined),
            selectedIcon: Icon(Icons.videocam),
            label: 'Cámaras',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alarmas',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Sesión',
          ),
        ],
      ),
    );
  }
}
