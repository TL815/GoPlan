import 'agent_session.dart';

class AgentSessionStore {
  final Map<String, AgentSession> _sessions = {};

  AgentSession? getById(String id) => _sessions[id];

  void put(AgentSession session) {
    _sessions[session.id] = session;
  }
}
