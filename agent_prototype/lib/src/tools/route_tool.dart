import '../models/tool_result.dart';
import 'agent_tool.dart';

class RouteTool implements AgentTool {
  const RouteTool();

  @override
  String get name => 'route';

  @override
  Future<ToolResult> run(Map<String, Object?> input) async {
    return ToolResult(toolName: name, status: ToolResultStatus.skipped);
  }
}
