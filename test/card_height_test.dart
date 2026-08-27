import 'package:flutter_test/flutter_test.dart';
import 'package:rockit/widgets/addons/launch_event.dart';

void main() {
  group('listing card height', () {
    // Top plus bottom of LaunchEventWidget.margin.
    const margin = 12.0;

    double heightFor(double width) => LaunchEventWidget.heightForWidth(width);

    double cardOnly(double width) => heightFor(width) - margin;

    test('follows the width, so a taller screen changes nothing', () {
      // The old rule was a third of the screen height, which is why the same
      // card was 250 tall on a short phone and 400 on a 20:9 one.
      expect(heightFor(411), heightFor(411));
      expect(cardOnly(411), closeTo((411 - 20) / 1.5, 0.01));
    });

    test('is the chosen aspect ratio until the cap', () {
      for (final width in [320.0, 411.0, 480.0]) {
        expect(
          cardOnly(width),
          closeTo((width - 20) / LaunchEventWidget.aspectRatio, 0.01),
          reason: 'width $width should be a plain ratio',
        );
      }
    });

    test('stops growing on a wide layout', () {
      // A tablet at 800dp would otherwise be 520 tall: one card per screen.
      expect(cardOnly(800), LaunchEventWidget.maxHeight);
      expect(cardOnly(2000), LaunchEventWidget.maxHeight);
    });

    test('the cap starts exactly where the ratio reaches it', () {
      final cutoff =
          LaunchEventWidget.maxHeight * LaunchEventWidget.aspectRatio + 20;

      expect(cardOnly(cutoff - 1), lessThan(LaunchEventWidget.maxHeight));
      expect(cardOnly(cutoff + 1), LaunchEventWidget.maxHeight);
    });

    test('a landscape column gets half the width, and so a shorter card', () {
      expect(heightFor(1000 / 2), lessThan(heightFor(1000)));
    });

    test('never goes negative when the width is smaller than the margin', () {
      expect(heightFor(0), margin);
      expect(heightFor(10), margin);
    });
  });
}
