import 'package:flutter_test/flutter_test.dart';
import 'package:rockit/util/by_date.dart';

typedef _Item = (String, DateTime?);

List<String> _names(List<_Item> items) => [for (final (n, _) in items) n];

List<_Item> _sort(List<_Item> items) => sortedByDate(items, (i) => i.$2);

void main() {
  final oct7 = DateTime.utc(2026, 10, 7, 5, 5);
  final oct8 = DateTime.utc(2026, 10, 8, 15, 25);
  final oct9 = DateTime.utc(2026, 10, 9);

  test('orders by date rather than by the order given', () {
    expect(
      _names(
        _sort([("splashdown", oct8), ("briefing", oct9), ("undock", oct7)]),
      ),
      ["undock", "splashdown", "briefing"],
    );
  });

  test('puts items without a date last, in their original order', () {
    expect(
      _names(_sort([("a", null), ("b", oct8), ("c", null), ("d", oct7)])),
      ["d", "b", "a", "c"],
    );
  });

  test('keeps the original order for equal dates', () {
    final items = [for (var i = 0; i < 20; i++) ("$i", oct7)];
    expect(_names(_sort(items)), [for (var i = 0; i < 20; i++) "$i"]);
  });

  test('handles an empty list', () {
    expect(_sort(const []), isEmpty);
  });
}
