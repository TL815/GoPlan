class AgentConfig {
  const AgentConfig({
    this.model = 'mock-travel-agent',
    this.maxHistoryMessages = 12,
    this.timeout = const Duration(seconds: 45),
  });

  final String model;
  final int maxHistoryMessages;
  final Duration timeout;
}
