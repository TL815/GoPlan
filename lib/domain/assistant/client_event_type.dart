enum ClientEventType {
  chatMessage,
  dateSelected,
  dateRangeSelected,
  optionSelected,
  numberSubmitted,
  confirmationSubmitted,
  dateConflictResolved,
  replacePlace,
  updateDay,
  retry,
  unknown,
}

ClientEventType clientEventTypeFromJson(Object? value) {
  return switch (value) {
    'chat_message' => ClientEventType.chatMessage,
    'date_selected' => ClientEventType.dateSelected,
    'date_range_selected' => ClientEventType.dateRangeSelected,
    'option_selected' => ClientEventType.optionSelected,
    'number_submitted' => ClientEventType.numberSubmitted,
    'confirmation_submitted' => ClientEventType.confirmationSubmitted,
    'date_conflict_resolved' => ClientEventType.dateConflictResolved,
    'replace_place' => ClientEventType.replacePlace,
    'update_day' => ClientEventType.updateDay,
    'retry' => ClientEventType.retry,
    _ => ClientEventType.unknown,
  };
}

String clientEventTypeToJson(ClientEventType value) {
  return switch (value) {
    ClientEventType.chatMessage => 'chat_message',
    ClientEventType.dateSelected => 'date_selected',
    ClientEventType.dateRangeSelected => 'date_range_selected',
    ClientEventType.optionSelected => 'option_selected',
    ClientEventType.numberSubmitted => 'number_submitted',
    ClientEventType.confirmationSubmitted => 'confirmation_submitted',
    ClientEventType.dateConflictResolved => 'date_conflict_resolved',
    ClientEventType.replacePlace => 'replace_place',
    ClientEventType.updateDay => 'update_day',
    ClientEventType.retry => 'retry',
    ClientEventType.unknown => 'unknown',
  };
}
