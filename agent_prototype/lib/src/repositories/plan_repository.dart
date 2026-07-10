import '../models/plan_draft.dart';

abstract interface class PlanRepository {
  Future<void> saveDraft(PlanDraft draft);
}
