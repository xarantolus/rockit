import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rockit/theme.dart';
import 'package:rockit/widgets/addons/reselect.dart';

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

    _controller = DefaultTabController.of(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = _controller;

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
                    // Only the row of items depends on the tab animation. The
                    // blur and the material above it are built once and handed
                    // in, rather than rebuilt on every tick of a swipe.
                    child: controller == null
                        ? const SizedBox.shrink()
                        : ListenableBuilder(
                            listenable: Listenable.merge([
                              controller,
                              controller.animation,
                            ]),
                            builder: (context, _) => Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (
                                  var i = 0;
                                  i < widget.destinations.length;
                                  i++
                                )
                                  _NavItem(
                                    destination: widget.destinations[i],
                                    index: i,
                                    controller: controller,
                                  ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.index,
    required this.controller,
  });

  final NavDestination destination;
  final int index;
  final TabController controller;

  /// 1 on the destination being shown and 0 a page away, so everything about
  /// the item can be interpolated rather than switched.
  ///
  /// Read from `animation` rather than `index`, which only moves once a swipe
  /// has committed: the bar looked like it was lagging a page behind the
  /// content. This tracks the drag itself.
  double get _selectedness {
    final position = controller.animation?.value ?? controller.index.toDouble();

    return (1 - (position - index).abs()).clamp(0.0, 1.0);
  }

  void _onTap(BuildContext context) {
    // Tapping the destination already showing is not a no-op: it is how you
    // get out of a feed you have scrolled a long way down.
    if (controller.index == index && !controller.indexIsChanging) {
      Reselections.of(context)?.reselect(index);

      return;
    }

    controller.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme.bodyMedium?.color ?? Colors.black;
    final selectedness = _selectedness;

    // Only the icon takes the accent. The label stays in the normal text
    // colour: accent-on-translucent was hard to read, especially in the dark
    // theme where the blue sits close to the background it is blurring.
    final iconColour = Color.lerp(
      text.withValues(alpha: 0.55),
      theme.colorScheme.surfaceAccent,
      selectedness,
    )!;

    return InkWell(
      onTap: () => _onTap(context),
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
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    destination.label,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      // Fades on the back half of the growth, so the text is
                      // never squeezed and faint at the same time. A colour
                      // alpha rather than an Opacity layer.
                      color: text.withValues(
                        alpha: max(0, selectedness * 2 - 1),
                      ),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
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
