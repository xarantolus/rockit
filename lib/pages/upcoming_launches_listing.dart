import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rockit/apis/launch_library/api.dart';
import 'package:rockit/apis/launch_library/launch_response.dart';
import 'package:rockit/pages/addons/launch_event_listing.dart';

class UpcomingLaunchesPage extends StatefulWidget {
  UpcomingLaunchesPage({Key? key}) : super(key: key);

  final service = LaunchLibraryAPI();

  @override
  _UpcomingLaunchesPageState createState() => _UpcomingLaunchesPageState();
}

class _UpcomingLaunchesPageState extends State<UpcomingLaunchesPage> {
  static Future<UpcomingLaunchesResponse> load(
    BuildContext context,
    LaunchLibraryAPI api, [
    String? next,
  ]) async {
    try {
      var res = await api.upcomingLaunches(next);

      res.maybeShowSnack(context);

      return res.data;
    } catch (e) {
      debugPrint("Error loading launches: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.loadingFail),
        ),
      );

      return UpcomingLaunchesResponse(
        count: 0,
        next: next,
        previous: null,
        results: [],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LaunchEventListing<Launch, String>(
      nextFunc: (BuildContext context, nextItemArg, current) async {
        var next = await load(context, widget.service, nextItemArg);

        var newList = next.results ?? [];

        newList.removeWhere((newLaunch) => current.any((launch) => newLaunch.id == launch.id));

        current.addAll(newList);

        return NextFuncResult(current, next.next);
      },
      emptyText: AppLocalizations.of(context)!.noLaunches,
    );
  }
}
