import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rockit/main.dart';

void main() {
  group('page transitions', () {
    test('detail pages rise from the bottom on Android', () {
      // Must not be OpenUpwards: that one reveals the page through a clip
      // sweeping bottom to top, so the hero at the top is uncovered last and
      // the text over it snaps in at the end.
      for (final theme in [RockItApp.lightTheme, RockItApp.darkTheme]) {
        expect(
          theme.pageTransitionsTheme.builders[TargetPlatform.android],
          isA<FadeUpwardsPageTransitionsBuilder>(),
        );
      }
    });
  });

  group('theme', () {
    test('light and dark disagree about brightness', () {
      expect(RockItApp.lightTheme.brightness, Brightness.light);
      expect(RockItApp.darkTheme.brightness, Brightness.dark);
    });

    test('white app bar text stays readable on the brand colour', () {
      // `appBarTheme.backgroundColor, isNotNull` passed on any colour at all,
      // and only ever looked at the light theme — the dark one does not set it.
      // What actually decides this is colorScheme.primary: CustomAppBar.create
      // paints every app bar with it, and main.dart forces the title and the
      // status bar icons white over the top. Lighten the brand colour and they
      // disappear, which no other test would notice.
      for (final theme in [RockItApp.lightTheme, RockItApp.darkTheme]) {
        final contrast =
            1.05 / (theme.colorScheme.primary.computeLuminance() + 0.05);

        expect(
          contrast,
          greaterThanOrEqualTo(3.0),
          reason: 'white-on-primary must clear the 3:1 bar for large text',
        );
      }
    });
  });
}
