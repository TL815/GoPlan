enum UiActionType {
  requestStartDate,
  requestDateRange,
  selectOption,
  inputNumber,
  confirm,
  confirmDateConflict,
  showItinerary,
  showMap,
  showBudget,
  none,
  unknown,
}

UiActionType uiActionTypeFromJson(Object? value) {
  return switch (value) {
    'request_start_date' => UiActionType.requestStartDate,
    'request_date_range' => UiActionType.requestDateRange,
    'select_option' => UiActionType.selectOption,
    'input_number' => UiActionType.inputNumber,
    'confirm' => UiActionType.confirm,
    'confirm_date_conflict' => UiActionType.confirmDateConflict,
    'show_itinerary' => UiActionType.showItinerary,
    'show_map' => UiActionType.showMap,
    'show_budget' => UiActionType.showBudget,
    'none' => UiActionType.none,
    _ => UiActionType.unknown,
  };
}

String uiActionTypeToJson(UiActionType value) {
  return switch (value) {
    UiActionType.requestStartDate => 'request_start_date',
    UiActionType.requestDateRange => 'request_date_range',
    UiActionType.selectOption => 'select_option',
    UiActionType.inputNumber => 'input_number',
    UiActionType.confirm => 'confirm',
    UiActionType.confirmDateConflict => 'confirm_date_conflict',
    UiActionType.showItinerary => 'show_itinerary',
    UiActionType.showMap => 'show_map',
    UiActionType.showBudget => 'show_budget',
    UiActionType.none => 'none',
    UiActionType.unknown => 'unknown',
  };
}
