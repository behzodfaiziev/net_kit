/// Transport-level failure kinds for [RawHttpException].
///
/// HTTP status codes are not failures; they are returned on the
/// raw HTTP response.
enum RawHttpFailureType {
  /// Connect, send, or receive timeout.
  timeout,

  /// DNS, TLS, or connection failure.
  connection,

  /// The request was cancelled.
  cancellation,

  /// Unclassified transport failure.
  unknown,
}

/// Thrown when the raw HTTP transport cannot complete a request.
///
/// This is not an API-layer exception. Protocol statuses such as 308, 404,
/// 410, and 500 are returned as a raw response instead.
final class RawHttpException implements Exception {
  /// Creates a transport exception.
  const RawHttpException({
    required this.message,
    required this.type,
    this.cause,
    this.uri,
  });

  /// Human-readable failure description.
  final String message;

  /// Failure classification.
  final RawHttpFailureType type;

  /// Underlying error, if any.
  final Object? cause;

  /// Request URI, when known.
  final Uri? uri;

  @override
  String toString() => 'RawHttpException($type): $message';
}
