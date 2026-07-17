import 'package:flutter_test/flutter_test.dart';
import 'package:goplan/application/assistant/travel_assistant_message.dart';
import 'package:goplan/application/assistant/travel_assistant_message_role.dart';
import 'package:goplan/application/assistant/travel_assistant_phase.dart';
import 'package:goplan/application/assistant/travel_assistant_state.dart';
import 'package:goplan/domain/assistant/assistant_response.dart';
import 'package:goplan/domain/assistant/assistant_status.dart';
import 'package:goplan/domain/assistant/ui_action_type.dart';
import 'package:goplan/domain/itinerary/itinerary_warning.dart';
import 'package:goplan/domain/trip/trip_state.dart';

void main() {
  test('initial state normalizes fields and exposes convenience getters', () {
    final state = TravelAssistantState.initial(
      userId: ' user_1 ',
      tripId: ' trip_1 ',
      timezone: ' ',
      conversationId: ' conv_1 ',
      tripState: TripState(destination: 'Yunnan'),
    );

    expect(state.phase, TravelAssistantPhase.idle);
    expect(state.messages, isEmpty);
    expect(state.userId, 'user_1');
    expect(state.tripId, 'trip_1');
    expect(state.timezone, 'Asia/Shanghai');
    expect(state.conversationId, 'conv_1');
    expect(state.uiAction.type, UiActionType.none);
    expect(state.assistantStatus, isNull);
    expect(state.lastResponse, isNull);
    expect(state.lastFailure, isNull);
    expect(state.hasConversation, isTrue);
    expect(state.hasItinerary, isFalse);
  });

  test('messages and warnings are immutable', () {
    final message = TravelAssistantMessage(
      id: 'message_1',
      role: TravelAssistantMessageRole.user,
      text: 'hi',
      createdAt: DateTime(2026, 7, 15),
    );
    final warning = ItineraryWarning(
      id: 'warning_1',
      type: 'date',
      message: 'check date',
    );
    final state = TravelAssistantState(
      phase: TravelAssistantPhase.ready,
      userId: 'user_1',
      tripId: 'trip_1',
      messages: [message],
      warnings: [warning],
      assistantStatus: AssistantStatus.needInput,
      lastResponse: AssistantResponse(status: AssistantStatus.needInput),
    );

    expect(() => state.messages.add(message), throwsUnsupportedError);
    expect(() => state.warnings.add(warning), throwsUnsupportedError);
    expect(state.needsInput, isTrue);
  });

  test('copyWith can clear nullable fields', () {
    final state = TravelAssistantState.initial(
      userId: 'user_1',
      tripId: 'trip_1',
      conversationId: 'conv_1',
    ).copyWith(assistantStatus: AssistantStatus.success);

    final cleared = state.copyWith(conversationId: null, assistantStatus: null);

    expect(cleared.conversationId, isNull);
    expect(cleared.assistantStatus, isNull);
  });
}
