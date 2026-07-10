import '../models/plan_draft.dart';

class PlanDraftService {
  const PlanDraftService();

  bool isCompleteEnoughForPreview(PlanDraft draft) {
    return draft.destination.isNotEmpty &&
        draft.durationDays > 0 &&
        draft.days.isNotEmpty;
  }
}
