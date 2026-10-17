import 'package:expenses_tracker/utils/split_calculation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('invalid and non-finite totals reset the displayed share', () {
    for (final text in ['', ' ', 'abc', '.', 'NaN', 'Infinity', '-Infinity', '1e999', '0', '-20']) {
      expect(parseExpenseTotal(text), isNull, reason: text);
      expect(calculateEqualShare(text, 3), 0, reason: text);
    }
  });
  test('positive decimal totals split across recipients', () {
    expect(parseExpenseTotal(' 120.5 '), 120.5);
    expect(calculateEqualShare('120.5', 4), 30.125);
    expect(calculateEqualShare('25', 1), 25);
  });
  test('no recipients never produces infinity or a divide-by-zero result', () {
    expect(calculateEqualShare('100', 0), 0);
    expect(calculateEqualShare('100', -1), 0);
  });
}
