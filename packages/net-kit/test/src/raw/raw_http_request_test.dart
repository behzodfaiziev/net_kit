import 'package:net_kit/net_kit.dart';
import 'package:test/test.dart';

void main() {
  group('RawHttpRequest', () {
    test('accepts an absolute https URI', () {
      final request = RawHttpRequest(
        uri: Uri.parse('https://example.com/upload/session?id=abc'),
        method: RawHttpMethod.put,
      );

      expect(request.uri.scheme, 'https');
      expect(request.uri.host, 'example.com');
      expect(request.uri.queryParameters['id'], 'abc');
    });

    test('accepts an absolute http URI', () {
      final request = RawHttpRequest(
        uri: Uri.parse('http://localhost:8080/upload'),
        method: RawHttpMethod.post,
      );

      expect(request.uri.scheme, 'http');
      expect(request.uri.host, 'localhost');
    });

    test('throws ArgumentError for a relative URI', () {
      expect(
        () => RawHttpRequest(
          uri: Uri.parse('/upload'),
          method: RawHttpMethod.put,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.name,
            'name',
            'uri',
          ),
        ),
      );
    });

    test('throws ArgumentError for a hostless URI', () {
      expect(
        () => RawHttpRequest(
          uri: Uri.parse('file:///tmp/data'),
          method: RawHttpMethod.get,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('stores caller-owned fields unchanged', () {
      final headers = {'Content-Type': 'application/octet-stream'};
      const stream = Stream<List<int>>.empty();
      final token = RawHttpCancellationToken();
      void onProgress(int sent, int total) {}

      const body = StreamRawHttpBody(
        stream: stream,
        contentLength: 4,
      );
      final request = RawHttpRequest(
        uri: Uri.parse('https://example.com/upload'),
        method: RawHttpMethod.put,
        headers: headers,
        body: body,
        connectTimeout: const Duration(seconds: 1),
        sendTimeout: const Duration(seconds: 2),
        receiveTimeout: const Duration(seconds: 3),
        cancellationToken: token,
        onSendProgress: onProgress,
      );

      expect(request.headers, same(headers));
      expect(request.body, same(body));
      expect(request.connectTimeout, const Duration(seconds: 1));
      expect(request.sendTimeout, const Duration(seconds: 2));
      expect(request.receiveTimeout, const Duration(seconds: 3));
      expect(request.cancellationToken, same(token));
      expect(request.onSendProgress, same(onProgress));
    });
  });
}
