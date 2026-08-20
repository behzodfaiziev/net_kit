import 'package:net_kit/net_kit.dart';
import 'package:test/test.dart';

void main() {
  group('RawHttpResponse', () {
    test('header lookup is case-insensitive', () {
      const response = RawHttpResponse(
        statusCode: 308,
        headers: {
          'Range': ['bytes=0-8388607'],
        },
      );

      expect(response.header('Range'), 'bytes=0-8388607');
      expect(response.header('range'), 'bytes=0-8388607');
      expect(response.header('RANGE'), 'bytes=0-8388607');
    });

    test('missing header returns null', () {
      const response = RawHttpResponse(
        statusCode: 200,
        headers: {},
      );

      expect(response.header('ETag'), isNull);
    });

    test('empty header values return null', () {
      const response = RawHttpResponse(
        statusCode: 200,
        headers: {
          'ETag': <String>[],
        },
      );

      expect(response.header('ETag'), isNull);
    });

    test('multiple values are comma-joined', () {
      const response = RawHttpResponse(
        statusCode: 200,
        headers: {
          'Accept-Ranges': ['bytes', 'none'],
        },
      );

      expect(response.header('Accept-Ranges'), 'bytes, none');
    });

    test('stores protocol statuses without classifying success', () {
      const statuses = [308, 404, 410, 500];

      for (final status in statuses) {
        final response = RawHttpResponse(
          statusCode: status,
          headers: const {},
        );
        expect(response.statusCode, status);
      }
    });
  });
}
