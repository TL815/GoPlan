class ToolResult {
  const ToolResult({
    required this.toolName,
    required this.status,
    this.payload = const {},
    this.errorMessage,
  });

  final String toolName;
  final ToolResultStatus status;
  final Map<String, Object?> payload;
  final String? errorMessage;
}

enum ToolResultStatus { skipped, success, failure }
