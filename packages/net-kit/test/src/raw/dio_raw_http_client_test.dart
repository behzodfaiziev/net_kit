import 'dart:async';
import 'dart:typed_data';

import 'package:net_kit/net_kit.dart';
import 'package:test/test.dart';

class _RecordingAdapter implements HttpClientAdapter {
  RequestOptions? lastOptions;
  Stream<Uint8List>? lastRequestStream;
  Object? lastData;
  int statusCode = 200;
  Map<String, List<String>> responseHeaders = {};
  DioExceptionType? throwType;
  Completer<void>? started;
  bool waitForCancel = false;
  bool drainStream = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    lastRequestStream = requestStream;
    lastData = options.data;
    started?.complete();

    if (waitForCancel && cancelFuture != null) {
      await cancelFuture;
    }

    if (drainStream && requestStream != null) {
      await requestStream.drain<void>();
    }

    if (throwType != null) {
      throw DioException(
        requestOptions: options,
        type: throwType!,
        message: throwType!.name,
      );
    }

    return ResponseBody.fromBytes(
      <int>[],
      statusCode,
      headers: responseHeaders,
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _RecordingAdapter adapter;
  late DioRawHttpClient client;

  RawHttpRequest request({
    Uri? uri,
    RawHttpMethod method = RawHttpMethod.put,
    Map<String, String> headers = const {},
    RawHttpBody? body,
    RawHttpCancellationToken? cancellationToken,
    void Function(int sent, int total)? onSendProgress,
  }) {
    return RawHttpRequest(
      uri: uri ?? Uri.parse('https://example.com/upload/session?id=abc'),
      method: method,
      headers: headers,
      body: body,
      cancellationToken: cancellationToken,
      onSendProgress: onSendProgress,
    );
  }

  setUp(() {
    adapter = _RecordingAdapter();
    client = DioRawHttpClient.test(httpClientAdapter: adapter);
  });

  tearDown(() {
    client.close();
  });

  group('DioRawHttpClient', () {
    test('sends an absolute URL unchanged', () async {
      final uri = Uri.parse(
        'https://example.com/upload/session?id=abc',
      );

      await client.send(request(uri: uri));

      expect(adapter.lastOptions!.uri.toString(), uri.toString());
      expect(adapter.lastOptions!.path, uri.toString());
    });

    test('does not add Authorization unless the caller supplies it', () async {
      await client.send(request());

      expect(
        adapter.lastOptions!.headers['Authorization'],
        isNull,
      );
      expect(
        adapter.lastOptions!.headers['authorization'],
        isNull,
      );
    });

    test(
      'does not imply Content-Type on a streaming PUT',
      () async {
        final stream = Stream<List<int>>.fromIterable([
          [1, 2, 3],
        ]);

        await client.send(
          request(
            body: StreamRawHttpBody(
              stream: stream,
              contentLength: 3,
            ),
          ),
        );

        expect(
          adapter.lastOptions!.headers['content-type'],
          isNull,
        );
        expect(adapter.lastOptions!.contentType, isNull);
      },
    );

    test('forwards a Stream body without flattening it', () async {
      final stream = Stream<List<int>>.fromIterable([
        [1],
        [2, 3],
      ]);

      await client.send(
        request(
          body: StreamRawHttpBody(
            stream: stream,
            contentLength: 3,
          ),
        ),
      );

      expect(adapter.lastData, isA<Stream<List<int>>>());
      expect(adapter.lastData, same(stream));
      expect(adapter.lastRequestStream, isNotNull);
    });

    test('forwards Content-Length from StreamRawHttpBody', () async {
      await client.send(
        request(
          body: const StreamRawHttpBody(
            stream: Stream.empty(),
            contentLength: 8388608,
          ),
        ),
      );

      expect(
        adapter.lastOptions!.headers['content-length']?.toString(),
        '8388608',
      );
    });

    test('preserves caller headers and does not mutate them', () async {
      final headers = {
        'Content-Type': 'application/octet-stream',
        'Content-Range': 'bytes 0-1023/2048',
      };

      await client.send(
        request(
          headers: headers,
          body: const StreamRawHttpBody(
            stream: Stream.empty(),
            contentLength: 1024,
          ),
        ),
      );

      expect(
        adapter.lastOptions!.headers['content-type'],
        'application/octet-stream',
      );
      expect(
        adapter.lastOptions!.headers['content-range'],
        'bytes 0-1023/2048',
      );
      expect(headers.containsKey('Content-Length'), isFalse);
      expect(headers.length, 2);
    });

    test('returns 308 with Range as RawHttpResponse', () async {
      adapter
        ..statusCode = 308
        ..responseHeaders = {
          'range': ['bytes=0-8388607'],
        };

      final response = await client.send(request());

      expect(response, isA<RawHttpResponse>());
      expect(response.statusCode, 308);
      expect(response.header('Range'), 'bytes=0-8388607');
      expect(response, isNot(isA<ApiException>()));
    });

    test('returns 404 without interpreting it', () async {
      adapter.statusCode = 404;

      final response = await client.send(request());

      expect(response.statusCode, 404);
    });

    test('returns 410 without interpreting it', () async {
      adapter.statusCode = 410;

      final response = await client.send(request());

      expect(response.statusCode, 410);
    });

    test('returns 500 as RawHttpResponse', () async {
      adapter.statusCode = 500;

      final response = await client.send(request());

      expect(response.statusCode, 500);
      expect(response, isA<RawHttpResponse>());
    });

    test('maps connection timeout to RawHttpException', () async {
      adapter.throwType = DioExceptionType.connectionTimeout;

      await expectLater(
        client.send(request()),
        throwsA(
          isA<RawHttpException>().having(
            (error) => error.type,
            'type',
            RawHttpFailureType.timeout,
          ),
        ),
      );
    });

    test('maps connection error to RawHttpException', () async {
      adapter.throwType = DioExceptionType.connectionError;

      await expectLater(
        client.send(request()),
        throwsA(
          isA<RawHttpException>().having(
            (error) => error.type,
            'type',
            RawHttpFailureType.connection,
          ),
        ),
      );
    });

    test('does not inherit NetKitManager access tokens', () async {
      final manager = NetKitManager(
        baseUrl: 'https://api.example.com',
      )..setAccessToken('secret-token');

      try {
        await client.send(request());

        expect(
          adapter.lastOptions!.headers['Authorization'],
          isNull,
        );
        expect(
          manager.baseOptions.headers['Authorization'],
          contains('secret-token'),
        );
      } finally {
        manager.dispose();
      }
    });

    test('uses the injected HttpClientAdapter', () async {
      adapter.statusCode = 201;

      final response = await client.send(request());

      expect(adapter.lastOptions, isNotNull);
      expect(response.statusCode, 201);
    });

    test('owned Dio has implied-content-type disabled', () async {
      await client.send(
        request(
          method: RawHttpMethod.post,
          body: const StringRawHttpBody('{"a":1}'),
        ),
      );

      expect(adapter.lastOptions!.contentType, isNull);
      expect(
        adapter.lastOptions!.headers['content-type'],
        isNull,
      );
    });

    test('forwards onSendProgress without buffering the stream', () async {
      final progress = <(int, int)>[];
      adapter.drainStream = true;

      await client.send(
        request(
          body: StreamRawHttpBody(
            stream: Stream<List<int>>.fromIterable([
              [1, 2, 3, 4],
            ]),
            contentLength: 4,
          ),
          onSendProgress: (sent, total) {
            progress.add((sent, total));
          },
        ),
      );

      expect(adapter.lastData, isA<Stream<List<int>>>());
      expect(progress, isNotEmpty);
      expect(progress.last.$2, 4);
    });

    test('cancel surfaces as RawHttpException cancellation', () async {
      adapter
        ..started = Completer<void>()
        ..waitForCancel = true;
      final token = RawHttpCancellationToken();

      final future = client.send(
        request(cancellationToken: token),
      );
      await adapter.started!.future;
      token.cancel();

      await expectLater(
        future,
        throwsA(
          isA<RawHttpException>().having(
            (error) => error.type,
            'type',
            RawHttpFailureType.cancellation,
          ),
        ),
      );
    });

    test('forwards BytesRawHttpBody without JSON content type', () async {
      await client.send(
        request(body: const BytesRawHttpBody([9, 8, 7])),
      );

      expect(adapter.lastData, equals([9, 8, 7]));
      expect(adapter.lastOptions!.contentType, isNull);
      expect(
        adapter.lastOptions!.headers['content-length']?.toString(),
        '3',
      );
    });

    test('forwards StringRawHttpBody without JSON content type', () async {
      await client.send(
        request(body: const StringRawHttpBody('plain')),
      );

      expect(adapter.lastData, 'plain');
      expect(adapter.lastOptions!.contentType, isNull);
    });

    test('HEAD with a null body sends no request stream', () async {
      await client.send(
        request(method: RawHttpMethod.head),
      );

      expect(adapter.lastData, isNull);
      expect(adapter.lastRequestStream, isNull);
    });

    test('GET with a null body sends no request stream', () async {
      await client.send(
        request(method: RawHttpMethod.get),
      );

      expect(adapter.lastData, isNull);
      expect(adapter.lastRequestStream, isNull);
    });
  });
}
