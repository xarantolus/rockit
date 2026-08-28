import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rockit/widgets/addons/shared_image_hero.dart';

/// The direction mapping is the part of a hero shuttle that is easy to get
/// backwards, and getting it backwards is not a crash — it is a cross-fade
/// that runs the wrong way, which only shows up as "the text flickers" on a
/// device. So it is a pure function, and this is where it is pinned.
void main() {
  group('flightProgress', () {
    test('a push runs from the card end to the page end', () {
      expect(flightProgress(HeroFlightDirection.push, 0), 0);
      expect(flightProgress(HeroFlightDirection.push, 1), 1);
    });

    test('a pop runs the other way, on an animation that also counts down', () {
      // The flight animation is the *popped* route's, so it goes 1 to 0 while
      // from/to swap ends. Both inversions have to be applied, not one.
      expect(flightProgress(HeroFlightDirection.pop, 1), 0);
      expect(flightProgress(HeroFlightDirection.pop, 0), 1);
    });

    test('the midpoint is the midpoint either way', () {
      expect(flightProgress(HeroFlightDirection.push, 0.5), 0.5);
      expect(flightProgress(HeroFlightDirection.pop, 0.5), 0.5);
    });

    test('is monotonic in both directions', () {
      double previousPush = -1;
      double previousPop = -1;

      for (var i = 0; i <= 10; i++) {
        final push = flightProgress(HeroFlightDirection.push, i / 10);
        final pop = flightProgress(HeroFlightDirection.pop, 1 - i / 10);

        expect(push, greaterThan(previousPush));
        expect(pop, greaterThan(previousPop));

        previousPush = push;
        previousPop = pop;
      }
    });

    test('a value outside the range cannot invert the fade', () {
      // Curved route animations overshoot; that must not read as "going back".
      expect(flightProgress(HeroFlightDirection.push, -0.1), 0);
      expect(flightProgress(HeroFlightDirection.push, 1.2), 1);
    });
  });

  group('overlayCrossFade', () {
    test('each end shows only its own overlay', () {
      expect(overlayCrossFade(0), 0);
      expect(overlayCrossFade(1), 1);
    });

    test('holds the starting overlay while the box is still card-shaped', () {
      // Otherwise the page's big countdown is already half visible inside a
      // card-sized rect, which is the ghosting this interval exists to avoid.
      expect(overlayCrossFade(0.1), 0);
      expect(overlayCrossFade(0.2), 0);
    });

    test('has finished before the flight lands', () {
      expect(overlayCrossFade(0.7), 1);
      expect(overlayCrossFade(0.9), 1);
    });

    test('swaps through the middle without stalling', () {
      final quarter = overlayCrossFade(0.325);
      final half = overlayCrossFade(0.45);
      final threeQuarters = overlayCrossFade(0.575);

      expect(half, closeTo(0.5, 0.01));
      expect(quarter, lessThan(half));
      expect(half, lessThan(threeQuarters));
    });

    test('never leaves both overlays dim at once', () {
      // The two are exact complements, so the scrim's total opacity is
      // constant across the flight rather than dipping in the middle.
      for (var i = 0; i <= 20; i++) {
        final fade = overlayCrossFade(i / 20);

        expect(fade + (1 - fade), 1);
        expect(fade, inInclusiveRange(0, 1));
      }
    });
  });
}
