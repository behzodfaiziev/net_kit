import 'package:net_kit/net_kit.dart';
import 'package:test/test.dart';

void main() {
  group('RawHttpBody', () {
    test('StreamRawHttpBody keeps the stream and contentLength', () {
      final stream = Stream.fromIterable([
        [1, 2],
        [3],
      ]);
      final body = StreamRawHttpBody(
        stream: stream,
        contentLength: 3,
      );

      expect(body.stream, same(stream));
      expect(body.contentLength, 3);
    });

    test('BytesRawHttpBody exposes the payload', () {
      const bytes = [4, 5, 6];
      const body = BytesRawHttpBody(bytes);

      expect(body.bytes, bytes);
    });

    test('StringRawHttpBody exposes the payload', () {
      const body = StringRawHttpBody('hello');

      expect(body.value, 'hello');
    });
  });
}
