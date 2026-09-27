import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/constants/maic_constants.dart';
import '../../../core/endpoint/server_endpoint.dart';
import '../../../data/storage/local_settings.dart';
import '../../../ui/theme/maic_colors.dart';
import '../../../ui/widgets/maic_chrome.dart';
import '../../connection/application/connection_controller.dart';
import '../application/session_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _host = TextEditingController();
  final _port = TextEditingController(text: '${MaicDefaults.apiPort}');
  final _user = TextEditingController(text: 'demo');
  final _password = TextEditingController(text: 'demo');
  var _useDemo = true;
  var _serverOpen = false;
  var _hidePassword = true;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(localSettingsProvider);
    final current = settings.read();
    if (settings.readDataSource() == DataSourceKind.remote &&
        current != null &&
        current.host != 'demo.maic.local') {
      _useDemo = false;
      _host.text = current.isSecure ? current.host : 'http://${current.host}';
      _port.text = '${current.port}';
      _user.clear();
      _password.clear();
    }
  }

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    _user.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connection = ref.watch(connectionControllerProvider);
    final session = ref.watch(sessionControllerProvider);
    final saved = ref.watch(localSettingsProvider).readSavedHosts();
    final busy = connection.busy || session.busy;
    final summary = _useDemo
        ? 'demo@demo'
        : (connection.endpoint != null &&
                connection.endpoint!.host != 'demo.maic.local'
            ? '${connection.endpoint!.host}:${connection.endpoint!.port}'
            : (_host.text.trim().isEmpty
                ? 'Sin servidor'
                : '${_host.text.trim()}:${_port.text.trim()}'));

    return Scaffold(
      body: MaicBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final minHeight = constraints.maxHeight.isFinite
                  ? (constraints.maxHeight - 16).clamp(0.0, double.infinity)
                  : 0.0;
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Header(),
                          const SizedBox(height: 36),
                          MaicPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  splashFactory: NoSplash.splashFactory,
                                  overlayColor: const WidgetStatePropertyAll(
                                    Colors.transparent,
                                  ),
                                  onTap: () =>
                                      setState(() => _serverOpen = !_serverOpen),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        const MaicIconBadge(icon: Icons.dns_outlined),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Servidor',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                summary,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: const Color(0xFF8FA3AD),
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          _serverOpen
                                              ? Icons.expand_less
                                              : Icons.expand_more,
                                          color: const Color(0xFF8FA3AD),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_serverOpen) ...[
                                  const SizedBox(height: 16),
                                  SegmentedButton<bool>(
                                    showSelectedIcon: false,
                                    segments: const [
                                      ButtonSegment(
                                        value: true,
                                        label: Text('Demo'),
                                      ),
                                      ButtonSegment(
                                        value: false,
                                        label: Text('Servidor'),
                                      ),
                                    ],
                                    selected: {_useDemo},
                                    onSelectionChanged: (value) {
                                      if (busy) return;
                                      _selectDemo(value.first);
                                    },
                                  ),
                                  if (_useDemo) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      'Sin servidor. Queda como demo@demo.',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ] else ...[
                                    if (saved.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      DropdownButtonFormField<String>(
                                        key: ValueKey(saved.length),
                                        initialValue: _savedValue(
                                          saved,
                                          connection.endpoint,
                                        ),
                                        decoration: const InputDecoration(
                                          labelText: 'IP guardada',
                                        ),
                                        items: [
                                          for (final host in saved)
                                            DropdownMenuItem(
                                              value: host.connectionKey,
                                              child: Text(
                                                host.isSecure
                                                    ? '${host.host}:${host.port}'
                                                    : host.connectionKey,
                                              ),
                                            ),
                                        ],
                                        onChanged: busy ? null : _applySaved,
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: TextField(
                                            controller: _host,
                                            enabled: !busy,
                                            keyboardType: TextInputType.url,
                                            decoration: const InputDecoration(
                                              labelText: 'Host o IP',
                                              hintText: '192.168.0.10',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: TextField(
                                            controller: _port,
                                            enabled: !busy,
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              labelText: 'Puerto',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Si no ponés esquema, se usa HTTPS y puerto 5443. '
                                      'Si el server es HTTP, escribí http:// delante de la IP.',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  FilledButton.tonal(
                                    onPressed: busy ? null : _testAndSave,
                                    child: connection.busy
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text('Probar y guardar'),
                                  ),
                                  if (connection.ready &&
                                      connection.endpoint != null) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      _useDemo
                                          ? 'Listo: demo@demo'
                                          : 'Servidor: ${connection.endpoint!.display}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                  if (connection.message != null) ...[
                                    const SizedBox(height: 8),
                                    Text(connection.message!),
                                  ],
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          MaicPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Row(
                                  children: [
                                    MaicIconBadge(icon: Icons.lock_outline),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text('Iniciar sesión'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                TextField(
                                  controller: _user,
                                  enabled: !busy,
                                  textInputAction: TextInputAction.next,
                                  autocorrect: false,
                                  textAlign: TextAlign.left,
                                  decoration: const InputDecoration(
                                    labelText: 'Usuario',
                                    hintText: 'Tu nombre de usuario',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _password,
                                  enabled: !busy,
                                  obscureText: _hidePassword,
                                  onSubmitted: (_) => _enter(),
                                  decoration: InputDecoration(
                                    labelText: 'Contraseña',
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(
                                        () => _hidePassword = !_hidePassword,
                                      ),
                                      icon: Icon(
                                        _hidePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 22),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48),
                                  ),
                                  onPressed: busy ? null : _enter,
                                  child: session.busy
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Ingresar'),
                                ),
                                if (session.message != null) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    session.message!,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String? _savedValue(List<ServerEndpoint> saved, ServerEndpoint? current) {
    if (current == null) return null;
    final key = current.connectionKey;
    for (final host in saved) {
      if (host.connectionKey == key) return key;
    }
    return null;
  }

  void _selectDemo(bool demo) {
    setState(() {
      _useDemo = demo;
      if (demo) {
        _user.text = 'demo';
        _password.text = 'demo';
      } else {
        _user.clear();
        _password.clear();
        if (_port.text.trim().isEmpty) {
          _port.text = '${MaicDefaults.apiPort}';
        }
      }
    });
  }

  void _applySaved(String? value) {
    if (value == null) return;
    final split = value.lastIndexOf(':');
    if (split <= 0) return;
    setState(() {
      _useDemo = false;
      _host.text = value.substring(0, split);
      _port.text = value.substring(split + 1);
    });
  }

  String _rawHost() {
    final host = _host.text.trim();
    final port = _port.text.trim();
    if (port.isEmpty || port == '${MaicDefaults.apiPort}') return host;
    return '$host:$port';
  }

  Future<void> _testAndSave() async {
    final connection = ref.read(connectionControllerProvider.notifier);
    if (_useDemo) {
      await connection.useMock();
      if (mounted) setState(() => _serverOpen = false);
      return;
    }
    final ok = await connection.probe(_rawHost());
    if (ok && mounted) setState(() => _serverOpen = false);
  }

  Future<void> _enter() async {
    final connection = ref.read(connectionControllerProvider.notifier);
    final state = ref.read(connectionControllerProvider);
    if (_useDemo) {
      if (!state.ready || state.kind != DataSourceKind.mock) {
        await connection.useMock();
      }
      final user = _user.text.trim().isEmpty ? 'demo' : _user.text;
      final password = _password.text.isEmpty ? 'demo' : _password.text;
      await ref.read(sessionControllerProvider.notifier).login(user, password);
      return;
    }

    final needsProbe = !state.ready ||
        state.kind != DataSourceKind.remote ||
        state.endpoint == null;
    if (needsProbe) {
      final ok = await connection.probe(_rawHost());
      if (!ok) return;
    }
    await ref
        .read(sessionControllerProvider.notifier)
        .login(_user.text, _password.text);
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: MaicColors.accentSoft,
            border: Border.all(color: MaicColors.accent, width: 1.2),
          ),
          child: const Icon(
            Icons.videocam_outlined,
            size: 34,
            color: MaicColors.accent,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'MAIC',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            letterSpacing: 6,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Operación de video',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: MaicColors.muted,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}
