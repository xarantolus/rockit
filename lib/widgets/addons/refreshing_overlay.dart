import 'package:flutter/material.dart';

/// Puts a slim progress bar over a listing while a background refresh runs.
///
/// The point is that cached content stays readable: the API regularly needs ten
/// seconds or more, and replacing a full list with a spinner for that long is
/// worse than showing slightly old data.
class RefreshingOverlay extends StatelessWidget {
  const RefreshingOverlay({
    required this.refreshing,
    required this.child,
    super.key,
  });

  final bool refreshing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: child),
        if (refreshing)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 3),
          ),
      ],
    );
  }
}
