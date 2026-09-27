import 'package:flutter_test/flutter_test.dart';
import 'package:maic_mobile/core/endpoint/server_endpoint.dart';
import 'package:maic_mobile/core/errors/app_failure.dart';

void main() {
  test('host solo usa https y puerto 5443', () {
    final endpoint = ServerEndpoint.parse('maic-server');
    expect(endpoint.display, 'https://maic-server:5443/');
  });

  test('IP sola agrega esquema y puerto', () {
    final endpoint = ServerEndpoint.parse('192.168.0.10');
    expect(endpoint.host, '192.168.0.10');
    expect(endpoint.port, 5443);
  });

  test('respeta puerto explícito y tira el path', () {
    final endpoint = ServerEndpoint.parse(
      'https://maic.empresa.local:7443/api/foo',
    );
    expect(endpoint.display, 'https://maic.empresa.local:7443/');
  });

  test('rechaza credenciales embebidas', () {
    expect(
      () => ServerEndpoint.parse('https://user:pass@maic-server'),
      throwsA(isA<AppFailure>()),
    );
  });

  test('http explícito se respeta', () {
    final endpoint = ServerEndpoint.parse('http://192.168.0.10:8080');
    expect(endpoint.scheme, 'http');
    expect(endpoint.display, 'http://192.168.0.10:8080/');
  });

  test('sin esquema sigue siendo https', () {
    final endpoint = ServerEndpoint.parse('192.168.0.10');
    expect(endpoint.scheme, 'https');
  });
}
