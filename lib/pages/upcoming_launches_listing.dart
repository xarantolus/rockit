import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:infinite_widgets/infinite_widgets.dart';
import 'package:rockit/apis/launch_library/api.dart';
import 'package:rockit/apis/launch_library/upcoming_response.dart';
import 'package:rockit/pages/launch_details.dart';
import 'package:rockit/widgets/addons/planet_loading_animation.dart';
import 'package:rockit/widgets/launch.dart';

class UpcomingLaunchesPage extends StatefulWidget {
  UpcomingLaunchesPage({Key? key}) : super(key: key);

  final service = LaunchLibraryAPI();

  @override
  _UpcomingLaunchesPageState createState() => _UpcomingLaunchesPageState();
}

class _UpcomingLaunchesPageState extends State<UpcomingLaunchesPage>
    with AutomaticKeepAliveClientMixin {
  // Make sure this page is cached, else it would reload often when switching between tabs
  @override
  bool get wantKeepAlive => true;

  static Future<UpcomingResponse> load(
    BuildContext context,
    LaunchLibraryAPI api, [
    String? next,
  ]) async {
    try {
      var res = await api.upcomingLaunches(next);

      res.maybeShowSnack(context);

      return res.data;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error loading launches: $e");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.loadingFail),
        ),
      );

      return UpcomingResponse(
        count: 0,
        next: next,
        previous: null,
        results: [],
      );
    }
  }

  late Future<UpcomingResponse> upcomingLaunchesFuture =
      load(context, widget.service);

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Center(
      child: FutureBuilder<UpcomingResponse>(
        future: upcomingLaunchesFuture,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return const PlanetLoadingAnimation();
            default:
              if (snapshot.hasError) {
                return GestureDetector(
                  child: ErrorWidget(
                      "${snapshot.error!}\n${AppLocalizations.of(context)!.tapToTryAgain}"),
                  onTap: () => setState(() {
                    upcomingLaunchesFuture = load(context, widget.service);
                  }),
                );
              } else {
                final results = snapshot.data!.results;
                if (results?.isEmpty ?? true) {
                  return Center(
                    child: Text(AppLocalizations.of(context)!.noLaunches),
                  );
                } else {
                  return LaunchesList(
                    results!,
                    snapshot.data!.next,
                    widget.service,
                  );
                }
              }
          }
        },
      ),
    );
  }
}

class LaunchesList extends StatefulWidget {
  const LaunchesList(this.initialLaunches, this.initialNextURL, this.service,
      {Key? key})
      : super(key: key);

  final LaunchLibraryAPI service;

  final List<Launch> initialLaunches;
  final String? initialNextURL;

  @override
  _LaunchesListState createState() => _LaunchesListState();
}

class _LaunchesListState extends State<LaunchesList> {
  late List<Launch> launches = widget.initialLaunches;
  late String? nextURL = widget.initialNextURL;

  bool _currentlyLoading = false;

  Future<bool> _updateLaunches([bool? refresh]) async {
    if (_currentlyLoading) {
      return true;
    }
    _currentlyLoading = true;

    Object? error;

    List<Launch> newList = [];
    try {
      var _nextURL = refresh == true ? null : nextURL;

      var _newLaunches = await _UpcomingLaunchesPageState.load(
        context,
        widget.service,
        _nextURL,
      );

      newList = _newLaunches.results ?? [];

      setState(() {
        // Refresh? => replace
        if (refresh == true) {
          launches = newList;
        } else {
          // When we cache responses, it can happen that a page further down the
          // list has been cached, but contains launches that were on the previous (non-cached)
          // page. By removing all known launches, we make sure this doesn't show up in the UI
          newList.removeWhere((newLaunch) =>
              launches.any((launch) => newLaunch.id == launch.id));

          launches.addAll(newList);
        }

        nextURL = _newLaunches.next;
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

  Future<bool> _loadMore() async {
    try {
      return await _updateLaunches(false);
    } catch (_) {
      return false;
    }
  }

  void _openLaunchDetails(BuildContext context, int index) async {
    void scrollToIndex(int idx, [bool animated = false]) {
      // Scroll the list view to the currently viewed launch. If the user now leaves this view
      // the list will have scrolled to the last viewed item, which is nice
      final wheight = LaunchWidget.calculateHeight(context);
      final isLandscape =
          MediaQuery.of(context).orientation == Orientation.landscape;
      final targetOffset = max(
          wheight * (isLandscape ? idx / 2 : idx) -
              (isLandscape && idx % 2 == 0 ? 0 : wheight) / 2,
          0.0);

      if (animated) {
        _launchListController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeIn,
        );
      } else {
        _launchListController.jumpTo(targetOffset);
      }
    }

    scrollToIndex(index, true);

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
                if (idx >= launches.length) {
                  return null;
                }
                return LaunchDetailsPage(launches[idx]);
              },
            ),
            controller: pc,
            onPageChanged: (idx) async {
              // If we are close to the end of currently loaded launches, we load the next ones
              if (nextURL != null && idx > launches.length - 10) {
                await _loadMore();
              }

              // Always adjust the current scroll position of the list
              scrollToIndex(idx);
            },
          );

          return pv;
        },
      ),
    );
  }

  final ScrollController _launchListController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await _updateLaunches(true);
      },
      child: InfiniteGridView(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:
              MediaQuery.of(context).orientation == Orientation.landscape
                  ? 2
                  : 1,
          mainAxisExtent: LaunchWidget.calculateHeight(context),
        ),
        hasNext: nextURL != null,
        nextData: _loadMore,
        loadingWidget: const PlanetLoadingAnimation(),
        physics: const BouncingScrollPhysics(),
        controller: _launchListController,
        itemCount: launches.length,
        // We pre-load up to 5 screens of info, that way images load already
        cacheExtent: MediaQuery.of(context).size.height * 5,
        itemBuilder: (context, index) {
          return GestureDetector(
            child: LaunchWidget(launches[index]),
            onTap: () => _openLaunchDetails(context, index),
          );
        },
      ),
    );
  }
}
