import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:goplan/application/assistant/conversation/assistant_conversation_summary.dart';
import 'package:goplan/application/assistant/travel_assistant_controller.dart';
import 'package:goplan/application/assistant/travel_assistant_phase.dart';
import 'package:goplan/application/assistant/travel_assistant_state.dart';
import 'package:goplan/application/assistant/ui_action/ui_action_dispatch_result.dart';
import 'package:goplan/application/assistant/ui_action/ui_action_dispatch_status.dart';
import 'package:goplan/domain/assistant/ui_action_type.dart';
import 'package:goplan/features/ai_chat/ai_chat_message_adapter.dart';
import 'package:goplan/features/ai_chat/ai_chat_runtime.dart';
import 'package:goplan/features/ai_chat/ai_chat_runtime_config.dart';
import 'package:goplan/features/ai_chat/conversation/ai_chat_launch_request.dart';
import 'package:goplan/features/ai_chat/conversation/ai_chat_session_bootstrap.dart';
import 'package:goplan/features/ai_chat/conversation/production_conversation_store_factory.dart';
import 'package:goplan/features/explore/conversation/assistant_conversation_history_controller.dart';
import 'package:goplan/features/explore/conversation/assistant_conversation_history_state.dart';
import 'package:goplan/features/ai_chat/ui_action/ui_action_presentation_coordinator.dart';
import 'package:goplan/features/ai_chat/ui_action/ui_action_response_listener.dart';
import 'package:goplan/features/ai_chat/widgets/assistant_failure_card.dart';
import 'package:goplan/features/ai_chat/widgets/assistant_loading_indicator.dart';
import 'package:goplan/features/plan/itinerary/itinerary_detail_page.dart';
import 'package:goplan/features/plan/itinerary/itinerary_overview_card.dart';

import 'services/weather_service.dart';
import 'services/qweather_service.dart';
import 'widgets/weather_sheet.dart';
import 'amap_photo_service_stub.dart'
    if (dart.library.io) 'amap_photo_service_io.dart';
import 'amap_web_view_stub.dart'
    if (dart.library.html) 'amap_web_view_web.dart';

part 'app/app.dart';
part 'features/loading/loading_page.dart';
part 'features/home/home_page.dart';
part 'features/ai_chat/ai_chat_page.dart';
part 'features/plan/plan_detail.dart';
part 'features/explore/explore_page.dart';
part 'features/navigation/bottom_dock.dart';
part 'features/shared/demo_data.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GoPlanApp());
}
