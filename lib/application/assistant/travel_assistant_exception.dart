import 'travel_assistant_failure.dart';

/// Exception used when a gateway cannot complete a request or cannot parse the
/// provider response into GoPlan's standard protocol.
///
/// A parseable business error is not necessarily exceptional: adapters should
/// return an AssistantResponse with an error status for those cases. This
/// exception is reserved for transport, configuration, cancellation, timeout,
/// and invalid protocol boundaries.
class TravelAssistantException implements Exception {
  const TravelAssistantException(this.failure);

  final TravelAssistantFailure failure;

  @override
  String toString() {
    final buffer = StringBuffer('TravelAssistantException(')
      ..write('type: ${failure.type}, ');
    if (failure.code != null) buffer.write('code: ${failure.code}, ');
    if (failure.statusCode != null) {
      buffer.write('statusCode: ${failure.statusCode}, ');
    }
    buffer
      ..write('message: ${failure.message}')
      ..write(')');
    return buffer.toString();
  }
}
