import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rockit/l10n/app_localizations.dart';
import 'package:rockit/apis/launch_library/api.dart';
import 'package:rockit/apis/launch_library/launch_response.dart';
import 'package:rockit/apis/paging.dart';
import 'package:rockit/background/home_screen_widget.dart';
import 'package:rockit/pages/addons/launch_event_listing.dart';

class UpcomingLaunchesPage extends StatelessWidget {
  UpcomingLaunchesPage({required this.tabIndex, super.key});

  /// Which destination in the bottom bar shows this page, so re-tapping it
  /// scrolls this list back to the top.
  final int tabIndex;

  final service = LaunchLibraryAPI();

  @override
  Widget build(BuildContext context) {
    return LaunchEventListing<Launch, String>(
      cachedFunc: () async {
        final cached = await service.cachedUpcomingLaunches();
        if (cached == null) {
          return null;
        }

        return NextFuncResult(cached.results, cached.next);
      },
      nextFunc: (nextItemArg, current) async {
        final res = await service.upcomingLaunches(next: nextItemArg);

        // This listing is where the home-screen widget's rows come from, and
        // startup writes the widget before the first one has arrived — so on a
        // fresh install it would otherwise say "nothing upcoming" until an
        // hourly job got round to it. Only the first page: a later page adds
        // nothing the widget shows. Cache-only, so it costs no request.
        if (nextItemArg == null) {
          unawaited(refreshHomeWidget());
        }

        return NextFuncResult(
          mergePages(current, res.data.results, (launch) => launch.id),
          res.data.next,
          notice: res.error,
        );
      },
      tabIndex: tabIndex,
      emptyText: AppLocalizations.of(context)!.noLaunches,
    );
  }
}
