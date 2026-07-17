// ignore_for_file: prefer_initializing_formals

import 'package:flutter/widgets.dart';
import 'package:goplan/application/assistant/conversation/conversation_store.dart';
import 'package:goplan/application/assistant/conversation/travel_assistant_session_mapper.dart';
import 'package:goplan/application/assistant/travel_assistant_controller.dart';
import 'package:goplan/application/assistant/travel_assistant_gateway.dart';
import 'package:goplan/application/assistant/ui_action/ui_action_dispatcher.dart';
import 'package:goplan/data/assistant/dify/dify_gateway_config.dart';
import 'package:goplan/data/assistant/dify/dify_travel_assistant_gateway.dart';
import 'package:goplan/features/ai_chat/ai_chat_runtime_config.dart';
import 'package:goplan/features/ai_chat/conversation/ai_chat_launch_request.dart';
import 'package:goplan/features/ai_chat/conversation/ai_chat_persistence_coordinator.dart';
import 'package:goplan/features/ai_chat/conversation/ai_chat_session_bootstrap.dart';
import 'package:goplan/features/ai_chat/conversation/local_conversation_id_generator.dart';
import 'package:goplan/features/ai_chat/conversation/production_conversation_store_factory.dart';
import 'package:goplan/features/ai_chat/ui_action/flutter_ui_action_interaction_port.dart';
import 'package:goplan/features/ai_chat/ui_action/ui_action_presentation_coordinator.dart';
import 'package:http/http.dart' as http;

class AiChatRuntime {
  AiChatRuntime({
    required this.httpClient,
    required this.controller,
    required this.dispatcher,
    required this.coordinator,
    this.persistenceCoordinator,
    this.localConversationId,
    this.createdAt,
    bool ownsHttpClient = true,
    bool ownsController = true,
  }) : _ownsHttpClient = ownsHttpClient,
       _ownsController = ownsController;

  static Future<AiChatRuntime> createProduction({
    required BuildContext Function() contextProvider,
    required bool Function() isMounted,
    AiChatLaunchRequest launchRequest =
        const AiChatLaunchRequest.resumeLatestForTrip(),
    ConversationStore? conversationStore,
    LocalConversationIdGenerator? idGenerator,
    DateTime Function()? now,
    void Function()? onPersistenceError,
  }) async {
    final client = http.Client();
    final config = AiChatRuntimeConfig.fromEnvironment();
    final store = conversationStore ?? createProductionConversationStore();
    final clock = now ?? DateTime.now;
    final bootstrap = AiChatSessionBootstrap(
      store: store,
      idGenerator:
          idGenerator ?? SecureLocalConversationIdGenerator(now: clock),
      now: clock,
    );
    final bootstrapResult = await bootstrap.load(
      config: config,
      request: launchRequest,
    );
    final gateway = DifyTravelAssistantGateway(
      client: client,
      config: DifyGatewayConfig.fromEnvironment(),
    );
    return AiChatRuntime.withGateway(
      gateway: gateway,
      httpClient: client,
      config: config,
      contextProvider: contextProvider,
      isMounted: isMounted,
      ownsHttpClient: true,
      ownsController: true,
      conversationStore: store,
      bootstrapResult: bootstrapResult,
      now: clock,
      onPersistenceError: onPersistenceError,
    );
  }

  factory AiChatRuntime.withGateway({
    required TravelAssistantGateway gateway,
    required http.Client httpClient,
    required AiChatRuntimeConfig config,
    required BuildContext Function() contextProvider,
    required bool Function() isMounted,
    bool ownsHttpClient = false,
    bool ownsController = true,
    ConversationStore? conversationStore,
    AiChatBootstrapResult? bootstrapResult,
    DateTime Function()? now,
    void Function()? onPersistenceError,
  }) {
    final mapper = const TravelAssistantSessionMapper();
    final restoreData = bootstrapResult?.snapshot == null
        ? null
        : mapper.restore(bootstrapResult!.snapshot!);
    final controller = TravelAssistantController(
      gateway: gateway,
      userId: restoreData?.userId ?? config.userId,
      tripId: restoreData?.tripId ?? config.tripId,
      timezone: config.timezone,
      initialConversationId: restoreData?.conversationId,
      initialMessages: restoreData?.messages ?? const [],
      initialTripState: restoreData?.tripState,
      initialItinerary: restoreData?.itinerary,
      initialWarnings: restoreData?.warnings ?? const [],
      initialAssistantStatus: restoreData?.assistantStatus,
      now: now,
    );
    final interactionPort = FlutterUiActionInteractionPort(
      contextProvider: contextProvider,
      isMounted: isMounted,
      today: now,
    );
    final dispatcher = UiActionDispatcher(
      controller: controller,
      interactionPort: interactionPort,
      now: now,
    );
    final coordinator = UiActionPresentationCoordinator(dispatcher: dispatcher);
    AiChatPersistenceCoordinator? persistenceCoordinator;
    if (conversationStore != null && bootstrapResult != null) {
      persistenceCoordinator = AiChatPersistenceCoordinator(
        controller: controller,
        store: conversationStore,
        mapper: mapper,
        localConversationId: bootstrapResult.localConversationId,
        createdAt: bootstrapResult.createdAt,
        now: now,
        onError: (_) => onPersistenceError?.call(),
      )..start();
    }
    return AiChatRuntime(
      httpClient: httpClient,
      controller: controller,
      dispatcher: dispatcher,
      coordinator: coordinator,
      persistenceCoordinator: persistenceCoordinator,
      localConversationId: bootstrapResult?.localConversationId,
      createdAt: bootstrapResult?.createdAt,
      ownsHttpClient: ownsHttpClient,
      ownsController: ownsController,
    );
  }

  final http.Client httpClient;
  final TravelAssistantController controller;
  final UiActionDispatcher dispatcher;
  final UiActionPresentationCoordinator coordinator;
  final AiChatPersistenceCoordinator? persistenceCoordinator;
  final String? localConversationId;
  final DateTime? createdAt;
  final bool _ownsHttpClient;
  final bool _ownsController;
  bool _disposed = false;

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final persistence = persistenceCoordinator;
    if (persistence != null) {
      await persistence.dispose();
    }
    if (_ownsController) {
      controller.dispose();
    }
    if (_ownsHttpClient) {
      httpClient.close();
    }
  }
}
