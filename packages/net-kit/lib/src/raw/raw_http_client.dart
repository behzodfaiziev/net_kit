import 'raw_http_request.dart';
import 'raw_http_response.dart';

/// Isolated raw HTTP transport.
///
/// Sends absolute URLs with caller-owned headers and returns status codes
/// and headers without API, auth, or model semantics.
abstract interface class RawHttpClient {
  /// Sends [request] and returns the HTTP response.
  ///
  /// Transport failures throw a raw transport exception. HTTP statuses,
  /// including non-2xx codes, are returned as [RawHttpResponse].
  Future<RawHttpResponse> send(RawHttpRequest request);
}
