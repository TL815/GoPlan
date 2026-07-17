import 'package:flutter_test/flutter_test.dart';
import 'package:goplan/application/assistant/conversation/travel_assistant_session_mapper.dart';
import 'package:goplan/application/assistant/travel_assistant_controller.dart';
import 'package:goplan/application/assistant/travel_assistant_message.dart';
import 'package:goplan/application/assistant/travel_assistant_message_role.dart';
import 'package:goplan/application/assistant/travel_assistant_phase.dart';
import 'package:goplan/domain/assistant/assistant_response.dart';
import 'package:goplan/domain/assistant/assistant_status.dart';
import 'package:goplan/domain/itinerary/itinerary_warning.dart';
import 'package:goplan/domain/trip/trip_state.dart';

import '../../../helpers/fake_travel_assistant_gateway.dart';

void main() {
  final createdAt = DateTime(2026, 7, 16, 9);
  final updatedAt = DateTime(2026, 7, 16, 10);

  test('maps state to snapshot without transient fields', () {
    final controller = TravelAssistantController(
      gateway: FakeTravelAssistantGateway(
        response: AssistantResponse(status: AssistantStatus.success),
      ),
      userId: 'user_1',
      tripId: 'trip_1',
      initialConversationId: 'conv_1',
      initialMessages: [
        TravelAssistantMessage(
          id: 'message_1',
          role: TravelAssistantMessageRole.user,
          text: 'hello',
          createdAt: createdAt,
        ),
      ],
      initialTripState: TripState(destination: 'Yunnan'),
      initialWarnings: const [
        ItineraryWarning(id: 'w1', type: 'note', message: 'note'),
      ],
      initialAssistantStatus: AssistantStatus.needInput,
    );
    addTearDown(controller.dispose);

    final snapshot = const TravelAssistantSessionMapper().fromState(
      state: controller.state,
      localConversationId: 'local_1',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    expect(snapshot.id, 'local_1');
    expect(snapshot.conversationId, 'conv_1');
    expect(snapshot.tripState!.destination, 'Yunnan');
    expect(snapshot.warnings.single.id, 'w1');
    expect(snapshot.assistantStatus, AssistantStatus.needInput);
    expect(snapshot.toJson().containsKey('phase'), isFalse);
    expect(snapshot.toJson().containsKey('last_response'), isFalse);
    expect(snapshot.toJson().containsKey('ui_action'), isFalse);
  });

  test('restores messages and controller can continue ids', () async {
    final snapshot = const TravelAssistantSessionMapper().fromState(
      state: TravelAssistantController(
        gateway: FakeTravelAssistantGateway(
          response: AssistantResponse(status: AssistantStatus.success),
        ),
        userId: 'user_1',
        tripId: 'trip_1',
        initialMessages: [
          TravelAssistantMessage(
            id: 'message_2',
            role: TravelAssistantMessageRole.user,
            text: 'old',
            createdAt: createdAt,
          ),
          TravelAssistantMessage(
            id: 'custom',
            role: TravelAssistantMessageRole.assistant,
            text: 'custom',
            createdAt: createdAt,
          ),
        ],
      ).state,
      localConversationId: 'local_1',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    final restore = const TravelAssistantSessionMapper().restore(snapshot);
    final gateway = FakeTravelAssistantGateway(
      response: AssistantResponse(
        status: AssistantStatus.success,
        message: 'new',
      ),
    );
    final controller = TravelAssistantController(
      gateway: gateway,
      userId: restore.userId,
      tripId: restore.tripId,
      initialMessages: restore.messages,
    );
    addTearDown(controller.dispose);

    expect(controller.state.phase, TravelAssistantPhase.idle);
    expect(controller.state.lastResponse, isNull);
    expect(controller.state.uiAction.type.name, 'none');

    await controller.sendMessage('next');

    expect(controller.state.messages.last.id, 'message_4');
  });
}
