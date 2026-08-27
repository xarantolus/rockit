import 'package:flutter/material.dart';
import 'package:rockit/l10n/app_localizations.dart';
import 'package:rockit/apis/launch_library/api.dart';
import 'package:rockit/apis/launch_library/launch_response.dart';
import 'package:rockit/apis/paging.dart';
import 'package:rockit/pages/addons/launch_event_listing.dart';

class UpcomingLaunchesPage extends StatefulWidget {
  UpcomingLaunchesPage({super.key});

  final service = LaunchLibraryAPI();

  @override
  State<UpcomingLaunchesPage> createState() => _UpcomingLaunchesPageState();
}

class _UpcomingLaunchesPageState extends State<UpcomingLaunchesPage> {
  @override
  Widget build(BuildContext context) {
    return LaunchEventListing<Launch, String>(
      cachedFunc: () async {
        final cached = await widget.service.cachedUpcomingLaunches();
        if (cached == null) {
          return null;
        }

        return NextFuncResult(cached.results ?? [], cached.next);
      },
      nextFunc: (nextItemArg, current) async {
        final res = await widget.service.upcomingLaunches(next: nextItemArg);

        return NextFuncResult(
          mergePages(current, res.data.results ?? [], (launch) => launch.id),
          res.data.next,
          notice: res.error,
        );
      },
      emptyText: AppLocalizations.of(context)!.noLaunches,
    );
  }
}
