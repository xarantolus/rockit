import 'package:flutter/material.dart';
import 'package:rockit/launch_library/api.dart';
import 'package:rockit/launch_library/json_convert.dart';
import 'package:rockit/pages/launch_details.dart';
import 'package:rockit/widgets/launch.dart';
import 'package:loadmore/loadmore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

  Future<bool> _updateLaunches([bool? refresh]) async {
    var _nextURL = refresh == true ? null : nextURL;

    var _newLaunches = await widget.service.upcomingLaunches(_nextURL);

    final newList = _newLaunches.results ?? [];

    setState(() {
      // Refresh? => replace
      if (refresh == true) {
        launches = newList;
      } else {
        launches.addAll(newList);
      }

      nextURL = _newLaunches.next;
    });

    return newList.isNotEmpty;
  }

  Future<bool> _loadMore() async {
    return await _updateLaunches(false);
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
            return GestureDetector(
              child: LaunchWidget(launches[index]),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => LaunchDetailsPage(launches[index]),
                  ),
                );
              },
            );
          },
        ),
        textBuilder: _buildLoadingText,
      ),
    );
  }
}
