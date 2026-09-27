import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/units/unit.dart';
import '../../../ui/theme/maic_colors.dart';
import '../../../ui/widgets/maic_chrome.dart';
import '../application/units_controller.dart';

class UnitsScreen extends ConsumerStatefulWidget {
  const UnitsScreen({super.key});

  @override
  ConsumerState<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends ConsumerState<UnitsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(unitsControllerProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(unitsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: MaicColors.bgTop,
        title: const Text('CÁMARAS'),
      ),
      body: MaicBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: MaicPanel(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: TextField(
                    onChanged: ref.read(unitsControllerProvider.notifier).search,
                    decoration: const InputDecoration(
                      hintText: 'Buscar unidad',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                      filled: false,
                    ),
                  ),
                ),
              ),
              if (state.lastUnit != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: MaicPanel(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      leading: const MaicIconBadge(icon: Icons.history),
                      title: const Text('Última vista'),
                      subtitle: Text(state.lastUnit!.displayName),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/units/${state.lastUnit!.id}'),
                    ),
                  ),
                ),
              if (state.message != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(state.message!),
                ),
              Expanded(
                child: RefreshIndicator(
                  color: MaicColors.accent,
                  onRefresh: ref.read(unitsControllerProvider.notifier).load,
                  child: _body(state),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(UnitsViewState state) {
    if (state.loading && state.units.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }
    final items = state.visible;
    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: Text('No hay unidades para este usuario.')),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final unit = items[index];
        return _UnitTile(
          unit: unit,
          onTap: () {
            ref.read(unitsControllerProvider.notifier).remember(unit);
            context.push('/units/${unit.id}');
          },
        );
      },
    );
  }
}

class _UnitTile extends StatelessWidget {
  const _UnitTile({required this.unit, required this.onTap});

  final MaicUnit unit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MaicPanel(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: MaicIconBadge(icon: _icon, color: _color),
        title: Text(unit.displayName),
        subtitle: Text(
          '${unit.kindLabel} · ${_statusLabel(unit.online)}',
          style: const TextStyle(color: MaicColors.muted),
        ),
        trailing: const Icon(Icons.chevron_right, color: MaicColors.muted),
        onTap: onTap,
      ),
    );
  }

  IconData get _icon {
    return unit.isRecorder ? Icons.dns_outlined : Icons.videocam_outlined;
  }

  Color get _color {
    return switch (unit.online) {
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
