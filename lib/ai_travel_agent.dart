import 'ai_travel_agent_stub.dart'
    if (dart.library.io) 'ai_travel_agent_io.dart' as impl;
import 'ai_travel_agent_models.dart';

export 'ai_travel_agent_models.dart';

AiTravelAgent createAiTravelAgent() => impl.createAiTravelAgent();
