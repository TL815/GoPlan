enum AssistantStatus { needInput, success, draft, error, unknown }

AssistantStatus assistantStatusFromJson(Object? value) {
  return switch (value) {
    'need_input' => AssistantStatus.needInput,
    'success' => AssistantStatus.success,
    'draft' => AssistantStatus.draft,
    'error' => AssistantStatus.error,
    _ => AssistantStatus.unknown,
  };
}

String assistantStatusToJson(AssistantStatus value) {
  return switch (value) {
    AssistantStatus.needInput => 'need_input',
    AssistantStatus.success => 'success',
    AssistantStatus.draft => 'draft',
    AssistantStatus.error => 'error',
    AssistantStatus.unknown => 'unknown',
  };
}
