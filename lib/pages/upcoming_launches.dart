import 'package:flutter/material.dart';
import 'package:rockit/launch_library/api.dart';
import 'package:rockit/launch_library/json_convert.dart';
import 'package:rockit/widgets/launch.dart';
import 'package:loadmore/loadmore.dart';

class UpcomingLaunchesPage extends StatefulWidget {
  UpcomingLaunchesPage({Key? key}) : super(key: key);

  final service = LaunchLibraryAPI();

  @override
  _UpcomingLaunchesPageState createState() => _UpcomingLaunchesPageState();
}

class _UpcomingLaunchesPageState extends State<UpcomingLaunchesPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<UpcomingResponse>(
        future: widget.service.upcomingLaunches(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final results = snapshot.data!.results;
            if (results?.isEmpty ?? true) {
              return const Center(
                child: Text("There are no items"),
              );
            } else {
              return LaunchesList(
                results!,
                snapshot.data!.next,
                widget.service,
              );
            }
          } else if (snapshot.hasError) {
            return ErrorWidget(snapshot.error!);
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

  Future<void> _updateLaunches([bool? refresh]) async {
    var _launches = launches;

    var _nextURL = nextURL;
    if (refresh == true) {
      _nextURL = null;
      _launches.clear();
    }

    var _newLaunches = await widget.service.upcomingLaunches(_nextURL);

    _launches.addAll(_newLaunches.results ?? []);

    setState(() {
      launches = _launches;
      nextURL = _newLaunches.next;
    });
  }

  bool loadingMore = false;

  Future<bool> _loadMore() async {
    try {
      await _updateLaunches(false);
    } catch (_) {
      return false;
    }
    return true;
  }

  String _buildLoadingText(LoadMoreStatus status) =>
      const {
        LoadMoreStatus.fail: "Failed to load. Tap to try again.",
        LoadMoreStatus.idle: "Waiting...",
        LoadMoreStatus.loading: "Loading more launches...",
        LoadMoreStatus.nomore: "You've reached the end of the list.",
      }[status] ??
      "Unknown";

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
          itemCount: launches.length,
          cacheExtent: MediaQuery.of(context).size.height * 5,
          itemBuilder: (context, index) {
            return LaunchWidget(launches[index]);
          },
        ),
        textBuilder: _buildLoadingText,
      ),
    );
  }
}
