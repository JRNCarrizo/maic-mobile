import 'package:dio/dio.dart';

import '../../core/constants/maic_constants.dart';
import '../../core/endpoint/server_endpoint.dart';
import '../../core/errors/app_failure.dart';
import '../../core/logging/app_logger.dart';
import '../../core/network/api_response.dart';
import '../../core/session/session_store.dart';

class DioMaicClient {
  DioMaicClient(this._session);

  final SessionStore _session;
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: MaicDefaults.httpTimeout,
      receiveTimeout: MaicDefaults.httpTimeout,
      sendTimeout: MaicDefaults.httpTimeout,
      headers: const {'Content-Type': 'application/json'},
    ),
  );

  Future<ApiResponse<T>> get<T>(
    ServerEndpoint endpoint,
    String path, {
    T Function(Object? raw)? parseData,
    bool withSession = true,
    Map<String, String>? query,
  }) {
    final uri = (query == null || query.isEmpty)
        ? endpoint.baseUri.replace(path: path)
        : endpoint.baseUri.replace(path: path, queryParameters: query);
    return _send<T>(
      () => _dio.get<Map<String, dynamic>>(
        uri.toString(),
        options: _options(withSession: withSession),
      ),
      parseData,
    );
  }

  Future<ApiResponse<T>> post<T>(
    ServerEndpoint endpoint,
    String path, {
    Map<String, dynamic>? body,
    T Function(Object? raw)? parseData,
    bool withSession = true,
  }) {
    return _send<T>(
      () => _dio.post<Map<String, dynamic>>(
        endpoint.baseUri.replace(path: path).toString(),
        data: body,
        options: _options(withSession: withSession),
      ),
      parseData,
    );
  }

  Options _options({required bool withSession}) {
    final headers = <String, String>{};
    final sessionId = _session.session?.sessionId;
    if (withSession && sessionId != null && sessionId.isNotEmpty) {
      headers[MaicHeaders.session] = sessionId;
    }
    return Options(headers: headers);
  }

  Future<void> ping(ServerEndpoint endpoint, String path) async {
    try {
      await _dio.get<dynamic>(
        endpoint.baseUri.replace(path: path).toString(),
        options: _options(withSession: false),
      );
    } on AppFailure {
      rethrow;
    } on DioException catch (error) {
      throw _mapDio(error);
    }
  }

  Future<ApiResponse<T>> _send<T>(
    Future<Response<Map<String, dynamic>>> Function() call,
    T Function(Object? raw)? parseData,
  ) async {
    try {
      final response = await call();
      final payload = response.data;
      if (payload == null) {
        throw const AppFailure(
          kind: FailureKind.invalidResponse,
          userMessage: 'El servidor no devolvió datos.',
        );
      }
      return ApiResponse.fromJson(payload, parseData);
    } on AppFailure {
      rethrow;
    } on DioException catch (error) {
      throw _mapDio(error);
    } catch (error) {
      AppLogger.error('Respuesta inválida: ${error.runtimeType}');
      throw const AppFailure(
        kind: FailureKind.invalidResponse,
        userMessage: 'La respuesta del servidor no se pudo leer.',
      );
    }
  }

  AppFailure _mapDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AppFailure(
          kind: FailureKind.timeout,
          userMessage: 'Se agotó el tiempo de espera del servidor.',
          isRetryable: true,
        );
      case DioExceptionType.badCertificate:
        return const AppFailure(
          kind: FailureKind.certificate,
          userMessage:
              'El certificado del servidor no es de confianza. No se desactiva TLS.',
        );
      case DioExceptionType.connectionError:
        return const AppFailure(
          kind: FailureKind.transport,
          userMessage: 'No se pudo conectar al servidor MAIC.',
          isRetryable: true,
        );
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == 401) {
          return const AppFailure(
            kind: FailureKind.unauthorized,
            userMessage: 'La sesión no es válida. Volvé a ingresar.',
            code: 'Unauthorized',
          );
        }
        if (code == 403) {
          return const AppFailure(
            kind: FailureKind.forbidden,
            userMessage: 'No tenés permiso para esta operación.',
            code: 'Forbidden',
          );
        }
        return AppFailure(
          kind: FailureKind.transport,
          userMessage: 'El servidor respondió HTTP $code.',
          isRetryable: true,
        );
      case DioExceptionType.cancel:
        return const AppFailure(
          kind: FailureKind.unknown,
          userMessage: 'La solicitud se canceló.',
        );
      case DioExceptionType.unknown:
      default:
        return const AppFailure(
          kind: FailureKind.transport,
          userMessage: 'Error de red al hablar con MAIC Server.',
          isRetryable: true,
        );
    }
  }
}
