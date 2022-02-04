import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rockit/apis/launch_library/api.dart';
import 'package:rockit/apis/launch_library/events_response.dart';
import 'package:rockit/pages/addons/launch_event_listing.dart';

class UpcomingEventsPage extends StatefulWidget {
  UpcomingEventsPage({Key? key}) : super(key: key);

  final service = LaunchLibraryAPI();

  @override
  _UpcomingEventsPageState createState() => _UpcomingEventsPageState();
}

class _UpcomingEventsPageState extends State<UpcomingEventsPage> {
  static Future<UpcomingEventsResponse> load(
    BuildContext context,
    LaunchLibraryAPI api, [
    String? next,
  ]) async {
    try {
      var res = await api.upcomingEvents(next: next);

      res.maybeShowSnack(context);

      return res.data;
    } catch (e) {
      debugPrint("Error loading events: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.loadingFail),
        ),
      );

      return UpcomingEventsResponse(
        count: 0,
        next: next,
        previous: null,
        results: [],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LaunchEventListing<Event, String>(
      nextFunc: (BuildContext context, nextItemArg, current) async {
        var next = await load(context, widget.service, nextItemArg);

        var newList = next.results ?? [];

        newList.removeWhere((newEvent) => current.any((event) => newEvent.id == event.id));

        current.addAll(newList);

        return NextFuncResult(current, next.next);
      },
      emptyText: AppLocalizations.of(context)!.noEvents,
    );
  }
}
