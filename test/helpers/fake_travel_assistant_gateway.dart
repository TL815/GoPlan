import 'package:goplan/application/assistant/travel_assistant_exception.dart';
import 'package:goplan/application/assistant/travel_assistant_gateway.dart';
import 'package:goplan/domain/assistant/assistant_request.dart';
import 'package:goplan/domain/assistant/assistant_response.dart';

class FakeTravelAssistantGateway implements TravelAssistantGateway {
  FakeTravelAssistantGateway({
    this.response,
    this.exception,
    List<AssistantResponse>? responseQueue,
    List<TravelAssistantException>? exceptionQueue,
    this.handler,
  }) : responseQueue = List<AssistantResponse>.from(responseQueue ?? const []),
       exceptionQueue = List<TravelAssistantException>.from(
         exceptionQueue ?? const [],
       );

  final AssistantResponse? response;
  final TravelAssistantException? exception;
  final List<AssistantResponse> responseQueue;
  final List<TravelAssistantException> exceptionQueue;
  final Future<AssistantResponse> Function(AssistantRequest request)? handler;

  AssistantRequest? lastRequest;
  final List<AssistantRequest> requests = [];
  int callCount = 0;

  @override
  Future<AssistantResponse> send(AssistantRequest request) async {
    callCount += 1;
    lastRequest = request;
    requests.add(request);
    final customHandler = handler;
    if (customHandler != null) return customHandler(request);
    if (exceptionQueue.isNotEmpty) throw exceptionQueue.removeAt(0);
    if (responseQueue.isNotEmpty) return responseQueue.removeAt(0);
    final failure = exception;
    if (failure != null) throw failure;
    final result = response;
    if (result == null) {
      throw StateError('FakeTravelAssistantGateway requires a response.');
    }
    return result;
  }
}
