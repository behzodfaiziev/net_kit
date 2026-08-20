import 'dart:io';

import 'package:net_kit/net_kit.dart';
import 'package:test/test.dart';

void main() {
  group('raw HTTP architecture', () {
    test('generic raw HTTP layer does not depend on Dio', () {
      final directory = Directory('lib/src/raw');
      expect(directory.existsSync(), isTrue);

      final leaks = <String>[];
      for (final entity in directory.listSync()) {
        if (entity is! File || !entity.path.endsWith('.dart')) {
          continue;
        }
        final source = File(entity.path).readAsStringSync();
        if (source.contains('package:dio/')) {
          leaks.add(entity.path);
        }
      }

      expect(leaks, isEmpty);
    });

    test('DioRawHttpClient constructs without Dio arguments', () {
      final client = DioRawHttpClient();
      expect(client, isA<RawHttpClient>());
      client.close();
    });
  });
}
