import 'package:flutter_test/flutter_test.dart';
import 'package:rockit/util/ordinal.dart';

void main() {
  group('englishOrdinal', () {
    test('uses st, nd, rd for 1, 2, 3', () {
      expect(englishOrdinal(1), '1st');
      expect(englishOrdinal(2), '2nd');
      expect(englishOrdinal(3), '3rd');
    });

    test('uses th for 4 through 10', () {
      for (var n = 4; n <= 10; n++) {
        expect(englishOrdinal(n), '${n}th');
      }
    });

    test('11, 12 and 13 take th despite their last digit', () {
      expect(englishOrdinal(11), '11th');
      expect(englishOrdinal(12), '12th');
      expect(englishOrdinal(13), '13th');
    });

    test('21, 22, 23 go back to st, nd, rd', () {
      expect(englishOrdinal(21), '21st');
      expect(englishOrdinal(22), '22nd');
      expect(englishOrdinal(23), '23rd');
    });

    test('the exception repeats in every hundred', () {
      expect(englishOrdinal(111), '111th');
      expect(englishOrdinal(112), '112th');
      expect(englishOrdinal(113), '113th');
      expect(englishOrdinal(211), '211th');
      expect(englishOrdinal(1013), '1013th');
    });

    test('handles the counts the API actually sends', () {
      // Real values: pad, agency and orbital launch attempt counts.
      expect(englishOrdinal(105), '105th');
      expect(englishOrdinal(221), '221st');
      expect(englishOrdinal(223), '223rd');
      expect(englishOrdinal(7378), '7378th');
    });

    test('zero takes th', () {
      expect(englishOrdinal(0), '0th');
    });
  });
}
