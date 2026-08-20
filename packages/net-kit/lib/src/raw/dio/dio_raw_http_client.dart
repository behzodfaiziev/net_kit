import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:meta/meta.dart';

import '../raw_http_body.dart';
import '../raw_http_cancellation_token.dart';
import '../raw_http_client.dart';
import '../raw_http_exception.dart';
import '../raw_http_method.dart';
import '../raw_http_request.dart';
import '../raw_http_response.dart';

/// [RawHttpClient] backed by an isolated Dio instance.
///
/// Always owns a private Dio client. Do not share the API-oriented
/// NetKitManager client with this implementation.
///
/// Application and protocol code should depend on [RawHttpClient].
/// Construct [DioRawHttpClient] only at the composition root.
final class DioRawHttpClient implements RawHttpClient {
  /// Creates an isolated raw HTTP client.
  DioRawHttpClient() : this._();

  /// Test-only constructor that injects a recording HTTP adapter.
  @visibleForTesting
  DioRawHttpClient.test({
    required HttpClientAdapter httpClientAdapter,
  }) : this._(httpClientAdapter: httpClientAdapter);

  DioRawHttpClient._({HttpClientAdapter? httpClientAdapter})
      : _dio = _createDio(httpClientAdapter);

  final Dio _dio;

  static Dio _createDio(HttpClientAdapter? httpClientAdapter) {
    final dio = Dio(
      BaseOptions(
        validateStatus: (_) => true,
        followRedirects: false,
        responseType: ResponseType.bytes,
      ),
    );
    dio.interceptors.removeImplyContentTypeInterceptor();
    if (httpClientAdapter != null) {
      dio.httpClientAdapter = httpClientAdapter;
    }
    return dio;
  }

  @override
  Future<RawHttpResponse> send(RawHttpRequest request) async {
    final headers = Map<String, String>.from(request.headers);
    final data = _mapBody(request.body, headers);

    CancelToken? cancelToken;
    final rawToken = request.cancellationToken;
    if (rawToken != null) {
      cancelToken = CancelToken();
      bindRawHttpCancellationToken(rawToken, cancelToken.cancel);
    }

    final options = Options(
      method: request.method.httpName,
      headers: headers,
      sendTimeout: request.sendTimeout,
      receiveTimeout: request.receiveTimeout,
      validateStatus: (_) => true,
      followRedirects: false,
      responseType: ResponseType.bytes,
    ).compose(
      _dio.options,
      request.uri.toString(),
      data: data,
      cancelToken: cancelToken,
      onSendProgress: request.onSendProgress,
    );
    if (request.connectTimeout != null) {
      options.connectTimeout = request.connectTimeout;
    }

    try {
      final response = await _dio.fetch<Object>(options);
      return RawHttpResponse(
        statusCode: response.statusCode ?? 0,
        headers: Map<String, List<String>>.from(response.headers.map),
        body: response.data,
      );
    } on DioException catch (error) {
      throw _toRawException(error, request.uri);
    }
  }

  /// Closes the owned HTTP client.
  void close({bool force = false}) {
    _dio.close(force: force);
  }

  Object? _mapBody(RawHttpBody? body, Map<String, String> headers) {
    switch (body) {
      case null:
        return null;
      case StreamRawHttpBody(:final stream, :final contentLength):
        _setHeader(headers, 'Content-Length', '$contentLength');
        return stream;
      case BytesRawHttpBody(:final bytes):
        _setHeader(headers, 'Content-Length', '${bytes.length}');
        return bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
      case StringRawHttpBody(:final value):
        return value;
    }
  }

  void _setHeader(Map<String, String> headers, String name, String value) {
    headers.removeWhere((key, _) => key.toLowerCase() == name.toLowerCase());
    headers[name] = value;
  }

  RawHttpException _toRawException(DioException error, Uri uri) {
    return RawHttpException(
      message: error.message ?? error.toString(),
      type: _failureType(error.type),
      cause: error,
      uri: uri,
    );
  }

  RawHttpFailureType _failureType(DioExceptionType type) {
    switch (type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return RawHttpFailureType.timeout;
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return RawHttpFailureType.connection;
      case DioExceptionType.cancel:
        return RawHttpFailureType.cancellation;
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        return RawHttpFailureType.unknown;
    }
  }
}
