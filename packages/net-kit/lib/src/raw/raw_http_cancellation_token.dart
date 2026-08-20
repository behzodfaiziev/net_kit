/// Caller-owned cancellation handle for a raw HTTP request.
///
/// The public contract does not expose any HTTP-client implementation type.
final class RawHttpCancellationToken {
  /// Creates a cancellation token.
  RawHttpCancellationToken();

  bool _isCancelled = false;
  void Function()? _onCancel;

  /// Whether [cancel] has been called.
  bool get isCancelled => _isCancelled;

  /// Cancels the in-flight request, if any.
  void cancel() {
    if (_isCancelled) {
      return;
    }
    _isCancelled = true;
    _onCancel?.call();
  }
}

/// Binds [token] to an adapter-specific cancel callback.
///
/// Used by the Dio raw client. Not part of the package public API.
void bindRawHttpCancellationToken(
  RawHttpCancellationToken token,
  void Function() onCancel,
) {
  token._onCancel = onCancel;
  if (token._isCancelled) {
    onCancel();
  }
}
