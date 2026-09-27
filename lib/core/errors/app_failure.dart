enum FailureKind {
  validation,
  unauthorized,
  forbidden,
  notFound,
  timeout,
  transport,
  certificate,
  invalidResponse,
  functional,
  unknown,
}

class AppFailure implements Exception {
  const AppFailure({
    required this.kind,
    required this.userMessage,
    this.code,
    this.isRetryable = false,
  });

  final FailureKind kind;
  final String userMessage;
  final String? code;
  final bool isRetryable;

  @override
  String toString() => 'AppFailure($kind, $code)';
}
