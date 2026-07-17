import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../application/assistant/travel_assistant_exception.dart';
import '../../../application/assistant/travel_assistant_failure.dart';
import '../../../application/assistant/travel_assistant_gateway.dart';
import '../../../domain/assistant/assistant_request.dart';
import '../../../domain/assistant/assistant_response.dart';
import 'dify_gateway_config.dart';
import 'dify_request_mapper.dart';
import 'dify_response_mapper.dart';

class DifyTravelAssistantGateway implements TravelAssistantGateway {
  const DifyTravelAssistantGateway({
    required this.client,
    required this.config,
    this.requestMapper = const DifyRequestMapper(),
    this.responseMapper = const DifyResponseMapper(),
    this.delay,
  });

  final http.Client client;
  final DifyGatewayConfig config;
  final DifyRequestMapper requestMapper;
  final DifyResponseMapper responseMapper;
  final Future<void> Function(Duration duration)? delay;

  @override
  Future<AssistantResponse> send(AssistantRequest request) async {
    _validateConfiguration(request);
    final body = requestMapper.map(request);
    final attempts = config.maxAttempts < 1 ? 1 : config.maxAttempts;

    TravelAssistantException? lastFailure;
    for (var attempt = 1; attempt <= attempts; attempt++) {
      try {
        return await _sendOnce(body);
      } on TravelAssistantException catch (error) {
        lastFailure = error;
        if (!_isRetryable(error.failure) || attempt >= attempts) rethrow;
        await _delayForAttempt(attempt);
      } on TimeoutException catch (error) {
        lastFailure = TravelAssistantException(
          TravelAssistantFailure.timeout(message: 'Dify 请求超时。', cause: error),
        );
        if (attempt >= attempts) throw lastFailure;
        await _delayForAttempt(attempt);
      } on http.ClientException catch (error) {
        lastFailure = TravelAssistantException(
          TravelAssistantFailure.network(message: 'Dify 网络连接失败。', cause: error),
        );
        if (attempt >= attempts) throw lastFailure;
        await _delayForAttempt(attempt);
      } on Object catch (error) {
        throw TravelAssistantException(
          TravelAssistantFailure(
            type: TravelAssistantFailureType.unknown,
            message: 'Dify 请求失败。',
            cause: error,
          ),
        );
      }
    }

    throw lastFailure ??
        TravelAssistantException(
          TravelAssistantFailure(
            type: TravelAssistantFailureType.unknown,
            message: 'Dify 请求失败。',
          ),
        );
  }

  Future<AssistantResponse> _sendOnce(Map<String, Object?> body) async {
    final response = await client
        .post(
          _chatMessagesUri(),
          headers: {
            'Authorization': 'Bearer ${config.apiKey}',
            'Accept': 'application/json',
            'Content-Type': 'application/json; charset=utf-8',
            'User-Agent': config.userAgent,
            'Connection': 'close',
          },
          body: jsonEncode(body),
        )
        .timeout(config.timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw TravelAssistantException(_failureForHttp(response));
    }

    final decoded = _decodeBody(response);
    return responseMapper.mapResponse(decoded);
  }

  Map<String, Object?> _decodeBody(http.Response response) {
    final body = utf8.decode(response.bodyBytes);
    Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException catch (error) {
      throw TravelAssistantException(
        TravelAssistantFailure.invalidResponse(
          message: 'Dify 返回的响应不是有效 JSON。',
          cause: error,
        ),
      );
    }
    if (decoded is! Map) {
      throw TravelAssistantException(
        TravelAssistantFailure.invalidResponse(message: 'Dify 返回的响应格式无效。'),
      );
    }
    return decoded.map((key, value) => MapEntry(key.toString(), value));
  }

  TravelAssistantFailure _failureForHttp(http.Response response) {
    final type = _failureTypeForStatus(response.statusCode);
    return TravelAssistantFailure(
      type: type,
      message: _safeHttpMessage(response),
      code: _safeHttpCode(response),
      statusCode: response.statusCode,
      retryable: _retryableHttpType(type),
    );
  }

  TravelAssistantFailureType _failureTypeForStatus(int statusCode) {
    if (statusCode == 400 || statusCode == 422) {
      return TravelAssistantFailureType.invalidRequest;
    }
    if (statusCode == 401 || statusCode == 403) {
      return TravelAssistantFailureType.unauthorized;
    }
    if (statusCode == 429) return TravelAssistantFailureType.rateLimited;
    if (statusCode == 500 ||
        statusCode == 502 ||
        statusCode == 503 ||
        statusCode == 504) {
      return TravelAssistantFailureType.serviceUnavailable;
    }
    if (statusCode >= 400 && statusCode <= 499) {
      return TravelAssistantFailureType.invalidRequest;
    }
    if (statusCode >= 500 && statusCode <= 599) {
      return TravelAssistantFailureType.serviceUnavailable;
    }
    return TravelAssistantFailureType.unknown;
  }

  String _safeHttpMessage(http.Response response) {
    final fallback = 'Dify 服务返回 HTTP ${response.statusCode}。';
    final body = utf8.decode(response.bodyBytes, allowMalformed: true);
    if (body.trim().startsWith('<')) return fallback;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final message = decoded['message']?.toString().trim();
        if (message != null && message.isNotEmpty) {
          return message.length > 300
              ? '${message.substring(0, 300)}...'
              : message;
        }
      }
    } on FormatException {
      return fallback;
    }
    return fallback;
  }

  String? _safeHttpCode(http.Response response) {
    final body = utf8.decode(response.bodyBytes, allowMalformed: true);
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final code = decoded['code']?.toString().trim();
        if (code != null && code.isNotEmpty && code.length <= 80) return code;
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  Uri _chatMessagesUri() {
    final base = config.apiBaseUri.toString();
    final normalized = base.endsWith('/') ? base : '$base/';
    return Uri.parse(normalized).resolve('chat-messages');
  }

  void _validateConfiguration(AssistantRequest request) {
    if (config.apiKey.trim().isEmpty) {
      throw TravelAssistantException(
        TravelAssistantFailure.configuration(message: 'Dify API 配置缺失。'),
      );
    }
    if (config.apiBaseUri.scheme != 'http' &&
        config.apiBaseUri.scheme != 'https') {
      throw TravelAssistantException(
        TravelAssistantFailure.configuration(message: 'Dify API Base URI 无效。'),
      );
    }
    if (request.userId.trim().isEmpty) {
      throw TravelAssistantException(
        const TravelAssistantFailure(
          type: TravelAssistantFailureType.invalidRequest,
          message: 'AssistantRequest.userId 不能为空。',
        ),
      );
    }
    if (request.tripId.trim().isEmpty) {
      throw TravelAssistantException(
        const TravelAssistantFailure(
          type: TravelAssistantFailureType.invalidRequest,
          message: 'AssistantRequest.tripId 不能为空。',
        ),
      );
    }
  }

  bool _isRetryable(TravelAssistantFailure failure) {
    return failure.type == TravelAssistantFailureType.network ||
        failure.type == TravelAssistantFailureType.timeout ||
        failure.type == TravelAssistantFailureType.rateLimited ||
        failure.type == TravelAssistantFailureType.serviceUnavailable;
  }

  bool _retryableHttpType(TravelAssistantFailureType type) {
    return type == TravelAssistantFailureType.rateLimited ||
        type == TravelAssistantFailureType.serviceUnavailable;
  }

  Future<void> _delayForAttempt(int attempt) {
    final wait = Duration(milliseconds: 700 * attempt);
    return (delay ?? Future<void>.delayed)(wait);
  }
}
