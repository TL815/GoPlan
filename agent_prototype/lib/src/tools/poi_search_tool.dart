import '../models/tool_result.dart';
import 'agent_tool.dart';

class PoiSearchTool implements AgentTool {
  const PoiSearchTool();

  @override
  String get name => 'poi_search';

  @override
  Future<ToolResult> run(Map<String, Object?> input) async {
    return ToolResult(toolName: name, status: ToolResultStatus.skipped);
  }
}
