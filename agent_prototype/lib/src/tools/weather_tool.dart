import '../models/tool_result.dart';
import 'agent_tool.dart';

class WeatherTool implements AgentTool {
  const WeatherTool();

  @override
  String get name => 'weather';

  @override
  Future<ToolResult> run(Map<String, Object?> input) async {
    return ToolResult(toolName: name, status: ToolResultStatus.skipped);
  }
}
