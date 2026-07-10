import '../agent_exception.dart';
import 'llm_adapter.dart';

class DeepSeekAdapter implements LlmAdapter {
  const DeepSeekAdapter();

  @override
  Future<String> complete(AgentPromptRequest request) {
    throw const AgentException(
      'DeepSeekAdapter is not implemented in the first scaffold step.',
    );
  }
}
