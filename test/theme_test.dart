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

    test('the app bar keeps its brand colour in the light theme', () {
      expect(RockItApp.lightTheme.appBarTheme.backgroundColor, isNotNull);
    });
  });
}
