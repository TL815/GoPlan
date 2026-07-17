import 'package:flutter_test/flutter_test.dart';
import 'package:goplan/application/assistant/conversation/assistant_conversation_snapshot.dart';
import 'package:goplan/application/assistant/conversation/assistant_message_snapshot.dart';
import 'package:goplan/application/assistant/conversation/conversation_store_exception.dart';
import 'package:goplan/application/assistant/travel_assistant_message_role.dart';
import 'package:goplan/data/assistant/conversation/conversation_json_document.dart';

void main() {
  final now = DateTime(2026, 7, 16, 9);

  AssistantConversationSnapshot conversation(String id) {
    return AssistantConversationSnapshot(
      id: id,
      userId: 'user_1',
      tripId: 'trip_1',
      title: 'Trip',
      createdAt: now,
      updatedAt: now,
      messages: [
        AssistantMessageSnapshot(
          id: 'message_1',
          role: TravelAssistantMessageRole.user,
          text: 'hello',
          createdAt: now,
        ),
      ],
    );
  }

  test('empty document encodes current schema version', () {
    final json = ConversationJsonDocument.empty().toJson();

    expect(json['schema_version'], 1);
    expect(json['conversations'], isEmpty);
  });

  test('version 1 document round trips', () {
    final source = ConversationJsonDocument(
      conversations: [conversation('local_1')],
    ).encode();

    final decoded = ConversationJsonDocument.decode(source);

    expect(decoded.schemaVersion, 1);
    expect(decoded.conversations.single.id, 'local_1');
  });

  test('missing schema version is compatible with version 1', () {
    final decoded = ConversationJsonDocument.fromJson({
      'conversations': [conversation('local_1').toJson()],
    });

    expect(decoded.schemaVersion, 1);
    expect(decoded.conversations.single.id, 'local_1');
  });

  test('future schema throws unsupportedVersion', () {
    expect(
      () => ConversationJsonDocument.fromJson({
        'schema_version': 99,
        'conversations': const [],
      }),
      throwsA(
        isA<ConversationStoreException>().having(
          (error) => error.type,
          'type',
          ConversationStoreFailureType.unsupportedVersion,
        ),
      ),
    );
  });

  test('top-level corrupt json throws invalidData safely', () {
    expect(
      () => ConversationJsonDocument.decode('{bad json with DIFY_API_KEY}'),
      throwsA(
        isA<ConversationStoreException>()
            .having(
              (error) => error.type,
              'type',
              ConversationStoreFailureType.invalidData,
            )
            .having(
              (error) => error.toString(),
              'safe string',
              isNot(contains('DIFY_API_KEY')),
            ),
      ),
    );
  });

  test('single corrupt record is skipped and valid records survive', () {
    final decoded = ConversationJsonDocument.fromJson({
      'schema_version': 1,
      'conversations': [
        conversation('local_1').toJson(),
        {'id': 'bad', 'messages': 'not a list'},
        conversation('local_2').toJson(),
      ],
    });

    expect(decoded.conversations.map((item) => item.id), [
      'local_1',
      'local_2',
    ]);
  });
}
