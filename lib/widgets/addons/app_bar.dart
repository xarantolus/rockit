import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Overlay style for a screen whose app bar is the primary colour.
///
/// The bars stay transparent: the app is edge-to-edge, so the app bar itself
/// paints the area behind the status bar. Only the icon brightness matters, and
/// it has to be light — the primary colour is a saturated blue that the default
/// dark icons disappear into.
///
/// `statusBarColor` and `systemNavigationBarColor` are deliberately not set.
/// Android 15 deprecated and disabled both (`setNavigationBarColor` still
/// applies at 80% alpha under 3-button navigation, nothing more), so setting
/// them buys nothing and hides the fact that contrast is what does the work.
SystemUiOverlayStyle systemOverlayStyle(BuildContext context) {
  final darkTheme = Theme.of(context).brightness == Brightness.dark;

  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    // iOS spells the same thing the other way round.
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    // Navigation sits over app content, not over the app bar, so its icons
    // follow the theme rather than being light like the status bar's.
    systemNavigationBarIconBrightness: darkTheme
        ? Brightness.light
        : Brightness.dark,
    systemNavigationBarContrastEnforced: true,
  );
}

class CustomAppBar {
  static AppBar create(
    BuildContext context, {
    String? title,
    TextStyle? titleStyle,
    List<Widget>? actions,
    Widget? icon,
  }) {
    var barColor = Theme.of(context).colorScheme.primary;

    return AppBar(
      backgroundColor: barColor,
      iconTheme: IconTheme.of(context).copyWith(color: Colors.white),
      centerTitle: true,
      systemOverlayStyle: systemOverlayStyle(context),
      title: title == null
          ? null
          : Text(
              title,
              style:
                  titleStyle?.copyWith(color: Colors.white) ??
                  const TextStyle(color: Colors.white),
            ),
      leading: icon == null
          ? null
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Tooltip(message: title ?? "", child: icon),
            ),
      actions: actions,
    );
  }
}
