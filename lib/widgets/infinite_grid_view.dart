import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Grid that calls [nextData] when the end comes into reach.
///
/// Replaces the abandoned `infinite_widgets` package, which has no Dart 3
/// release.
class InfiniteGridView extends StatefulWidget {
  const InfiniteGridView({
    super.key,
    required this.gridDelegate,
    required this.itemBuilder,
    required this.itemCount,
    required this.hasNext,
    required this.nextData,
    this.loadingWidget,
    this.failedBuilder,
    this.controller,
    this.physics,
    this.cacheExtent,
    this.padding,
  });

  final SliverGridDelegate gridDelegate;
  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;
  final bool hasNext;

  /// Loads the next page; false means it failed.
  final Future<bool> Function() nextData;
  final Widget? loadingWidget;

  /// Shown in place of [loadingWidget] once a page has failed, until `retry`
  /// is called.
  final Widget Function(VoidCallback retry)? failedBuilder;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final double? cacheExtent;

  /// Applied inside the scrollable, so content scrolls through it rather than
  /// being clipped — used to keep the last row clear of the system bars.
  final EdgeInsets? padding;

  @override
  State<InfiniteGridView> createState() => _InfiniteGridViewState();
}

enum _PageState { idle, loading, failed }

class _InfiniteGridViewState extends State<InfiniteGridView> {
  _PageState _state = _PageState.idle;

  @override
  void didUpdateWidget(InfiniteGridView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.itemCount != oldWidget.itemCount) {
      _state = _PageState.idle;
    }
  }

  Future<void> _load() async {
    setState(() => _state = _PageState.loading);
    final ok = await widget.nextData();
    if (mounted) {
      setState(() => _state = ok ? _PageState.idle : _PageState.failed);
    }
  }

  bool _onScroll(ScrollNotification notification) {
    final metrics = notification.metrics;
    // Load one viewport ahead so the next page is ready on arrival.
    final threshold = metrics.maxScrollExtent - metrics.viewportDimension;
    // A failed page waits for a tap rather than retrying on every scroll.
    if (widget.hasNext &&
        _state == _PageState.idle &&
        metrics.pixels >= threshold) {
      unawaited(_load());
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final failed = widget.failedBuilder;
    final loading = _state == _PageState.failed && failed != null
        ? failed(() => unawaited(_load()))
        : widget.loadingWidget;
    final showLoader = widget.hasNext && loading != null;

    // One scrollable whether or not the footer is showing: swapping between
    // two scroll views on the last page reset the position to the top.
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: CustomScrollView(
        scrollCacheExtent: widget.cacheExtent == null
            ? null
            : ScrollCacheExtent.pixels(widget.cacheExtent!),
        controller: widget.controller,
        physics: widget.physics,
        slivers: [
          SliverPadding(
            padding: widget.padding ?? EdgeInsets.zero,
            sliver: SliverMainAxisGroup(
              slivers: [
                SliverGrid(
                  gridDelegate: widget.gridDelegate,
                  delegate: SliverChildBuilderDelegate(
                    widget.itemBuilder,
                    childCount: widget.itemCount,
                  ),
                ),
                if (showLoader) SliverToBoxAdapter(child: loading),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
