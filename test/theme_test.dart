import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rockit/main.dart';
import 'package:rockit/theme.dart';

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

    test('the surface accent stays readable on the surfaces it is used on', () {
      // The other half of the test above, and the reason the two colours had
      // to be separated. Making primary dark enough for white to sit on it is
      // exactly what makes it unreadable *as* text on a dark card: the
      // related-launch chip measured 2.2:1 on device. Small text, so 4.5:1.
      for (final theme in [RockItApp.lightTheme, RockItApp.darkTheme]) {
        final scheme = theme.colorScheme;

        // The chip tints its background with primary, so that is what the
        // label actually sits on — not the bare card.
        final chip = Color.alphaBlend(
          scheme.primary.withValues(alpha: 0.10),
          theme.cardTheme.color ?? scheme.surface,
        );

        for (final background in [chip, scheme.surface]) {
          expect(
            contrast(scheme.surfaceAccent, background),
            greaterThanOrEqualTo(4.5),
            reason:
                'accent on ${background.toARGB32().toRadixString(16)} '
                'in the ${theme.brightness.name} theme',
          );
        }
      }
    });
  });
}

/// WCAG relative contrast between two opaque colours.
double contrast(Color a, Color b) {
  final high = max(a.computeLuminance(), b.computeLuminance());
  final low = min(a.computeLuminance(), b.computeLuminance());

  return (high + 0.05) / (low + 0.05);
}
