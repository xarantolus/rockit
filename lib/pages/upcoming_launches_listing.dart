import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:loadmore/loadmore.dart';
import 'package:rockit/apis/launch_library/api.dart';
import 'package:rockit/apis/launch_library/upcoming_response.dart';
import 'package:rockit/pages/launch_details.dart';
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Center(
      child: FutureBuilder<UpcomingResponse>(
        future: widget.service.upcomingLaunches(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
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
          } else if (snapshot.hasError) {
            return GestureDetector(
              child: ErrorWidget(
                  "${snapshot.error!}\n${AppLocalizations.of(context)!.tapToTryAgain}"),
              onTap: () => setState(() {}),
            );
          } else {
            return const CircularProgressIndicator();
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

    var error;

    List<Launch> newList = [];
    try {
      var _nextURL = refresh == true ? null : nextURL;

      var _newLaunches = await widget.service.upcomingLaunches(_nextURL);

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
      _currentlyLoading = false;
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

  String _buildLoadingText(LoadMoreStatus status) {
    switch (status) {
      case LoadMoreStatus.fail:
        return AppLocalizations.of(context)!.loadingLaunchFail;
      case LoadMoreStatus.idle:
        return AppLocalizations.of(context)!.loadingLaunchIdle;
      case LoadMoreStatus.loading:
        return AppLocalizations.of(context)!.loadingLaunchLoading;
      case LoadMoreStatus.nomore:
        return AppLocalizations.of(context)!.loadingLaunchNoMore;
      default:
        return AppLocalizations.of(context)!.unknown;
    }
  }

  void _openLaunchDetails(BuildContext context, int index) async {
    void scrollToIndex(int idx, [bool animated = false]) {
      // Scroll the list view to the currently viewed launch. If the user now leaves this view
      // the list will have scrolled to the last viewed item, which is nice
      final wheight = LaunchWidget.calculateHeight(context);
      final targetOffset = wheight * idx - wheight / 2;

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
      child: LoadMore(
        isFinish: nextURL == null,
        onLoadMore: _loadMore,
        child: ListView.builder(
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
        textBuilder: _buildLoadingText,
      ),
    );
  }
}
