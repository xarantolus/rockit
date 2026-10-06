import 'package:flutter/material.dart';
import 'package:rockit/apis/launch_library/events_response.dart';
import 'package:rockit/apis/launch_library/launch_response.dart';
import 'package:rockit/pages/event_details.dart';
import 'package:rockit/pages/launch_details.dart';

/// Launch and event detail pages that can be swiped through left and right.
class DetailPager extends StatefulWidget {
  const DetailPager({
    required this.itemAt,
    required this.initialIndex,
    this.heroPrefix = "",
    this.onPageChanged,
    super.key,
  });

  /// The [Launch] or [Event] at an index, or null past the end. Read as pages
  /// are built, so a list that grows while the pager is open shows the new
  /// items.
  final Object? Function(int index) itemAt;

  final int initialIndex;
  final String heroPrefix;
  final ValueChanged<int>? onPageChanged;

  @override
  State<DetailPager> createState() => _DetailPagerState();
}

class _DetailPagerState extends State<DetailPager> {
  /// Only the page being looked at carries a hero. A PageView builds its
  /// neighbours, and on a pop Flutter flies *every* hero whose tag matches
  /// something in the list — so several images used to sail back at once. The
  /// system back gesture makes it obvious, because it also drags the PageView a
  /// little, leaving two pages partly on screen.
  late int _current = widget.initialIndex;

  late final _controller = PageController(initialPage: widget.initialIndex);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.custom(
      physics: const BouncingScrollPhysics(),
      controller: _controller,
      childrenDelegate: SliverChildBuilderDelegate((context, idx) {
        final item = widget.itemAt(idx);
        return switch (item) {
          null => null,
          Launch() => LaunchDetailsPage(
            item,
            heroPrefix: widget.heroPrefix,
            heroEnabled: idx == _current,
          ),
          Event() => EventDetailsPage(
            item,
            heroPrefix: widget.heroPrefix,
            heroEnabled: idx == _current,
          ),
          _ => throw ArgumentError(
            "Invalid data type ${item.runtimeType} in launch/event pager",
          ),
        };
      }),
      onPageChanged: (idx) {
        // Settles only once a swipe finishes, so a back gesture that merely
        // nudges the PageView leaves the hero where it was.
        setState(() => _current = idx);
        widget.onPageChanged?.call(idx);
      },
    );
  }
}
