abstract interface class UserPreferenceRepository {
  Future<Map<String, Object?>> loadPreferences();
}
