import '../models/tool_result.dart';
import 'agent_tool.dart';

class PlaceDetailTool implements AgentTool {
  const PlaceDetailTool();

  @override
  String get name => 'place_detail';

  @override
  Future<ToolResult> run(Map<String, Object?> input) async {
    return ToolResult(toolName: name, status: ToolResultStatus.skipped);
  }
}
