import 'package:net_kit/net_kit.dart';
import 'package:test/test.dart';

void main() {
  group('RawHttpCancellationToken', () {
    test('isCancelled is false until cancel is called', () {
      final token = RawHttpCancellationToken();

      expect(token.isCancelled, isFalse);
      token.cancel();
      expect(token.isCancelled, isTrue);
    });

    test('cancel is idempotent', () {
      final token = RawHttpCancellationToken();

      expect(
        (token
              ..cancel()
              ..cancel())
            .isCancelled,
        isTrue,
      );
    });
  });
}
