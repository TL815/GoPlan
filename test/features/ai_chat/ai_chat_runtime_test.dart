import 'package:flutter_test/flutter_test.dart';
import 'package:goplan/application/assistant/conversation/assistant_conversation_snapshot.dart';
import 'package:goplan/application/assistant/conversation/assistant_message_snapshot.dart';
import 'package:goplan/application/assistant/travel_assistant_message_role.dart';
import 'package:goplan/domain/assistant/assistant_response.dart';
import 'package:goplan/domain/assistant/assistant_status.dart';
import 'package:goplan/features/ai_chat/ai_chat_runtime.dart';
import 'package:goplan/features/ai_chat/ai_chat_runtime_config.dart';
import 'package:goplan/features/ai_chat/conversation/ai_chat_session_bootstrap.dart';
import 'package:http/http.dart' as http;

import '../../helpers/fake_travel_assistant_gateway.dart';

void main() {
  test('runtime config reads stable defaults from environment', () {
    final config = AiChatRuntimeConfig.fromEnvironment();

    expect(config.userId, AiChatRuntimeConfig.defaultUserId);
    expect(config.tripId, AiChatRuntimeConfig.defaultTripId);
    expect(config.timezone, AiChatRuntimeConfig.defaultTimezone);
  });

  test('withGateway creates controller and does not access network', () async {
    final client = _CloseTrackingClient();
    final gateway = FakeTravelAssistantGateway(
      response: AssistantResponse(
        conversationId: 'conv_runtime',
        status: AssistantStatus.success,
        message: 'ok',
      ),
    );

    final runtime = AiChatRuntime.withGateway(
      gateway: gateway,
      httpClient: client,
      config: const AiChatRuntimeConfig(
        userId: 'user_runtime',
        tripId: 'trip_runtime',
        timezone: 'Asia/Shanghai',
      ),
      contextProvider: () => throw StateError('context should not be read'),
      isMounted: () => true,
      ownsHttpClient: true,
    );
    addTearDown(runtime.dispose);

    expect(runtime.controller.state.userId, 'user_runtime');
    expect(runtime.controller.state.tripId, 'trip_runtime');

    await runtime.controller.sendMessage('hello');

    expect(gateway.callCount, 1);
    expect(client.sendCount, 0);
    expect(runtime.controller.state.conversationId, 'conv_runtime');
  });

  test('dispose is idempotent and closes owned resources', () {
    final client = _CloseTrackingClient();
    final runtime = AiChatRuntime.withGateway(
      gateway: FakeTravelAssistantGateway(
        response: AssistantResponse(status: AssistantStatus.success),
      ),
      httpClient: client,
      config: const AiChatRuntimeConfig(
        userId: 'user_runtime',
        tripId: 'trip_runtime',
        timezone: 'Asia/Shanghai',
      ),
      contextProvider: () => throw StateError('context should not be read'),
      isMounted: () => true,
      ownsHttpClient: true,
    );

    runtime.dispose();
    runtime.dispose();

    expect(client.closeCount, 1);
    expect(
      () => runtime.controller.sendMessage('after dispose'),
      throwsStateError,
    );
  });

  test('withGateway restores snapshot without calling gateway', () async {
    final client = _CloseTrackingClient();
    final gateway = FakeTravelAssistantGateway(
      response: AssistantResponse(
        conversationId: 'provider_restored',
        status: AssistantStatus.success,
        message: 'next',
      ),
    );
    final createdAt = DateTime(2026, 7, 1);
    final snapshot = AssistantConversationSnapshot(
      id: 'local_restored',
      userId: 'user_runtime',
      tripId: 'trip_runtime',
      conversationId: 'provider_restored',
      createdAt: createdAt,
      updatedAt: DateTime(2026, 7, 17),
      messages: [
        AssistantMessageSnapshot(
          id: 'message_1',
          role: TravelAssistantMessageRole.user,
          text: 'saved hello',
          createdAt: createdAt,
        ),
      ],
    );

    final runtime = AiChatRuntime.withGateway(
      gateway: gateway,
      httpClient: client,
      config: const AiChatRuntimeConfig(
        userId: 'ignored_user',
        tripId: 'ignored_trip',
        timezone: 'Asia/Shanghai',
      ),
      contextProvider: () => throw StateError('context should not be read'),
      isMounted: () => true,
      ownsHttpClient: true,
      bootstrapResult: AiChatBootstrapResult(
        localConversationId: snapshot.id,
        createdAt: snapshot.createdAt,
        snapshot: snapshot,
        isNewConversation: false,
      ),
    );
    addTearDown(runtime.dispose);

    expect(gateway.callCount, 0);
    expect(runtime.localConversationId, 'local_restored');
    expect(runtime.controller.state.messages.single.text, 'saved hello');
    expect(runtime.controller.state.conversationId, 'provider_restored');

    await runtime.controller.sendMessage('next please');

    expect(gateway.callCount, 1);
    expect(gateway.lastRequest!.conversationId, 'provider_restored');
  });
}

class _CloseTrackingClient extends http.BaseClient {
  int sendCount = 0;
  int closeCount = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    sendCount += 1;
    throw StateError('network should not be used');
  }

  @override
  void close() {
    closeCount += 1;
    super.close();
  }
}
