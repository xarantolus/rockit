import 'package:flutter_test/flutter_test.dart';
import 'package:rockit/apis/paging.dart';

void main() {
  group('mergePages', () {
    test('appends items that are not already present', () {
      final current = ['a', 'b'];

      final merged = mergePages(current, ['c', 'd'], (id) => id);

      expect(merged, ['a', 'b', 'c', 'd']);
    });

    test('drops items the list already has', () {
      // The API pages with overlapping windows, so this is the normal case
      // rather than an edge case.
      final merged = mergePages(['a', 'b'], ['b', 'c'], (id) => id);

      expect(merged, ['a', 'b', 'c']);
    });

    test('drops duplicates within the incoming page too', () {
      final merged = mergePages(['a'], ['b', 'b', 'c'], (id) => id);

      expect(merged, ['a', 'b', 'c']);
    });

    test('keeps the existing order', () {
      final merged = mergePages(['b', 'a'], ['a', 'c'], (id) => id);

      expect(merged, ['b', 'a', 'c']);
    });

    test('an empty incoming page changes nothing', () {
      final merged = mergePages(['a', 'b'], <String>[], (id) => id);

      expect(merged, ['a', 'b']);
    });

    test('merges into an empty list', () {
      final merged = mergePages(<String>[], ['a', 'b'], (id) => id);

      expect(merged, ['a', 'b']);
    });

    test('compares by id, not by object identity', () {
      final merged = mergePages(
        [(id: 1, name: 'old')],
        [(id: 1, name: 'updated'), (id: 2, name: 'new')],
        (item) => item.id,
      );

      // The already-known id keeps the copy that is on screen.
      expect(merged.map((e) => e.name), ['old', 'new']);
    });
  });
}
