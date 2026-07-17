import 'package:flutter_test/flutter_test.dart';
import 'package:goplan/application/assistant/travel_assistant_exception.dart';
import 'package:goplan/application/assistant/travel_assistant_failure.dart';
import 'package:goplan/application/assistant/travel_assistant_gateway.dart';
import 'package:goplan/domain/assistant/assistant_request.dart';
import 'package:goplan/domain/assistant/assistant_response.dart';
import 'package:goplan/domain/assistant/assistant_status.dart';
import 'package:goplan/domain/assistant/client_event.dart';

import '../../helpers/fake_travel_assistant_gateway.dart';

void main() {
  AssistantRequest request() {
    return AssistantRequest(
      userId: 'user_1',
      tripId: 'trip_1',
      conversationId: 'conv_1',
      query: '去云南',
      event: ClientEvent.chatMessage('去云南'),
    );
  }

  test('FakeTravelAssistantGateway implements TravelAssistantGateway', () {
    final gateway = FakeTravelAssistantGateway(
      response: AssistantResponse(
        status: AssistantStatus.success,
        message: 'ok',
      ),
    );

    expect(gateway, isA<TravelAssistantGateway>());
  });

  test(
    'send returns preset AssistantResponse and records request/count',
    () async {
      final response = AssistantResponse(
        status: AssistantStatus.success,
        message: '已生成',
      );
      final gateway = FakeTravelAssistantGateway(response: response);
      final firstRequest = request();

      final result = await gateway.send(firstRequest);
      await gateway.send(firstRequest);

      expect(result, same(response));
      expect(gateway.lastRequest, same(firstRequest));
      expect(gateway.callCount, 2);
    },
  );

  test('send can throw preset TravelAssistantException', () async {
    final exception = TravelAssistantException(
      TravelAssistantFailure.timeout(message: 'timeout'),
    );
    final gateway = FakeTravelAssistantGateway(exception: exception);

    expect(() => gateway.send(request()), throwsA(same(exception)));
  });

  test('error status can be returned as a normal AssistantResponse', () async {
    final response = AssistantResponse(
      status: AssistantStatus.error,
      message: '缺少日期',
    );
    final gateway = FakeTravelAssistantGateway(response: response);

    final result = await gateway.send(request());

    expect(result.status, AssistantStatus.error);
    expect(result.message, '缺少日期');
  });

  test('can return response with conversationId', () async {
    final response = AssistantResponse(
      conversationId: 'conv_from_provider',
      status: AssistantStatus.needInput,
      message: '请选择日期',
    );
    final gateway = FakeTravelAssistantGateway(response: response);

    final result = await gateway.send(request());

    expect(result.conversationId, 'conv_from_provider');
  });

  test('does not cache or generate conversationId internally', () async {
    final response = AssistantResponse(status: AssistantStatus.success);
    final gateway = FakeTravelAssistantGateway(response: response);
    final firstRequest = request();
    final secondRequest = AssistantRequest(
      userId: 'user_1',
      tripId: 'trip_1',
      query: '继续',
      event: ClientEvent.chatMessage('继续'),
    );

    final first = await gateway.send(firstRequest);
    final second = await gateway.send(secondRequest);

    expect(first.conversationId, isNull);
    expect(second.conversationId, isNull);
    expect(gateway.lastRequest?.conversationId, isNull);
    expect(gateway.callCount, 2);
  });
}
