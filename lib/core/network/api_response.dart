class ApiError {
  const ApiError({required this.code, required this.message, this.details});

  final String code;
  final String message;
  final Map<String, dynamic>? details;

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: json['code'] as String? ?? 'Unknown',
      message: json['message'] as String? ?? 'Error del servidor.',
      details: json['details'] is Map<String, dynamic>
          ? json['details'] as Map<String, dynamic>
          : null,
    );
  }
}

class ApiResponse<T> {
  const ApiResponse({required this.result, this.data, this.error});

  final bool result;
  final T? data;
  final ApiError? error;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? raw)? parseData,
  ) {
    final rawData = json['data'];
    return ApiResponse<T>(
      result: json['result'] == true,
      data: rawData == null || parseData == null ? null : parseData(rawData),
      error: json['error'] is Map<String, dynamic>
          ? ApiError.fromJson(json['error'] as Map<String, dynamic>)
          : null,
    );
  }
}
