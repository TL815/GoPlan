/// Stable categories for assistant transport and protocol failures.
enum TravelAssistantFailureType {
  configuration,
  network,
  timeout,
  unauthorized,
  rateLimited,
  invalidRequest,
  invalidResponse,
  serviceUnavailable,
  cancelled,
  unknown,
}

/// Structured failure data produced by assistant gateway implementations.
///
/// This model deliberately avoids depending on concrete transport exception
/// types. The optional [cause] is for local debugging only and should not be
/// serialized or shown to users.
class TravelAssistantFailure {
  const TravelAssistantFailure({
    required this.type,
    required this.message,
    this.code,
    this.statusCode,
    this.retryable = false,
    this.cause,
  });

  factory TravelAssistantFailure.network({
    String message = 'Network error',
    String? code,
    int? statusCode,
    bool retryable = true,
    Object? cause,
  }) {
    return TravelAssistantFailure(
      type: TravelAssistantFailureType.network,
      message: message,
      code: code,
      statusCode: statusCode,
      retryable: retryable,
      cause: cause,
    );
  }

  factory TravelAssistantFailure.timeout({
    String message = 'Request timed out',
    String? code,
    int? statusCode,
    bool retryable = true,
    Object? cause,
  }) {
    return TravelAssistantFailure(
      type: TravelAssistantFailureType.timeout,
      message: message,
      code: code,
      statusCode: statusCode,
      retryable: retryable,
      cause: cause,
    );
  }

  factory TravelAssistantFailure.invalidResponse({
    String message = 'Invalid assistant response',
    String? code,
    int? statusCode,
    bool retryable = false,
    Object? cause,
  }) {
    return TravelAssistantFailure(
      type: TravelAssistantFailureType.invalidResponse,
      message: message,
      code: code,
      statusCode: statusCode,
      retryable: retryable,
      cause: cause,
    );
  }

  factory TravelAssistantFailure.configuration({
    String message = 'Assistant configuration error',
    String? code,
    int? statusCode,
    bool retryable = false,
    Object? cause,
  }) {
    return TravelAssistantFailure(
      type: TravelAssistantFailureType.configuration,
      message: message,
      code: code,
      statusCode: statusCode,
      retryable: retryable,
      cause: cause,
    );
  }

  final TravelAssistantFailureType type;
  final String message;
  final String? code;
  final int? statusCode;
  final bool retryable;
  final Object? cause;

  TravelAssistantFailure copyWith({
    TravelAssistantFailureType? type,
    String? message,
    String? code,
    int? statusCode,
    bool? retryable,
    Object? cause,
  }) {
    return TravelAssistantFailure(
      type: type ?? this.type,
      message: message ?? this.message,
      code: code ?? this.code,
      statusCode: statusCode ?? this.statusCode,
      retryable: retryable ?? this.retryable,
      cause: cause ?? this.cause,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer('TravelAssistantFailure(')
      ..write('type: $type, ');
    if (code != null) buffer.write('code: $code, ');
    if (statusCode != null) buffer.write('statusCode: $statusCode, ');
    buffer
      ..write('retryable: $retryable, ')
      ..write('message: $message')
      ..write(')');
    return buffer.toString();
  }
}
