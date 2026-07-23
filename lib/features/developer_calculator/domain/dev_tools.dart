/// Pure, dependency-free helpers behind the developer calculator. Keeping the
/// logic here (separate from widgets) makes it trivial to unit-test.
class DevTools {
  const DevTools._();

  /// Parses [input] as an integer in [radix] (2, 8, 10 or 16). Returns null on
  /// invalid input.
  static int? parse(String input, int radix) {
    final String cleaned = input.trim().replaceAll(RegExp(r'\s+'), '');
    if (cleaned.isEmpty) return null;
    return int.tryParse(cleaned, radix: radix);
  }

  static String toBase(int value, int radix) {
    if (value < 0) {
      return '-${(-value).toRadixString(radix).toUpperCase()}';
    }
    return value.toRadixString(radix).toUpperCase();
  }

  /// Groups a binary string into nibbles for readability, e.g. 1010 1100.
  static String groupBinary(String binary) {
    final bool negative = binary.startsWith('-');
    final String digits = negative ? binary.substring(1) : binary;
    final StringBuffer out = StringBuffer();
    final int pad = (4 - digits.length % 4) % 4;
    final String padded = '0' * pad + digits;
    for (int i = 0; i < padded.length; i++) {
      if (i != 0 && i % 4 == 0) out.write(' ');
      out.write(padded[i]);
    }
    return (negative ? '-' : '') + out.toString();
  }

  // --- Bitwise ---------------------------------------------------------------

  static int and(int a, int b) => a & b;
  static int or(int a, int b) => a | b;
  static int xor(int a, int b) => a ^ b;
  static int not(int a) => ~a;
  static int shiftLeft(int a, int bits) => a << bits;
  static int shiftRight(int a, int bits) => a >> bits;

  // --- Bytes -----------------------------------------------------------------

  static const List<String> byteUnits = <String>['B', 'KB', 'MB', 'GB', 'TB', 'PB'];

  /// Human-readable size using binary (1024) multiples.
  static String humanBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    double value = bytes.toDouble();
    int unit = 0;
    while (value >= 1024 && unit < byteUnits.length - 1) {
      value /= 1024;
      unit++;
    }
    return '${value.toStringAsFixed(2)} ${byteUnits[unit]}';
  }

  /// Converts [value] given in the unit at [fromUnitIndex] to raw bytes.
  static int toBytes(double value, int fromUnitIndex) =>
      (value * _pow1024(fromUnitIndex)).round();

  static num _pow1024(int exp) {
    num result = 1;
    for (int i = 0; i < exp; i++) {
      result *= 1024;
    }
    return result;
  }

  // --- Timestamps ------------------------------------------------------------

  static DateTime? fromEpochSeconds(String input) {
    final int? v = int.tryParse(input.trim());
    if (v == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(v * 1000);
  }

  static DateTime? fromEpochMillis(String input) {
    final int? v = int.tryParse(input.trim());
    if (v == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(v);
  }

  // --- ASCII -----------------------------------------------------------------

  static const Map<int, String> _controlNames = <int, String>{
    0: 'NUL', 1: 'SOH', 2: 'STX', 3: 'ETX', 4: 'EOT', 5: 'ENQ', 6: 'ACK',
    7: 'BEL', 8: 'BS', 9: 'TAB', 10: 'LF', 11: 'VT', 12: 'FF', 13: 'CR',
    14: 'SO', 15: 'SI', 16: 'DLE', 17: 'DC1', 18: 'DC2', 19: 'DC3', 20: 'DC4',
    21: 'NAK', 22: 'SYN', 23: 'ETB', 24: 'CAN', 25: 'EM', 26: 'SUB', 27: 'ESC',
    28: 'FS', 29: 'GS', 30: 'RS', 31: 'US', 32: 'SP', 127: 'DEL',
  };

  static String asciiGlyph(int code) =>
      _controlNames[code] ?? String.fromCharCode(code);

  static List<int> get asciiCodes =>
      List<int>.generate(128, (int i) => i, growable: false);
}
