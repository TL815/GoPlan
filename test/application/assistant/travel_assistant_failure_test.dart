import 'package:flutter_test/flutter_test.dart';
import 'package:goplan/application/assistant/travel_assistant_failure.dart';

void main() {
  test('factory retryable defaults are stable', () {
    expect(TravelAssistantFailure.network().retryable, isTrue);
    expect(TravelAssistantFailure.timeout().retryable, isTrue);
    expect(TravelAssistantFailure.invalidResponse().retryable, isFalse);
    expect(TravelAssistantFailure.configuration().retryable, isFalse);
  });

  test('copyWith only changes specified fields', () {
    const failure = TravelAssistantFailure(
      type: TravelAssistantFailureType.serviceUnavailable,
      message: 'service down',
      code: 'SVC_DOWN',
      statusCode: 503,
      retryable: true,
    );

    final updated = failure.copyWith(message: 'try later', retryable: false);

    expect(updated.type, failure.type);
    expect(updated.code, failure.code);
    expect(updated.statusCode, failure.statusCode);
    expect(updated.message, 'try later');
    expect(updated.retryable, isFalse);
  });

  test('toString keeps structured fields', () {
    final failure = TravelAssistantFailure.network(
      message: 'network failed',
      code: 'NET',
      statusCode: 502,
    );

    final text = failure.toString();

    expect(text, contains('TravelAssistantFailure'));
    expect(text, contains('network'));
    expect(text, contains('NET'));
    expect(text, contains('502'));
    expect(text, contains('network failed'));
  });
}
