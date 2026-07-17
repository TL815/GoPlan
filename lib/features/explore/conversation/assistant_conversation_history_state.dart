// ignore_for_file: prefer_initializing_formals

import 'package:goplan/application/assistant/conversation/assistant_conversation_summary.dart';

enum AssistantConversationHistoryPhase { loading, ready, failure }

class AssistantConversationHistoryState {
  const AssistantConversationHistoryState({
    required this.phase,
    this.summaries = const [],
  });

  const AssistantConversationHistoryState.loading()
    : phase = AssistantConversationHistoryPhase.loading,
      summaries = const [];

  const AssistantConversationHistoryState.ready(
    List<AssistantConversationSummary> summaries,
  ) : phase = AssistantConversationHistoryPhase.ready,
      summaries = summaries;

  const AssistantConversationHistoryState.failure()
    : phase = AssistantConversationHistoryPhase.failure,
      summaries = const [];

  final AssistantConversationHistoryPhase phase;
  final List<AssistantConversationSummary> summaries;
}
