import 'package:flutter_test/flutter_test.dart';
import 'package:goplan/application/assistant/conversation/assistant_conversation_snapshot.dart';
import 'package:goplan/application/assistant/conversation/assistant_message_snapshot.dart';
import 'package:goplan/application/assistant/conversation/conversation_store_exception.dart';
import 'package:goplan/application/assistant/travel_assistant_message_role.dart';
import 'package:goplan/data/assistant/conversation/conversation_json_document.dart';
import 'package:goplan/data/assistant/conversation/shared_preferences_conversation_store.dart';

import '../../../helpers/fake_string_store.dart';

void main() {
  final t1 = DateTime(2026, 7, 16, 9);
  final t2 = DateTime(2026, 7, 16, 10);
  final t3 = DateTime(2026, 7, 16, 11);

  AssistantConversationSnapshot conversation({
    required String id,
    String userId = 'user_1',
    String tripId = 'trip_1',
    DateTime? createdAt,
    DateTime? updatedAt,
    String title = 'Trip',
  }) {
    return AssistantConversationSnapshot(
      id: id,
      userId: userId,
      tripId: tripId,
      title: title,
      createdAt: createdAt ?? t1,
      updatedAt: updatedAt ?? t1,
      messages: [
        AssistantMessageSnapshot(
          id: 'message_1',
          role: TravelAssistantMessageRole.user,
          text: 'hello',
          createdAt: createdAt ?? t1,
        ),
      ],
    );
  }

  SharedPreferencesConversationStore store(FakeStringStore strings) {
    return SharedPreferencesConversationStore(stringStore: strings);
  }

  test('save new conversation and getById', () async {
    final strings = FakeStringStore();
    final s = store(strings);

    await s.save(conversation(id: 'local_1'));

    expect((await s.getById('local_1'))!.id, 'local_1');
    expect(
      strings.values,
      contains(SharedPreferencesConversationStore.defaultStorageKey),
    );
  });

  test(
    'save same id updates record without duplicating and keeps createdAt',
    () async {
      final strings = FakeStringStore();
      final s = store(strings);

      await s.save(conversation(id: 'local_1', createdAt: t1, updatedAt: t1));
      await s.save(
        conversation(
          id: 'local_1',
          createdAt: t3,
          updatedAt: t2,
          title: 'Updated',
        ),
      );

      final document = ConversationJsonDocument.decode(
        strings.values[SharedPreferencesConversationStore.defaultStorageKey]!,
      );

      expect(document.conversations, hasLength(1));
      expect(document.conversations.single.title, 'Updated');
      expect(document.conversations.single.createdAt, t1);
      expect(document.conversations.single.updatedAt, t2);
    },
  );

  test('listForUser is exact and sorted by updatedAt descending', () async {
    final strings = FakeStringStore();
    final s = store(strings);

    await s.save(conversation(id: 'old', updatedAt: t1));
    await s.save(conversation(id: 'other', userId: 'user_2', updatedAt: t3));
    await s.save(conversation(id: 'new', updatedAt: t2));

    final summaries = await s.listForUser('user_1');

    expect(summaries.map((item) => item.id), ['new', 'old']);
    expect(() => summaries.add(summaries.first), throwsUnsupportedError);
  });

  test('getLatestForTrip matches both user and trip', () async {
    final strings = FakeStringStore();
    final s = store(strings);

    await s.save(conversation(id: 'a', tripId: 'trip_1', updatedAt: t1));
    await s.save(conversation(id: 'b', tripId: 'trip_2', updatedAt: t3));
    await s.save(conversation(id: 'c', tripId: 'trip_1', updatedAt: t2));

    final latest = await s.getLatestForTrip(userId: 'user_1', tripId: 'trip_1');

    expect(latest!.id, 'c');
    expect(
      await s.getLatestForTrip(userId: 'missing', tripId: 'trip_1'),
      isNull,
    );
  });

  test('delete and clearForUser are safe and scoped', () async {
    final strings = FakeStringStore();
    final s = store(strings);

    await s.save(conversation(id: 'a'));
    await s.save(conversation(id: 'b', userId: 'user_2'));
    await s.delete('missing');
    await s.delete('a');

    expect(await s.getById('a'), isNull);
    expect(await s.getById('b'), isNotNull);

    await s.clearForUser('user_2');

    expect(await s.getById('b'), isNull);
  });

  test('concurrent saves do not overwrite each other', () async {
    final strings = FakeStringStore();
    final s = store(strings);

    await Future.wait([
      s.save(conversation(id: 'a')),
      s.save(conversation(id: 'b')),
    ]);

    expect(await s.getById('a'), isNotNull);
    expect(await s.getById('b'), isNotNull);
  });

  test('read and write failures map to safe store exceptions', () async {
    final readStore = FakeStringStore(
      readError: StateError('read DIFY_API_KEY'),
    );
    await expectLater(
      store(readStore).getById('a'),
      throwsA(
        isA<ConversationStoreException>()
            .having(
              (error) => error.type,
              'type',
              ConversationStoreFailureType.readFailed,
            )
            .having(
              (error) => error.toString(),
              'safe string',
              isNot(contains('DIFY_API_KEY')),
            ),
      ),
    );

    final writeStore = FakeStringStore(
      writeError: StateError('write conv_secret'),
    );
    await expectLater(
      store(writeStore).save(conversation(id: 'a')),
      throwsA(
        isA<ConversationStoreException>()
            .having(
              (error) => error.type,
              'type',
              ConversationStoreFailureType.writeFailed,
            )
            .having(
              (error) => error.toString(),
              'safe string',
              isNot(contains('conv_secret')),
            ),
      ),
    );
  });
}
