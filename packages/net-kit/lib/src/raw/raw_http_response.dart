/// Transport response with no API or model interpretation.
final class RawHttpResponse {
  /// Creates a raw HTTP response.
  const RawHttpResponse({
    required this.statusCode,
    required this.headers,
    this.body,
  });

  /// HTTP status code as returned by the server.
  final int statusCode;

  /// Response headers. Keys are not normalized.
  final Map<String, List<String>> headers;

  /// Response body. Typically `List<int>` when using the Dio adapter.
  final Object? body;

  /// Case-insensitive header lookup.
  ///
  /// Returns `null` when the header is absent or has no values.
  /// Multiple values are joined with `', '`.
  String? header(String name) {
    final target = name.toLowerCase();
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == target) {
        if (entry.value.isEmpty) {
          return null;
        }
        return entry.value.join(', ');
      }
    }
    return null;
  }
}
