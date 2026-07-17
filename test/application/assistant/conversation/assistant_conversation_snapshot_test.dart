import 'package:flutter_test/flutter_test.dart';
import 'package:goplan/application/assistant/conversation/assistant_conversation_snapshot.dart';
import 'package:goplan/application/assistant/conversation/assistant_conversation_summary.dart';
import 'package:goplan/application/assistant/conversation/assistant_message_snapshot.dart';
import 'package:goplan/application/assistant/travel_assistant_message_role.dart';
import 'package:goplan/domain/assistant/assistant_status.dart';
import 'package:goplan/domain/itinerary/itinerary.dart';
import 'package:goplan/domain/itinerary/itinerary_warning.dart';
import 'package:goplan/domain/trip/trip_state.dart';

void main() {
  final createdAt = DateTime(2026, 7, 16, 9);
  final updatedAt = DateTime(2026, 7, 16, 10);

  AssistantConversationSnapshot snapshot({String? title}) {
    return AssistantConversationSnapshot(
      id: ' local_1 ',
      userId: ' user_1 ',
      tripId: ' trip_1 ',
      conversationId: ' ',
      title: title,
      createdAt: createdAt,
      updatedAt: updatedAt,
      messages: [
        AssistantMessageSnapshot(
          id: 'message_1',
          role: TravelAssistantMessageRole.user,
          text: 'Plan a very gentle Hangzhou weekend with cafes',
          createdAt: createdAt,
        ),
      ],
      tripState: TripState(destination: 'Hangzhou'),
      itinerary: Itinerary(title: 'Hangzhou draft', destination: 'Hangzhou'),
      warnings: const [
        ItineraryWarning(id: 'w1', type: 'weather', message: 'rain'),
      ],
      assistantStatus: AssistantStatus.draft,
    );
  }

  test('complete snapshot round trips and normalizes ids', () {
    final restored = AssistantConversationSnapshot.fromJson(
      snapshot().toJson(),
    );

    expect(restored.id, 'local_1');
    expect(restored.userId, 'user_1');
    expect(restored.tripId, 'trip_1');
    expect(restored.conversationId, isNull);
    expect(restored.title, 'Hangzhou draft');
    expect(restored.messages.single.id, 'message_1');
    expect(restored.tripState!.destination, 'Hangzhou');
    expect(restored.itinerary!.title, 'Hangzhou draft');
    expect(restored.warnings.single.id, 'w1');
    expect(restored.assistantStatus, AssistantStatus.draft);
  });

  test('explicit title wins and lists are immutable', () {
    final current = snapshot(title: 'My trip');

    expect(current.title, 'My trip');
    expect(
      () => current.messages.add(current.messages.single),
      throwsUnsupportedError,
    );
    expect(() => current.warnings.clear(), throwsUnsupportedError);
  });

  test('title falls back to destination, first user message, then default', () {
    expect(
      AssistantConversationSnapshot(
        id: 'a',
        userId: 'u',
        tripId: 't',
        createdAt: createdAt,
        updatedAt: updatedAt,
        tripState: TripState(destination: 'Yunnan'),
      ).title,
      'Yunnan',
    );

    expect(
      AssistantConversationSnapshot(
        id: 'b',
        userId: 'u',
        tripId: 't',
        createdAt: createdAt,
        updatedAt: updatedAt,
        messages: [
          AssistantMessageSnapshot(
            id: 'message_1',
            role: TravelAssistantMessageRole.user,
            text: 'abcdefghijklmnopqrstuvwxyz',
            createdAt: createdAt,
          ),
        ],
      ).title,
      'abcdefghijklmnopqrstuvwx',
    );

    expect(
      AssistantConversationSnapshot(
        id: 'c',
        userId: 'u',
        tripId: 't',
        createdAt: createdAt,
        updatedAt: updatedAt,
      ).title,
      '新的旅行计划',
    );
  });

  test('summary omits full content and conversationId', () {
    final summary = AssistantConversationSummary.fromSnapshot(snapshot());

    expect(summary.id, 'local_1');
    expect(summary.destination, 'Hangzhou');
    expect(summary.messageCount, 1);
    expect(summary.hasItinerary, isTrue);
  });

  test('toString is safe', () {
    final text = snapshot(
      title: 'safe',
    ).copyWith(conversationId: 'conv_secret_123').toString();

    expect(text, contains('hasConversationId: true'));
    expect(text, isNot(contains('conv_secret_123')));
  });
}
