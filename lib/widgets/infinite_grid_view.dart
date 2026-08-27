import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Grid that calls [nextData] when the end comes into reach.
///
/// Replaces the abandoned `infinite_widgets` package, which has no Dart 3
/// release; the constructor arguments are unchanged.
class InfiniteGridView extends StatefulWidget {
  const InfiniteGridView({
    super.key,
    required this.gridDelegate,
    required this.itemBuilder,
    required this.itemCount,
    required this.hasNext,
    required this.nextData,
    this.loadingWidget,
    this.controller,
    this.physics,
    this.cacheExtent,
    this.padding,
  });

  final SliverGridDelegate gridDelegate;
  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;
  final bool hasNext;
  final VoidCallback nextData;
  final Widget? loadingWidget;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final double? cacheExtent;

  /// Applied inside the scrollable, so content scrolls through it rather than
  /// being clipped — used to keep the last row clear of the system bars.
  final EdgeInsets? padding;

  @override
  State<InfiniteGridView> createState() => _InfiniteGridViewState();
}

class _InfiniteGridViewState extends State<InfiniteGridView> {
  bool _requested = false;

  @override
  void didUpdateWidget(InfiniteGridView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.itemCount != oldWidget.itemCount) {
      _requested = false;
    }
  }

  bool _onScroll(ScrollNotification notification) {
    final metrics = notification.metrics;
    // Load one viewport ahead so the next page is ready on arrival.
    final threshold = metrics.maxScrollExtent - metrics.viewportDimension;
    if (widget.hasNext && !_requested && metrics.pixels >= threshold) {
      _requested = true;
      widget.nextData();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final loading = widget.loadingWidget;
    final showLoader = widget.hasNext && loading != null;

    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: showLoader
          ? SingleChildScrollView(
              controller: widget.controller,
              physics: widget.physics,
              padding: widget.padding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GridView.builder(
                    gridDelegate: widget.gridDelegate,
                    itemBuilder: widget.itemBuilder,
                    itemCount: widget.itemCount,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                  ),
                  loading,
                ],
              ),
            )
          : GridView.builder(
              scrollCacheExtent: widget.cacheExtent == null
                  ? null
                  : ScrollCacheExtent.pixels(widget.cacheExtent!),
              gridDelegate: widget.gridDelegate,
              itemBuilder: widget.itemBuilder,
              itemCount: widget.itemCount,
              controller: widget.controller,
              physics: widget.physics,
              padding: widget.padding ?? EdgeInsets.zero,
            ),
    );
  }
}
