import 'package:http/http.dart' as http;

class HttpLogger extends http.BaseClient {
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    print("===== HTTP REQUEST =====");
    print("${request.method} ${request.url}");
    print("Headers: ${request.headers}");

    if (request is http.Request) {
      print("Body: ${request.body}");
    }

    final response = await _inner.send(request);
    final bytes = await response.stream.toBytes();
    final body = String.fromCharCodes(bytes);

    print("===== HTTP RESPONSE =====");
    print("Status: ${response.statusCode}");
    print("Headers: ${response.headers}");
    print("BODY:\n$body");

    return http.StreamedResponse(
      Stream.fromIterable([bytes]),
      response.statusCode,
      headers: response.headers,
      reasonPhrase: response.reasonPhrase,
      request: response.request,
    );
  }
}
