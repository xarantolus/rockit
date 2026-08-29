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

    _controller?.removeListener(_onTabChanged);
    _controller = controller..addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = _controller?.index ?? 0;

    final items = [
      for (var i = 0; i < widget.destinations.length; i++)
        _item(context, widget.destinations[i], i, i == selected),
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

  Widget _item(
    BuildContext context,
    NavDestination destination,
    int index,
    bool isSelected,
  ) {
    final theme = Theme.of(context);
    final active = theme.colorScheme.primary;
    final idle = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.55);

    return InkWell(
      onTap: () => _controller?.animateTo(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconTheme(
              data: IconThemeData(color: isSelected ? active : idle, size: 24),
              child: destination.icon,
            ),
            // Only the selected destination is named, which is what lets the
            // bar stay as narrow as it is.
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                destination.label,
                style: TextStyle(
                  color: active,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
