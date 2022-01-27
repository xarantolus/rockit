import 'dart:core';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:infinite_widgets/infinite_widgets.dart';
import 'package:rockit/apis/launch_library/events_response.dart';
import 'package:rockit/apis/launch_library/upcoming_response.dart';
import 'package:rockit/pages/event_details.dart';
import 'package:rockit/pages/launch_details.dart';
import 'package:rockit/widgets/addons/planet_loading_animation.dart';
import 'package:rockit/widgets/event.dart';
import 'package:rockit/widgets/launch.dart';

class NextFuncResult<I, S> {
  S? nextArg;

  List<I> items;

  NextFuncResult(this.items, this.nextArg);
}

class LaunchEventListing<I, N> extends StatefulWidget {
  const LaunchEventListing({
    this.initialItems,
    this.nextFunc,
    this.initialNextItemArg,
    required this.emptyText,
    this.refreshOnLeave = false,
    Key? key,
  })  : assert(initialItems == null || nextFunc == null),
        assert(initialItems != null || nextFunc != null),
        super(key: key);

  // Either initialItems OR nextFunc must be given
  final List<I>? initialItems;
  final Future<NextFuncResult<I, N>> Function(BuildContext context, N? nextItemArg, List<I> current)? nextFunc;

  final N? initialNextItemArg;

  final String emptyText;

  final bool refreshOnLeave;

  Future<NextFuncResult<I, N>> loadItems(BuildContext context, N? nextItemArg, List<I> current) async {
    if (initialItems != null) {
      return NextFuncResult<I, N>(initialItems!, null);
    }
    return nextFunc!(context, nextItemArg, current);
  }

  @override
  State<LaunchEventListing<I, N>> createState() => _LaunchEventListingState<I, N>();
}

class _LaunchEventListingState<I, N> extends State<LaunchEventListing<I, N>> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late Future<NextFuncResult<I, N>> ftr = widget.loadItems(context, null, []);

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Center(
      child: FutureBuilder<NextFuncResult<I, N>>(
        future: ftr,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return const PlanetLoadingAnimation();
            default:
              if (snapshot.hasError) {
                return GestureDetector(
                  child: ErrorWidget("${snapshot.error!}\n${AppLocalizations.of(context)!.tapToTryAgain}"),
                  onTap: () => setState(() {
                    ftr = widget.loadItems(context, null, []);
                  }),
                );
              } else {
                final results = snapshot.data!;
                if (results.items.isEmpty) {
                  return Center(
                    child: Text(widget.emptyText),
                  );
                } else {
                  return ItemList(
                    results,
                    widget.nextFunc,
                    widget.refreshOnLeave,
                    widget.emptyText,
                  );
                }
              }
          }
        },
      ),
    );
  }
}

class ItemList<I, N> extends StatefulWidget {
  ItemList(this.initial, this.nextFunc, this.refreshOnLeave, this.emptyText, {Key? key}) : super(key: key);

  NextFuncResult<I, N> initial;

  final bool refreshOnLeave;
  final String emptyText;

  final Future<NextFuncResult<I, N>> Function(BuildContext context, N? nextItemArg, List<I> current)? nextFunc;

  @override
  State<ItemList<I, N>> createState() => _ItemListState<I, N>();
}

class _ItemListState<I, N> extends State<ItemList<I, N>> {
  late List<I> items = widget.initial.items;
  late N? nextItemArg = widget.initial.nextArg;

  bool _currentlyLoading = false;

  final ScrollController listController = ScrollController();

  Future<bool> _updateItems([bool? refresh]) async {
    if (_currentlyLoading) {
      return true;
    }
    _currentlyLoading = true;

    Object? error;

    try {
      var _nextURL = refresh == true ? null : nextItemArg;

      var _newItems = await widget.nextFunc!(
        context,
        _nextURL,
        refresh == true ? [] : items,
      );

      setState(() {
        // Refresh? => replace
        items = _newItems.items;
        nextItemArg = _newItems.nextArg;
      });
    } catch (e) {
      error = e;
    } finally {
      setState(() {
        _currentlyLoading = false;
      });
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
    void scrollToIndex(int idx, {bool animated = false}) {
      // Scroll the list view to the currently viewed launch. If the user now leaves this view
      // the list will have scrolled to the last viewed item, which is nice

      // This is also the wrong calculation
      final wheight = LaunchWidget.calculateHeight(context);
      final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
      final targetOffset = min(
        max(
          wheight * (isLandscape ? idx / 2 : idx) - (isLandscape && idx % 2 == 0 ? 0 : wheight) / 2,
          0.0,
        ),
        // Do not scroll further than the list height
        listController.position.maxScrollExtent,
      );

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

    scrollToIndex(index, animated: true);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          var pc = PageController(
            initialPage: index,
            // Prevent pages from being cached, else we would sometimes have
            // two hero animations going back to the list, which is really ugly
            keepPage: false,
          );

          var pv = PageView.custom(
            physics: const BouncingScrollPhysics(),
            childrenDelegate: SliverChildBuilderDelegate(
              (context, idx) {
                if (idx >= items.length) {
                  return null;
                }
                if (items[idx] is Launch) {
                  return LaunchDetailsPage(items[idx] as Launch);
                } else if (items[idx] is Event) {
                  return EventDetailsPage(items[idx] as Event);
                } else {
                  throw Exception("Invalid data type ${items[idx].runtimeType} in launch/event pageview");
                }
              },
            ),
            controller: pc,
            onPageChanged: (idx) async {
              // Always adjust the current scroll position of the list
              scrollToIndex(idx);

              // If we are close to the end of currently loaded events, we load the next ones
              if (nextItemArg != null && idx > items.length - 10) {
                await _loadMore();
              }
            },
          );

          return pv;
        },
      ),
    );

    if (widget.refreshOnLeave) {
      await _updateItems(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await _updateItems(true);
      },
      child: InfiniteGridView(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).orientation == Orientation.landscape ? 2 : 1,
          // TODO: Use the correct widget to calculate height?
          mainAxisExtent: LaunchWidget.calculateHeight(context),
        ),
        hasNext: nextItemArg != null,
        nextData: _loadMore,
        loadingWidget: const PlanetLoadingAnimation(),
        physics: const BouncingScrollPhysics(),
        controller: listController,
        itemCount: items.isEmpty ? 1 : items.length,
        // We pre-load up to 5 screens of info, that way images load already
        cacheExtent: MediaQuery.of(context).size.height * 5,
        itemBuilder: (context, index) {
          if (items.isEmpty) {
            return Center(
              child: Text(widget.emptyText),
            );
          }
          final Widget childWidget;
          if (items[index] is Launch) {
            childWidget = LaunchWidget(items[index] as Launch);
          } else if (items[index] is Event) {
            childWidget = EventWidget(items[index] as Event);
          } else {
            throw Exception("Invalid data type ${items[index].runtimeType} in launch/event listing");
          }
          return GestureDetector(
            child: childWidget,
            onTap: () => _openItemDetails(context, index),
          );
        },
      ),
    );
  }
}
