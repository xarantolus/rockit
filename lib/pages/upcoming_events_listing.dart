import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rockit/l10n/app_localizations.dart';
import 'package:rockit/apis/launch_library/api.dart';
import 'package:rockit/apis/launch_library/events_response.dart';
import 'package:rockit/apis/paging.dart';
import 'package:rockit/background/home_screen_widget.dart';
import 'package:rockit/pages/addons/launch_event_listing.dart';

class UpcomingEventsPage extends StatelessWidget {
  UpcomingEventsPage({required this.tabIndex, super.key});

  /// Which destination in the bottom bar shows this page, so re-tapping it
  /// scrolls this list back to the top.
  final int tabIndex;

  final service = LaunchLibraryAPI();

  @override
  Widget build(BuildContext context) {
    return LaunchEventListing<Event, String>(
      cachedFunc: () async {
        final cached = await service.cachedUpcomingEvents();
        if (cached == null) {
          return null;
        }

        return NextFuncResult(cached.results, cached.next);
      },
      nextFunc: (nextItemArg, current) async {
        final res = await service.upcomingEvents(next: nextItemArg);

        // Subscribed events are resolved out of the per-event cache this
        // listing seeds, so the widget can only show them once it has landed.
        if (nextItemArg == null) {
          unawaited(refreshHomeWidget());
        }

        return NextFuncResult(
          mergePages(current, res.data.results, (event) => event.id),
          res.data.next,
          notice: res.error,
        );
      },
      tabIndex: tabIndex,
      emptyText: AppLocalizations.of(context)!.noEvents,
    );
  }
}
