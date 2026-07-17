import '../../domain/assistant/assistant_request.dart';
import '../../domain/assistant/assistant_response.dart';

/// Boundary between the GoPlan app/application layer and travel assistant
/// providers such as Dify, a business backend, or a custom agent service.
///
/// Implementations are responsible for mapping transport requests and raw
/// provider responses into GoPlan's standard [AssistantRequest] and
/// [AssistantResponse] models. UI and controllers must not depend on provider
/// specific JSON or SDK objects.
abstract interface class TravelAssistantGateway {
  /// Sends one standard assistant request and returns a standard response.
  ///
  /// `conversationId`, `tripId`, and `userId` are explicit data on
  /// [AssistantRequest]. Implementations must not hide them in global state.
  /// Transport, configuration, and response parsing failures should throw a
  /// `TravelAssistantException`; parseable business errors should be returned
  /// as an [AssistantResponse] with an error status.
  Future<AssistantResponse> send(AssistantRequest request);
}
