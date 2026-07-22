/// Helpers to render Latin digits as Persian (Eastern Arabic) digits.
///
/// Kept as a tiny, allocation-free utility so it is cheap to call inside
/// build methods.
const List<String> _persian = <String>['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

extension PersianDigits on String {
  /// Replaces every ASCII digit in the string with its Persian counterpart.
  String toPersianDigits() {
    final StringBuffer buffer = StringBuffer();
    for (final int unit in codeUnits) {
      if (unit >= 0x30 && unit <= 0x39) {
        buffer.write(_persian[unit - 0x30]);
      } else {
        buffer.writeCharCode(unit);
      }
    }
    return buffer.toString();
  }
}

extension PersianDigitsNum on num {
  String toPersianDigits() => toString().toPersianDigits();
}
