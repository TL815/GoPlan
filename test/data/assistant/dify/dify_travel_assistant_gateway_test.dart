import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:goplan/application/assistant/travel_assistant_exception.dart';
import 'package:goplan/application/assistant/travel_assistant_failure.dart';
import 'package:goplan/data/assistant/dify/dify_gateway_config.dart';
import 'package:goplan/data/assistant/dify/dify_travel_assistant_gateway.dart';
import 'package:goplan/domain/assistant/assistant_request.dart';
import 'package:goplan/domain/assistant/assistant_status.dart';
import 'package:goplan/domain/assistant/client_event.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/fake_http_client.dart';

void main() {
  const testKey = 'test_dify_key';

  DifyGatewayConfig config({int maxAttempts = 3, Uri? apiBaseUri}) {
    return DifyGatewayConfig(
      apiBaseUri: apiBaseUri ?? Uri.parse('https://api.dify.ai/v1'),
      apiKey: testKey,
      timeout: const Duration(seconds: 1),
      maxAttempts: maxAttempts,
      userAgent: 'GoPlanTest/1.0',
    );
  }

  AssistantRequest request({String? conversationId, String query = '去云南'}) {
    return AssistantRequest(
      userId: 'user_1',
      tripId: 'trip_1',
      conversationId: conversationId,
      query: query,
      event: ClientEvent.chatMessage('去云南'),
      tripSnapshot: const {'destination': '云南'},
    );
  }

  String okBody({
    String conversationId = 'conv_response',
    String status = 'success',
  }) {
    return jsonEncode({
      'conversation_id': conversationId,
      'answer': jsonEncode({
        'schema_version': '1.0',
        'status': status,
        'message': status == 'error' ? '业务错误' : 'ok',
      }),
    });
  }

  Map<String, Object?> requestBody(FakeHttpClient client) {
    return jsonDecode(client.requests.single.body) as Map<String, Object?>;
  }

  test('posts to chat-messages with headers and standard body', () async {
    final client = FakeHttpClient([FakeHttpClient.response(200, okBody())]);
    final gateway = DifyTravelAssistantGateway(
      client: client,
      config: config(),
    );

    final response = await gateway.send(
      request(conversationId: 'conv_request'),
    );
    final sent = client.requests.single;
    final body = requestBody(client);

    expect(response.conversationId, 'conv_response');
    expect(sent.method, 'POST');
    expect(sent.url.toString(), 'https://api.dify.ai/v1/chat-messages');
    expect(sent.headers['Authorization'], 'Bearer $testKey');
    expect(sent.headers['Accept'], 'application/json');
    expect(sent.headers['Content-Type'], 'application/json; charset=utf-8');
    expect(sent.headers['User-Agent'], 'GoPlanTest/1.0');
    expect(body['response_mode'], 'blocking');
    expect(body['user'], 'user_1');
    expect(body['conversation_id'], 'conv_request');
  });

  test(
    'handles apiBaseUri trailing slash without double path issues',
    () async {
      final client = FakeHttpClient([FakeHttpClient.response(200, okBody())]);
      final gateway = DifyTravelAssistantGateway(
        client: client,
        config: config(apiBaseUri: Uri.parse('https://api.dify.ai/v1/')),
      );

      await gateway.send(request());

      expect(
        client.requests.single.url.toString(),
        'https://api.dify.ai/v1/chat-messages',
      );
    },
  );

  test('does not cache conversationId across calls', () async {
    final client = FakeHttpClient([
      FakeHttpClient.response(200, okBody(conversationId: 'conv_a')),
      FakeHttpClient.response(200, okBody(conversationId: 'conv_b')),
    ]);
    final gateway = DifyTravelAssistantGateway(
      client: client,
      config: config(),
    );

    await gateway.send(request(conversationId: 'request_a'));
    await gateway.send(request(conversationId: 'request_b'));

    final firstBody =
        jsonDecode(client.requests[0].body) as Map<String, Object?>;
    final secondBody =
        jsonDecode(client.requests[1].body) as Map<String, Object?>;
    expect(firstBody['conversation_id'], 'request_a');
    expect(secondBody['conversation_id'], 'request_b');
  });

  test(
    'configuration and invalid request failures do not send requests',
    () async {
      Future<TravelAssistantFailure> failureFor(
        DifyGatewayConfig cfg,
        AssistantRequest req,
      ) async {
        final client = FakeHttpClient([FakeHttpClient.response(200, okBody())]);
        final gateway = DifyTravelAssistantGateway(client: client, config: cfg);
        try {
          await gateway.send(req);
        } on TravelAssistantException catch (error) {
          expect(client.requestCount, 0);
          return error.failure;
        }
        fail('Expected TravelAssistantException');
      }

      expect(
        (await failureFor(
          DifyGatewayConfig(
            apiBaseUri: Uri.parse('https://api.dify.ai/v1'),
            apiKey: '',
          ),
          request(),
        )).type,
        TravelAssistantFailureType.configuration,
      );
      expect(
        (await failureFor(
          config(apiBaseUri: Uri.parse('file:///tmp/dify')),
          request(),
        )).type,
        TravelAssistantFailureType.configuration,
      );
      expect(
        (await failureFor(
          config(),
          AssistantRequest(
            userId: '',
            tripId: 'trip_1',
            query: '',
            event: ClientEvent.chatMessage('hi'),
          ),
        )).type,
        TravelAssistantFailureType.invalidRequest,
      );
      expect(
        (await failureFor(
          config(),
          AssistantRequest(
            userId: 'user_1',
            tripId: '',
            query: '',
            event: ClientEvent.chatMessage('hi'),
          ),
        )).type,
        TravelAssistantFailureType.invalidRequest,
      );
    },
  );

  test('maps HTTP errors to structured failures and retry flags', () async {
    final cases = <int, TravelAssistantFailureType>{
      400: TravelAssistantFailureType.invalidRequest,
      401: TravelAssistantFailureType.unauthorized,
      403: TravelAssistantFailureType.unauthorized,
      422: TravelAssistantFailureType.invalidRequest,
      429: TravelAssistantFailureType.rateLimited,
      500: TravelAssistantFailureType.serviceUnavailable,
      503: TravelAssistantFailureType.serviceUnavailable,
      418: TravelAssistantFailureType.invalidRequest,
      599: TravelAssistantFailureType.serviceUnavailable,
      302: TravelAssistantFailureType.unknown,
    };

    for (final entry in cases.entries) {
      final client = FakeHttpClient([
        FakeHttpClient.response(
          entry.key,
          jsonEncode({'code': 'ERR_${entry.key}', 'message': 'short error'}),
        ),
      ]);
      final gateway = DifyTravelAssistantGateway(
        client: client,
        config: config(maxAttempts: 1),
      );

      try {
        await gateway.send(request());
        fail('Expected failure for ${entry.key}');
      } on TravelAssistantException catch (error) {
        expect(error.failure.type, entry.value);
        expect(error.failure.statusCode, entry.key);
        expect(error.failure.code, 'ERR_${entry.key}');
        expect(error.failure.message, 'short error');
      }
    }
  });

  test(
    'invalid JSON and non-map top-level responses map to invalidResponse',
    () async {
      for (final body in ['not json', '[]']) {
        final client = FakeHttpClient([FakeHttpClient.response(200, body)]);
        final gateway = DifyTravelAssistantGateway(
          client: client,
          config: config(),
        );

        expect(
          () => gateway.send(request()),
          throwsA(
            isA<TravelAssistantException>().having(
              (error) => error.failure.type,
              'type',
              TravelAssistantFailureType.invalidResponse,
            ),
          ),
        );
      }
    },
  );

  test('network, timeout, 503, and 429 retry then succeed', () async {
    final scenarios = <String, Object>{
      'network': http.ClientException('offline'),
      'timeout': TimeoutException('slow'),
      '503': 503,
      '429': 429,
    };

    for (final scenario in scenarios.entries) {
      final delays = <Duration>[];
      final handlers = [
        if (scenario.value is int)
          FakeHttpClient.response(scenario.value as int, '{}')
        else
          FakeHttpClient.exception(scenario.value),
        FakeHttpClient.response(
          200,
          okBody(conversationId: 'conv_${scenario.key}'),
        ),
      ];
      final client = FakeHttpClient(handlers);
      final gateway = DifyTravelAssistantGateway(
        client: client,
        config: config(maxAttempts: 2),
        delay: (duration) async => delays.add(duration),
      );

      final response = await gateway.send(request());

      expect(response.conversationId, 'conv_${scenario.key}');
      expect(client.requestCount, 2);
      expect(delays, [const Duration(milliseconds: 700)]);
    }
  });

  test('does not retry non-retryable failures', () async {
    final cases = [
      FakeHttpClient.response(400, '{}'),
      FakeHttpClient.response(401, '{}'),
      FakeHttpClient.response(200, 'not json'),
    ];

    for (final handler in cases) {
      final client = FakeHttpClient([
        handler,
        FakeHttpClient.response(200, okBody()),
      ]);
      final gateway = DifyTravelAssistantGateway(
        client: client,
        config: config(maxAttempts: 3),
      );

      expect(
        () => gateway.send(request()),
        throwsA(isA<TravelAssistantException>()),
      );
      await Future<void>.delayed(Duration.zero);
      expect(client.requestCount, 1);
    }
  });

  test(
    'maxAttempts zero still sends once and final failure is thrown',
    () async {
      final client = FakeHttpClient([FakeHttpClient.response(503, '{}')]);
      final gateway = DifyTravelAssistantGateway(
        client: client,
        config: config(maxAttempts: 0),
        delay: (_) async => fail('No delay expected'),
      );

      expect(
        () => gateway.send(request()),
        throwsA(
          isA<TravelAssistantException>().having(
            (error) => error.failure.type,
            'type',
            TravelAssistantFailureType.serviceUnavailable,
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(client.requestCount, 1);
    },
  );

  test('mapper TravelAssistantException propagates unchanged', () async {
    final client = FakeHttpClient([
      FakeHttpClient.response(200, '{"answer": null}'),
    ]);
    final gateway = DifyTravelAssistantGateway(
      client: client,
      config: config(),
    );

    expect(
      () => gateway.send(request()),
      throwsA(
        isA<TravelAssistantException>().having(
          (error) => error.failure.type,
          'type',
          TravelAssistantFailureType.invalidResponse,
        ),
      ),
    );
  });

  test('standard business error status returns normally', () async {
    final client = FakeHttpClient([
      FakeHttpClient.response(200, okBody(status: 'error')),
    ]);
    final gateway = DifyTravelAssistantGateway(
      client: client,
      config: config(),
    );

    final response = await gateway.send(request());

    expect(response.status, AssistantStatus.error);
    expect(response.message, '业务错误');
  });

  test(
    'exception strings do not contain key, Authorization, or request body',
    () async {
      final client = FakeHttpClient([
        FakeHttpClient.response(400, '<html>bad</html>'),
      ]);
      final gateway = DifyTravelAssistantGateway(
        client: client,
        config: config(),
      );

      try {
        await gateway.send(request(query: 'sensitive full query'));
        fail('Expected failure');
      } on TravelAssistantException catch (error) {
        final text = error.toString();
        expect(text, isNot(contains(testKey)));
        expect(text, isNot(contains('Authorization')));
        expect(text, isNot(contains('sensitive full query')));
        expect(text, isNot(contains('destination')));
      }
    },
  );
}
