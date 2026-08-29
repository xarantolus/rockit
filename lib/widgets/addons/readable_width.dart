import 'package:flutter/material.dart';

/// Caps content at a comfortable reading measure and centres it.
///
/// A detail page is one column, so on a tablet its prose ran the full width —
/// about 110 characters a line against the 45 to 75 that is comfortable. On a
/// phone this changes nothing, because the screen is already narrower than the
/// cap.
class ReadableWidth extends StatelessWidget {
  const ReadableWidth({required this.child, super.key});

  static const maxWidth = 700.0;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
