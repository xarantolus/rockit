import 'package:flutter/material.dart';
import 'package:rockit/l10n/app_localizations.dart';
import 'package:rockit/apis/launch_library/api.dart';
import 'package:rockit/background/handler.dart';
import 'package:rockit/pages/addons/launch_event_listing.dart';
import 'package:rockit/util/failure_reporter.dart';
import 'package:rockit/widgets/addons/app_bar.dart';
import 'package:rockit/widgets/addons/sort.dart';

class SubscriptionListingPage extends StatefulWidget {
  const SubscriptionListingPage({super.key});

  @override
  State<SubscriptionListingPage> createState() =>
      _SubscriptionListingPageState();
}

class _SubscriptionListingPageState extends State<SubscriptionListingPage> {
  final _reporter = FailureReporter();

  /// Mentions failures the user has not been told about yet, and stays quiet
  /// about the ones they have. A snackbar, not a dialog — whatever did load is
  /// already on screen.
  void _reportFailures(Set<String> failed) {
    if (_reporter.take(failed).isEmpty || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.errorLoadSubscriptions),
      ),
    );
  }

  Future<List<dynamic>> loadLaunchesAndEvents() async {
    final subscriptionManager = BackgroundHandler();

    final launchIDs = await subscriptionManager.loadSubscribedLaunchIDs();
    final eventIDs = await subscriptionManager.loadSubscribedEventIDs();

    final api = LaunchLibraryAPI();

    final failed = <String>{};

    // In parallel, not in turn: anything from a recent listing answers from
    // the cache at once, and the rest is a ten-second request each.
    Future<Object?> load(String id, Future<Object?> Function() fetch) async {
      try {
        return await fetch();
      } catch (err) {
        debugPrint("Error loading subscription $id: $err");
        failed.add(id);

        return null;
      }
    }

    List<dynamic> list = (await Future.wait([
      ...launchIDs.map(
        (id) =>
            load("launch:$id", () async => (await api.launch(id, true)).data),
      ),
      ...eventIDs.map(
        (id) => load(
          "event:$id",
          () async => (await api.event(int.parse(id), true)).data,
        ),
      ),
    ])).where((item) => item != null).toList();

    _reportFailures(failed);

    return sortLaunchesAndEvents(list);
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
          return NextFuncResult(await loadLaunchesAndEvents(), null);
        },
      ),
    );
  }
}
