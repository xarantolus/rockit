import 'package:flutter/material.dart';

/// The brand blue at a lightness that reads on a *light* surface: 4.6:1 on the
/// tinted chip and 5.6:1 on the page.
///
/// It is the same blue the dark theme fills its app bar with, which is the
/// whole point — see [SurfaceAccent.surfaceAccent].
const _lightSurfaceAccent = Color.fromRGBO(0x2B, 0x66, 0xBF, 1.0);

/// The brand blue at a lightness that reads on a *dark* surface: 5.1:1 on the
/// tinted chip and 6.7:1 on the page.
const _darkSurfaceAccent = Color.fromRGBO(0x6F, 0xA8, 0xFF, 1.0);

extension SurfaceAccent on ColorScheme {
  /// The brand colour for text and icons drawn *on* a surface, as opposed to
  /// [primary], which is a colour drawn *behind* white.
  ///
  /// The two cannot be the same colour, and treating them as one is a real bug
  /// rather than a nicety. [primary] has to be dark enough for white to sit on
  /// it in the app bar and the FABs, which is exactly what leaves it too close
  /// to a surface to be read *as* text: the related-launch chip measured
  /// **2.2:1** in the dark theme and **2.8:1** in the light one, against 4.5:1
  /// for small text.
  ///
  /// The neat part is that the app already had both colours; it was using each
  /// on the wrong background. Every theme's fill blue is the other theme's
  /// accent blue.
  Color get surfaceAccent =>
      brightness == Brightness.dark ? _darkSurfaceAccent : _lightSurfaceAccent;
}
