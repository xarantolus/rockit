import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rockit/main.dart';

void main() {
  group('page transitions', () {
    test('detail pages rise from the bottom on Android', () {
      // Flutter's current Android default slides in from the side, which reads
      // as sideways motion in a vertically scrolled list and fights the
      // horizontal pager between launches.
      for (final theme in [RockItApp.lightTheme, RockItApp.darkTheme]) {
        expect(
          theme.pageTransitionsTheme.builders[TargetPlatform.android],
          isA<OpenUpwardsPageTransitionsBuilder>(),
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
