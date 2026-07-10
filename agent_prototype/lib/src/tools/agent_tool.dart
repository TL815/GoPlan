import '../models/tool_result.dart';

abstract interface class AgentTool {
  String get name;

  Future<ToolResult> run(Map<String, Object?> input);
}
