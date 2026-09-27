import '../constants/maic_constants.dart';
import '../errors/app_failure.dart';

/// Normaliza la URL base del MAIC Server (contrato §3.1).
/// HTTPS por defecto. HTTP solo si lo escriben explícito (`http://...`).
class ServerEndpoint {
  const ServerEndpoint({
    required this.host,
    required this.port,
    this.scheme = 'https',
  });

  final String host;
  final int port;
  final String scheme;

  bool get isSecure => scheme == 'https';

  Uri get baseUri => Uri(scheme: scheme, host: host, port: port);

  String get display => baseUri.toString().endsWith('/')
      ? baseUri.toString()
      : '${baseUri.toString()}/';

  String get connectionKey => '$scheme://$host:$port';

  bool get isLoopback =>
      host == 'localhost' || host == '127.0.0.1' || host == '::1';

  static ServerEndpoint parse(String raw) {
    final input = raw.trim();
    if (input.isEmpty) {
      throw const AppFailure(
        kind: FailureKind.validation,
        userMessage: 'Ingresá la dirección del servidor MAIC.',
      );
    }
    if (input.contains('@')) {
      throw const AppFailure(
        kind: FailureKind.validation,
        userMessage:
            'La URL no puede incluir usuario ni contraseña. Ingresá solo el host.',
      );
    }

    final withScheme = input.contains('://') ? input : 'https://$input';
    final parsed = Uri.tryParse(withScheme);
    if (parsed == null || parsed.host.isEmpty) {
      throw const AppFailure(
        kind: FailureKind.validation,
        userMessage: 'La dirección del servidor no es válida.',
      );
    }
    final scheme = parsed.scheme.toLowerCase();
    if (scheme != 'https' && scheme != 'http') {
      throw const AppFailure(
        kind: FailureKind.validation,
        userMessage: 'Usá http:// o https://. Si no ponés nada, se usa HTTPS.',
      );
    }

    return ServerEndpoint(
      host: parsed.host,
      port: parsed.hasPort ? parsed.port : MaicDefaults.apiPort,
      scheme: scheme,
    );
  }

  Map<String, dynamic> toJson() => {
    'host': host,
    'port': port,
    'scheme': scheme,
  };

  factory ServerEndpoint.fromJson(Map<String, dynamic> json) {
    final rawScheme = json['scheme']?.toString().toLowerCase();
    return ServerEndpoint(
      host: json['host'] as String,
      port: json['port'] as int,
      scheme: rawScheme == 'http' ? 'http' : 'https',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ServerEndpoint &&
      other.host == host &&
      other.port == port &&
      other.scheme == scheme;

  @override
  int get hashCode => Object.hash(host, port, scheme);
}
