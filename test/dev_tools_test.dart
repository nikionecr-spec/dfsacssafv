import 'package:flutter_test/flutter_test.dart';
import 'package:productivity_app/features/developer_calculator/domain/dev_tools.dart';

void main() {
  group('DevTools · base conversion', () {
    test('parses hexadecimal', () {
      expect(DevTools.parse('FF', 16), 255);
      expect(DevTools.parse('0', 16), 0);
      expect(DevTools.parse('zz', 16), isNull);
    });

    test('formats to base', () {
      expect(DevTools.toBase(255, 2), '11111111');
      expect(DevTools.toBase(255, 16), 'FF');
      expect(DevTools.toBase(8, 8), '10');
    });

    test('groups binary into nibbles', () {
      expect(DevTools.groupBinary('11111111'), '1111 1111');
      expect(DevTools.groupBinary('101'), '0101');
    });
  });

  group('DevTools · bitwise', () {
    test('AND / OR / XOR', () {
      expect(DevTools.and(12, 10), 8);
      expect(DevTools.or(12, 10), 14);
      expect(DevTools.xor(12, 10), 6);
    });

    test('shifts', () {
      expect(DevTools.shiftLeft(1, 4), 16);
      expect(DevTools.shiftRight(16, 2), 4);
    });
  });

  group('DevTools · bytes', () {
    test('human readable', () {
      expect(DevTools.humanBytes(512), '512 B');
      expect(DevTools.humanBytes(1024), '1.00 KB');
      expect(DevTools.humanBytes(1024 * 1024), '1.00 MB');
    });

    test('to bytes', () {
      expect(DevTools.toBytes(1, 2), 1024 * 1024);
      expect(DevTools.toBytes(2, 1), 2048);
    });
  });

  group('DevTools · timestamps', () {
    test('parses epoch seconds', () {
      final DateTime? d = DevTools.fromEpochSeconds('0');
      expect(d?.toUtc().year, 1970);
    });
  });
}
