import 'dart:async';
import 'dart:core';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rockit/l10n/app_localizations.dart';
import 'package:rockit/widgets/infinite_grid_view.dart';
import 'package:rockit/apis/cache_first.dart';
import 'package:rockit/apis/error_details.dart';
import 'package:rockit/apis/launch_library/events_response.dart';
import 'package:rockit/apis/launch_library/launch_response.dart';
import 'package:rockit/pages/event_details.dart';
import 'package:rockit/pages/launch_details.dart';
import 'package:rockit/widgets/addons/insets.dart';
import 'package:rockit/widgets/addons/launch_event.dart';
import 'package:rockit/widgets/addons/planet_loading_animation.dart';
import 'package:rockit/widgets/addons/refreshing_overlay.dart';
import 'package:rockit/widgets/event.dart';
import 'package:rockit/widgets/launch.dart';

class NextFuncResult<I, S> {
  S? nextArg;

  List<I> items;

  /// Set when the load succeeded only partially, e.g. it fell back to the
  /// cache. Surfaced as a snackbar once.
  final ErrorType? notice;

  NextFuncResult(this.items, this.nextArg, {this.notice});
}

/// Loads a page from the network. [current] is the list to extend, empty on a
/// first load or a refresh.
typedef NextFunc<I, N> =
    Future<NextFuncResult<I, N>> Function(N? nextItemArg, List<I> current);

/// Reads the first page out of the cache, or returns null when nothing is
/// stored. Must not touch the network.
typedef CachedFunc<I, N> = Future<NextFuncResult<I, N>?> Function();

class LaunchEventListing<I, N> extends StatefulWidget {
  const LaunchEventListing({
    this.initialItems,
    this.nextFunc,
    this.cachedFunc,
    this.initialNextItemArg,
    required this.emptyText,
    this.refreshOnLeave = false,
    this.scrollOffset,
    this.heroPrefix = "",
    super.key,
  }) : assert(initialItems == null || nextFunc == null),
       assert(initialItems != null || nextFunc != null);

  // Either initialItems OR nextFunc must be given
  final List<I>? initialItems;
  final NextFunc<I, N>? nextFunc;

  /// Reads the first page out of the cache so it can be shown before the
  /// network answers. Listings that have no cache leave this null and simply
  /// show the loading animation until [nextFunc] returns.
  final CachedFunc<I, N>? cachedFunc;

  final N? initialNextItemArg;

  final String heroPrefix;

  final String emptyText;

  final bool refreshOnLeave;

  final ValueNotifier<double>? scrollOffset;

  @override
  State<LaunchEventListing<I, N>> createState() =>
      _LaunchEventListingState<I, N>();
}

class _LaunchEventListingState<I, N> extends State<LaunchEventListing<I, N>>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final CacheFirstController<NextFuncResult<I, N>> controller =
      CacheFirstController(
        loadCached: () async => await widget.cachedFunc?.call(),
        loadFresh: () async {
          final result = await widget.nextFunc!(null, <I>[]);
          controller.noteNotice(result.notice);
          return result;
        },
      );

  @override
  void initState() {
    super.initState();

    // The tab keeps this state alive, so this runs once per app start rather
    // than on every tab switch — which matters at 15 requests per hour.
    if (widget.initialItems == null) {
      controller.addListener(_onControllerUpdate);
      unawaited(controller.start());
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerUpdate);
    controller.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (!mounted) {
      return;
    }

    final notice = controller.takeNotice();

    setState(() {});

    notice?.showSnack(context);
  }

  Widget _buildList(NextFuncResult<I, N> results) {
    return ItemList(
      results,
      widget.nextFunc,
      widget.refreshOnLeave,
      widget.emptyText,
      widget.heroPrefix,
      scrollOffset: widget.scrollOffset,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.initialItems != null) {
      return _buildList(NextFuncResult<I, N>(widget.initialItems!, null));
    }

    final results = controller.data;

    if (results == null) {
      if (controller.status == ListingStatus.failed) {
        return GestureDetector(
          child: ErrorWidget(
            "${controller.fatalError}\n${AppLocalizations.of(context)!.tapToTryAgain}",
          ),
          onTap: () => unawaited(controller.refresh()),
        );
      }

      return const Center(child: PlanetLoadingAnimation());
    }

    // An empty cached page while the refresh is still running is not "nothing
    // to show" yet, so keep waiting rather than flashing the empty text.
    if (results.items.isEmpty && !controller.isRefreshing) {
      return Center(child: Text(widget.emptyText));
    }

    return RefreshingOverlay(
      refreshing: controller.isRefreshing,
      child: _buildList(results),
    );
  }
}

class ItemList<I, N> extends StatefulWidget {
  const ItemList(
    this.initial,
    this.nextFunc,
    this.refreshOnLeave,
    this.emptyText,
    this.heroPrefix, {
    this.scrollOffset,
    super.key,
  });

  final NextFuncResult<I, N> initial;

  final bool refreshOnLeave;
  final String emptyText;

  final String heroPrefix;

  final ValueNotifier<double>? scrollOffset;

  final NextFunc<I, N>? nextFunc;

  @override
  State<ItemList<I, N>> createState() => _ItemListState<I, N>();
}

class _ItemListState<I, N> extends State<ItemList<I, N>> {
  late List<I> items = widget.initial.items;
  late N? nextItemArg = widget.initial.nextArg;

  bool _currentlyLoading = false;

  /// Whether the user has paged past the first page.
  bool _paged = false;

  @override
  void didUpdateWidget(ItemList<I, N> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (identical(widget.initial, oldWidget.initial)) {
      return;
    }

    // A background refresh produced a new first page. If the user has already
    // paged further, dropping their extra pages would shrink the list out from
    // under them mid-scroll — so keep what they have. The refresh still landed
    // in the HTTP cache and will be picked up on the next start.
    if (_paged) {
      return;
    }

    items = widget.initial.items;
    nextItemArg = widget.initial.nextArg;
  }

  late ScrollController listController = ScrollController(
    initialScrollOffset: widget.scrollOffset?.value ?? 0,
  );

  Future<bool> _updateItems([bool? refresh]) async {
    if (_currentlyLoading) {
      return true;
    }
    _currentlyLoading = true;

    Object? error;

    try {
      var nextURL = refresh == true ? null : nextItemArg;

      var newItems = await widget.nextFunc!(
        nextURL,
        refresh == true ? <I>[] : items,
      );

      if (mounted) {
        setState(() {
          // Refresh? => replace
          items = newItems.items;
          nextItemArg = newItems.nextArg;
          _paged = refresh != true;
        });

        newItems.notice?.showSnack(context);
      }
    } catch (e) {
      error = e;
    } finally {
      _currentlyLoading = false;
      if (mounted) {
        setState(() {});
      }
    }

    if (error != null) {
      throw error;
    }

    return true;
  }

  Future<bool> _loadMore([bool refresh = false]) async {
    try {
      if (widget.nextFunc == null) {
        return false;
      }
      return await _updateItems(refresh);
    } catch (e) {
      debugPrint("Loading more events: $e");
      return false;
    }
  }

  void _openItemDetails(BuildContext context, int index) async {
    double? initialListHeight = listController.hasClients
        ? listController.position.maxScrollExtent
        : null;
    void scrollToIndex(int idx, {bool animated = false}) {
      // The try is there because MediaQuery is not always available
      try {
        // Scroll the list view to the currently viewed launch. If the user now leaves this view
        // the list will have scrolled to the last viewed item, which is nice
        int columns = 1;
        try {
          columns = LaunchEventWidget.columnsForContext(context);
        } catch (_) {}

        // The card sizes off its own width, so more columns means shorter
        // cards — the offset maths has to use the same number.
        final wheight = LaunchEventWidget.calculateHeight(
          context,
          columns: columns,
        );

        // The row this item is on, roughly centred.
        final targetOffset = min(
          max(wheight * (idx ~/ columns) - wheight / 2, 0.0),
          // Do not scroll further than the list height.
          // The wheight * items.length is not a very accurate way of
          // calculating it, but the scroll position is not always available so we do it like that.
          listController.hasClients
              ? listController.position.maxScrollExtent
              : initialListHeight ?? (wheight * items.length),
        );

        if (widget.scrollOffset != null) {
          widget.scrollOffset!.value = targetOffset;
        } else {
          if (animated) {
            listController.animateTo(
              targetOffset,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeIn,
            );
          } else {
            listController.jumpTo(targetOffset);
          }
        }
      } catch (e, trace) {
        debugPrint("Error while scrolling to the current item: $e\n$trace");
      }
    }

    scrollToIndex(index, animated: true);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          // Only the page being looked at carries a hero. A PageView builds its
          // neighbours, and on a pop Flutter flies *every* hero whose tag
          // matches something in the list — so several images used to sail back
          // at once. The system back gesture makes it obvious, because it also
          // drags the PageView a little, leaving two pages partly on screen.
          var current = index;

          // Built once, outside the StatefulBuilder: rebuilding it on every
          // page change would hand the PageView a fresh controller and snap it
          // back to the page it started on.
          final pageController = PageController(initialPage: index);

          return StatefulBuilder(
            builder: (context, setPagerState) {
              return PageView.custom(
                physics: const BouncingScrollPhysics(),
                childrenDelegate: SliverChildBuilderDelegate((context, idx) {
                  if (idx >= items.length) {
                    return null;
                  }
                  if (items[idx] is Launch) {
                    return LaunchDetailsPage(
                      items[idx] as Launch,
                      heroPrefix: widget.heroPrefix,
                      heroEnabled: idx == current,
                    );
                  } else if (items[idx] is Event) {
                    return EventDetailsPage(
                      items[idx] as Event,
                      heroPrefix: widget.heroPrefix,
                      heroEnabled: idx == current,
                    );
                  } else {
                    throw Exception(
                      "Invalid data type ${items[idx].runtimeType} in launch/event pageview",
                    );
                  }
                }),
                controller: pageController,
                onPageChanged: (idx) async {
                  // Settles only once a swipe finishes, so a back gesture that
                  // merely nudges the PageView leaves the hero where it was.
                  setPagerState(() => current = idx);

                  // Always adjust the current scroll position of the list
                  scrollToIndex(idx);

                  // If we are close to the end of currently loaded events, we load the next ones
                  if (nextItemArg != null && idx > items.length - 10) {
                    await _loadMore();
                  }
                },
              );
            },
          );
        },
      ),
    );

    if (widget.refreshOnLeave) {
      await _updateItems(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // This list is only empty if we unsubscribed from the last launch/event
    if (items.isEmpty) {
      return Center(child: Text(widget.emptyText));
    }

    final columns = LaunchEventWidget.columnsForContext(context);

    final grid = InfiniteGridView(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisExtent: LaunchEventWidget.calculateHeight(
          context,
          columns: columns,
        ),
      ),
      hasNext: nextItemArg != null,
      nextData: _loadMore,
      loadingWidget: const PlanetLoadingAnimation(),
      physics: const BouncingScrollPhysics(),
      padding: bottomSystemBarPadding(context),
      controller: listController,
      itemCount: items.isEmpty ? 1 : items.length,
      // We pre-load up to 5 screens of info, that way images load already
      cacheExtent: MediaQuery.of(context).size.height * 5,
      itemBuilder: (context, index) {
        if (items.isEmpty) {
          return Center(child: Text(widget.emptyText));
        }
        final Widget childWidget;
        if (items[index] is Launch) {
          childWidget = LaunchWidget(
            items[index] as Launch,
            heroPrefix: widget.heroPrefix,
          );
        } else if (items[index] is Event) {
          childWidget = EventWidget(
            items[index] as Event,
            heroPrefix: widget.heroPrefix,
          );
        } else {
          throw Exception(
            "Invalid data type ${items[index].runtimeType} in launch/event listing",
          );
        }
        return GestureDetector(
          child: childWidget,
          onTap: () => _openItemDetails(context, index),
        );
      },
    );

    if (widget.nextFunc == null) {
      return grid;
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _updateItems(true);
      },
      child: grid,
    );
  }
}
