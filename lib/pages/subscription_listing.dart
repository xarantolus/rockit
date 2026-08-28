import 'package:flutter/material.dart';
import 'package:rockit/l10n/app_localizations.dart';
import 'package:rockit/apis/launch_library/api.dart';
import 'package:rockit/background/handler.dart';
import 'package:rockit/pages/addons/launch_event_listing.dart';
import 'package:rockit/widgets/addons/app_bar.dart';
import 'package:rockit/widgets/addons/sort.dart';

class SubscriptionListingPage extends StatefulWidget {
  const SubscriptionListingPage({super.key});

  @override
  State<SubscriptionListingPage> createState() =>
      _SubscriptionListingPageState();
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

    bool hadErrors = false;

    // In parallel, not in turn. Anything seen in a recent listing is already
    // filed under its own URL and answers from the cache immediately; whatever
    // is left is a real request against an API that regularly takes ten
    // seconds, and adding those up was most of the wait here.
    Future<Object?> load(String what, Future<Object?> Function() fetch) async {
      try {
        return await fetch();
      } catch (err) {
        debugPrint("Error loading $what: $err");
        hadErrors = true;

        return null;
      }
    }

    List<dynamic> list = (await Future.wait([
      ...launchIDs.map(
        (id) =>
            load("launch $id", () async => (await api.launch(id, true)).data),
      ),
      ...eventIDs.map(
        (id) => load(
          "event $id",
          () async => (await api.event(int.parse(id), true)).data,
        ),
      ),
    ])).where((item) => item != null).toList();

    // Now sort the list by the expected date
    list = sortLaunchesAndEvents(list);

    // Loading can still take a while when nothing was cached, so the user may
    // well have left before this finishes.
    if (hadErrors && mounted) {
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
        heroPrefix: "subscription-",
        emptyText: AppLocalizations.of(context)!.noSubscriptions,
        nextFunc: (nextItemArg, current) async {
          var items = await loadLaunchesAndEvents();

          return NextFuncResult(items.list, null);
        },
      ),
    );
  }
}
