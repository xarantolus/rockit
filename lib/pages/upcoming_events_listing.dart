import 'package:flutter/material.dart';
import 'package:rockit/l10n/app_localizations.dart';
import 'package:rockit/apis/launch_library/api.dart';
import 'package:rockit/apis/launch_library/events_response.dart';
import 'package:rockit/apis/paging.dart';
import 'package:rockit/pages/addons/launch_event_listing.dart';

class UpcomingEventsPage extends StatefulWidget {
  UpcomingEventsPage({super.key});

  final service = LaunchLibraryAPI();

  @override
  State<UpcomingEventsPage> createState() => _UpcomingEventsPageState();
}

class _UpcomingEventsPageState extends State<UpcomingEventsPage> {
  @override
  Widget build(BuildContext context) {
    return LaunchEventListing<Event, String>(
      cachedFunc: () async {
        final cached = await widget.service.cachedUpcomingEvents();
        if (cached == null) {
          return null;
        }

        return NextFuncResult(cached.results, cached.next);
      },
      nextFunc: (nextItemArg, current) async {
        final res = await widget.service.upcomingEvents(next: nextItemArg);

        return NextFuncResult(
          mergePages(current, res.data.results, (event) => event.id),
          res.data.next,
          notice: res.error,
        );
      },
      emptyText: AppLocalizations.of(context)!.noEvents,
    );
  }
}
