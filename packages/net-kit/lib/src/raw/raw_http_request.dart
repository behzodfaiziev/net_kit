import 'raw_http_body.dart';
import 'raw_http_cancellation_token.dart';
import 'raw_http_method.dart';

/// Upload progress for a raw HTTP request.
///
/// `sent` is the number of bytes written so far. `total` is the declared
/// content length when known.
typedef RawHttpProgressCallback = void Function(int sent, int total);

/// A single raw HTTP request.
///
/// The caller owns headers. The transport does not inject authorization,
/// JSON content type, or API-specific headers.
final class RawHttpRequest {
  /// Creates a raw HTTP request.
  ///
  /// [uri] must be absolute (`hasScheme` and a non-empty host).
  RawHttpRequest({
    required this.uri,
    required this.method,
    this.headers = const {},
    this.body,
    this.connectTimeout,
    this.sendTimeout,
    this.receiveTimeout,
    this.cancellationToken,
    this.onSendProgress,
  }) {
    if (!uri.hasScheme || uri.host.isEmpty) {
      throw ArgumentError.value(uri, 'uri', 'Must be an absolute URI');
    }
  }

  /// Absolute request URI, including scheme, host, path, and query.
  final Uri uri;

  /// HTTP method.
  final RawHttpMethod method;

  /// Caller-owned request headers.
  final Map<String, String> headers;

  /// Optional request body.
  final RawHttpBody? body;

  /// Timeout for establishing the connection.
  final Duration? connectTimeout;

  /// Timeout for sending the request body.
  final Duration? sendTimeout;

  /// Timeout for receiving the response.
  final Duration? receiveTimeout;

  /// Optional cancellation handle.
  final RawHttpCancellationToken? cancellationToken;

  /// Upload progress. `total` is the declared content length when known.
  final RawHttpProgressCallback? onSendProgress;
}
