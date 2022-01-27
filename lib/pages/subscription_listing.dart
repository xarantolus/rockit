import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rockit/apis/launch_library/api.dart';
import 'package:rockit/apis/launch_library/events_response.dart';
import 'package:rockit/apis/launch_library/upcoming_response.dart';
import 'package:rockit/background/handler.dart';
import 'package:rockit/pages/addons/launch_event_listing.dart';
import 'package:rockit/widgets/addons/app_bar.dart';

class SubscriptionListingPage extends StatefulWidget {
  const SubscriptionListingPage({Key? key}) : super(key: key);

  @override
  State<SubscriptionListingPage> createState() => _SubscriptionListingPageState();
}

class LaunchEventList {
  List<dynamic> list;
  LaunchEventList(this.list);
}

class _SubscriptionListingPageState extends State<SubscriptionListingPage> {
  Future<LaunchEventList> loadLaunchesAndEvents() async {
    final subscriptionManager = BackgroundHandler();

    final launchIDs = await subscriptionManager.loadSubscribedLaunchIDs();
    final eventIDs = await subscriptionManager.loadSubscribedEventIDs();

    final api = LaunchLibraryAPI();

    var list = [];
    bool hadErrors = false;

    for (var launchID in launchIDs) {
      try {
        list.add((await api.launch(launchID, true)).data);
      } catch (err) {
        debugPrint("Error loading launch with id $launchID: $err");
        hadErrors = true;
      }
    }
    for (var eventID in eventIDs) {
      try {
        list.add((await api.event(eventID, true)).data);
      } catch (err) {
        debugPrint("Error loading event with id $eventID: $err");
        hadErrors = true;
      }
    }

    // Now sort the list by the expected date

    DateTime? getDate(dynamic d) {
      if (d is Launch) {
        return DateTime.tryParse(d.net ?? d.windowStart ?? "")?.toLocal();
      }

      return (d as Event).date;
    }

    list.sort((a, b) {
      final ad = getDate(a);
      final bd = getDate(b);
      if (ad == null || bd == null) {
        return 0;
      }
      return ad.compareTo(bd);
    });

    if (hadErrors) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Text(AppLocalizations.of(context)!.errorLoadSubscriptions),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(AppLocalizations.of(context)!.ok),
              ),
            ],
          );
        },
      );
    }

    return LaunchEventList(list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.create(
        context,
        title: AppLocalizations.of(context)!.subscriptions,
      ),
      body: LaunchEventListing<dynamic, String>(
        refreshOnLeave: true,
        emptyText: AppLocalizations.of(context)!.noSubscriptions,
        nextFunc: (context, nextItemArg, current) async {
          var items = await loadLaunchesAndEvents();

          return NextFuncResult(items.list, null);
        },
      ),
    );
  }
}
