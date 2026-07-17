class AiChatRuntimeConfig {
  const AiChatRuntimeConfig({
    required this.userId,
    required this.tripId,
    required this.timezone,
  });

  factory AiChatRuntimeConfig.fromEnvironment() {
    return AiChatRuntimeConfig(
      userId: _valueOrDefault(
        const String.fromEnvironment('DIFY_USER_ID'),
        defaultUserId,
      ),
      tripId: _valueOrDefault(
        const String.fromEnvironment('DIFY_TRIP_ID'),
        defaultTripId,
      ),
      timezone: _valueOrDefault(
        const String.fromEnvironment('GOPLAN_TIMEZONE'),
        defaultTimezone,
      ),
    );
  }

  static const defaultUserId = 'goplan-local-user';
  static const defaultTripId = 'goplan-local-trip';
  static const defaultTimezone = 'Asia/Shanghai';

  final String userId;
  final String tripId;
  final String timezone;

  static String _valueOrDefault(String value, String fallback) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }
}
