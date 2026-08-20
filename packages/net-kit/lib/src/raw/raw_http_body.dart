/// Request body for a raw HTTP request.
///
/// The raw transport does not assume JSON or any application envelope.
sealed class RawHttpBody {
  /// Creates a raw HTTP body.
  const RawHttpBody();
}

/// Streaming request body that is forwarded without buffering the payload.
final class StreamRawHttpBody extends RawHttpBody {
  /// Creates a streaming body.
  ///
  /// [contentLength] is sent as the `Content-Length` header. The [stream]
  /// must not be fully materialized by the client.
  const StreamRawHttpBody({
    required this.stream,
    required this.contentLength,
  });

  /// Chunked request payload.
  final Stream<List<int>> stream;

  /// Exact number of bytes that [stream] will produce.
  final int contentLength;
}

/// In-memory binary request body.
final class BytesRawHttpBody extends RawHttpBody {
  /// Creates a bytes body.
  const BytesRawHttpBody(this.bytes);

  /// Raw bytes to send.
  final List<int> bytes;
}

/// UTF-8 string request body.
///
/// No `Content-Type` is inferred. Supply one on the request if needed.
final class StringRawHttpBody extends RawHttpBody {
  /// Creates a string body.
  const StringRawHttpBody(this.value);

  /// String payload.
  final String value;
}
