import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

/// A destination in [FloatingNavBar].
class NavDestination {
  const NavDestination({required this.icon, required this.label});

  final Widget icon;
  final String label;
}

/// A bottom bar that floats clear of the screen edges, with content scrolling
/// underneath it.
///
/// The host [Scaffold] must set `extendBody: true`, and anything scrollable
/// below needs [FloatingNavBar.allowance] added to its bottom padding —
/// otherwise the last item sits under the bar with no way to reach it.
class FloatingNavBar extends StatefulWidget {
  const FloatingNavBar({required this.destinations, super.key});

  final List<NavDestination> destinations;

  /// Height plus the margin below it — what a scroll view has to clear.
  static const allowance = 88.0;

  static const _margin = EdgeInsets.fromLTRB(16, 0, 16, 12);
  static const _height = 64.0;
  static const _radius = 32.0;

  @override
  State<FloatingNavBar> createState() => _FloatingNavBarState();
}

class _FloatingNavBarState extends State<FloatingNavBar> {
  TabController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final controller = DefaultTabController.of(context);
    if (controller == _controller) {
      return;
    }

    _detach();
    _controller = controller
      ..animation?.addListener(_onMoved)
      ..addListener(_onMoved);
  }

  void _detach() {
    _controller?.animation?.removeListener(_onMoved);
    _controller?.removeListener(_onMoved);
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  void _onMoved() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Where the selection is right now, as a fraction between destinations.
  ///
  /// The controller's `index` only moves once a swipe has committed, which made
  /// the bar look like it was lagging a page behind the content. Its
  /// `animation` tracks the drag itself, so the label can grow and the tint can
  /// cross over while the finger is still down.
  double get _position =>
      _controller?.animation?.value ?? _controller?.index.toDouble() ?? 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final position = _position;

    final items = [
      for (var i = 0; i < widget.destinations.length; i++)
        _item(
          context,
          widget.destinations[i],
          i,
          // 1 on this destination, 0 once a whole page away.
          (1 - (position - i).abs()).clamp(0.0, 1.0),
        ),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: FloatingNavBar._margin,
        // Shrink-wrapped and centred, because the bar is only as wide as its
        // icons. `heightFactor` matters: a plain Center takes the whole slot,
        // which floats the bar up the screen and pushes the search button off
        // the bottom.
        child: Align(
          alignment: Alignment.center,
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(FloatingNavBar._radius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(FloatingNavBar._radius),
              // Only the background is translucent; the icons and the label
              // sit on top at full strength. The blur is what keeps them
              // readable — a flat wash over a launch photo competes with them.
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Material(
                  color: theme.colorScheme.surface.withValues(alpha: 0.45),
                  child: SizedBox(
                    height: FloatingNavBar._height,
                    child: Row(mainAxisSize: MainAxisSize.min, children: items),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// [selectedness] is 1 on the destination being shown and 0 a page away, so
  /// everything about the item can be interpolated rather than switched.
  Widget _item(
    BuildContext context,
    NavDestination destination,
    int index,
    double selectedness,
  ) {
    final theme = Theme.of(context);
    final text = theme.textTheme.bodyMedium?.color ?? Colors.black;

    // Only the icon takes the accent. The label stays in the normal text
    // colour: accent-on-translucent was hard to read, especially in the dark
    // theme where the blue sits close to the background it is blurring.
    final iconColour = Color.lerp(
      text.withValues(alpha: 0.55),
      theme.colorScheme.primary,
      selectedness,
    )!;

    return InkWell(
      onTap: () => _controller?.animateTo(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconTheme(
              data: IconThemeData(color: iconColour, size: 24),
              child: destination.icon,
            ),
            // The label grows in rather than appearing, so tapping an icon
            // does not make the bar jump to a new shape in one frame.
            ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: selectedness,
                child: Opacity(
                  // Fades on the back half of the growth, so the text is never
                  // squeezed and faint at the same time.
                  opacity: max(0, selectedness * 2 - 1),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      destination.label,
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        color: text,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
