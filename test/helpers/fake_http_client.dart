import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class FakeHttpClient extends http.BaseClient {
  FakeHttpClient(this._handlers);

  final List<FutureOr<http.StreamedResponse> Function(http.BaseRequest request)>
  _handlers;

  final requests = <http.Request>[];

  int get requestCount => requests.length;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request is http.Request) {
      requests.add(request);
    }
    if (_handlers.isEmpty) {
      throw StateError('No fake HTTP handler configured.');
    }
    final handler = _handlers.removeAt(0);
    return handler(request);
  }

  static FutureOr<http.StreamedResponse> Function(http.BaseRequest request)
  response(
    int statusCode,
    String body, {
    Map<String, String> headers = const {'content-type': 'application/json'},
  }) {
    return (_) => http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      statusCode,
      headers: headers,
    );
  }

  static FutureOr<http.StreamedResponse> Function(http.BaseRequest request)
  exception(Object error) {
    return (_) => throw error;
  }
}
