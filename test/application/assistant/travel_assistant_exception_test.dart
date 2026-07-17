import 'package:flutter_test/flutter_test.dart';
import 'package:goplan/application/assistant/travel_assistant_exception.dart';
import 'package:goplan/application/assistant/travel_assistant_failure.dart';

void main() {
  test('toString includes type and message', () {
    final exception = TravelAssistantException(
      TravelAssistantFailure.invalidResponse(
        message: 'cannot parse assistant response',
        code: 'BAD_JSON',
        statusCode: 200,
      ),
    );

    final text = exception.toString();

    expect(text, contains('invalidResponse'));
    expect(text, contains('cannot parse assistant response'));
    expect(text, contains('BAD_JSON'));
    expect(text, contains('200'));
  });

  test('toString does not include Authorization or API key content', () {
    final exception = TravelAssistantException(
      TravelAssistantFailure.configuration(
        message: 'Configuration failed',
        cause: {
          'Authorization': 'Bearer secret-token',
          'api_key': 'secret-key',
        },
      ),
    );

    final text = exception.toString();

    expect(text, isNot(contains('Authorization')));
    expect(text, isNot(contains('Bearer secret-token')));
    expect(text, isNot(contains('api_key')));
    expect(text, isNot(contains('secret-key')));
  });
}
