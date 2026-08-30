import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rockit/l10n/app_localizations.dart';
import 'package:rockit/pages/keywords_page.dart';
import 'package:rockit/apis/launch_library/api.dart';
import 'package:rockit/apis/launch_library/api_issue.dart';
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
  /// Says *why*, when the API can tell us.
  ///
  /// "Come back later" on its own is the least useful half of the message: the
  /// hourly limit is invisible to anyone who does not know the API has one, so
  /// it reads as their connection being bad. A limit names itself and says
  /// when it clears; anything else keeps the general wording, because a
  /// subscription can also fail on its own.
  Future<void> _reportFailures(Set<String> failed) async {
    if (_reporter.take(failed).isEmpty) {
      return;
    }

    final issue = await diagnoseApiFailure();

    if (!mounted) {
      return;
    }

    final localizations = AppLocalizations.of(context)!;
    final minutes = issue.retryIn?.inMinutes;

    final text = switch (issue.kind) {
      ApiIssue.rateLimited when minutes != null =>
        localizations.apiLimitReachedIn(minutes),
      ApiIssue.rateLimited => localizations.apiLimitReached,
      _ => localizations.errorLoadSubscriptions,
    };

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<List<dynamic>> loadLaunchesAndEvents() async {
    final subscriptionManager = BackgroundHandler();

    final launchIDs = await subscriptionManager.loadSubscribedLaunchIDs();
    final eventIDs = await subscriptionManager.loadSubscribedEventIDs();

    final api = LaunchLibraryAPI();
    final found = <dynamic>[];
    final failed = <String>{};

    // Whatever is already stored costs nothing, so take that first and only
    // ask for the rest. A launch seen in a recent listing was seeded under its
    // own URL and is free; one that has already flown was not, because the
    // listings start at yesterday.
    final missingLaunches = <String>[];
    for (final id in launchIDs) {
      final cached = await api.cachedLaunch(id);
      cached == null ? missingLaunches.add(id) : found.add(cached);
    }

    final missingEvents = <int>[];
    for (final id in eventIDs) {
      final parsed = int.tryParse(id);
      if (parsed == null) {
        continue;
      }

      final cached = await api.cachedEvent(parsed);
      cached == null ? missingEvents.add(parsed) : found.add(cached);
    }

    // One request for all the missing launches and one for all the missing
    // events, rather than one apiece. This used to be a request per
    // subscription: five of them was a third of the hourly budget, every time
    // the page was opened.
    if (missingLaunches.isNotEmpty) {
      try {
        final fetched = await api.launchesByIds(missingLaunches);
        found.addAll(fetched);

        final seen = fetched.map((l) => l.id).toSet();
        failed.addAll(
          missingLaunches
              .where((id) => !seen.contains(id))
              .map((id) => "launch:$id"),
        );
      } catch (err) {
        debugPrint("Error loading subscribed launches: $err");
        failed.addAll(missingLaunches.map((id) => "launch:$id"));
      }
    }

    if (missingEvents.isNotEmpty) {
      try {
        final fetched = await api.eventsByIds(missingEvents);
        found.addAll(fetched);

        final seen = fetched.map((e) => e.id).toSet();
        failed.addAll(
          missingEvents
              .where((id) => !seen.contains(id))
              .map((id) => "event:$id"),
        );
      } catch (err) {
        debugPrint("Error loading subscribed events: $err");
        failed.addAll(missingEvents.map((id) => "event:$id"));
      }
    }

    unawaited(_reportFailures(failed));

    return sortLaunchesAndEvents(found);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const KeywordsPage()));

          // Adding a keyword can subscribe to things, so the list behind it is
          // out of date on the way back.
          if (mounted) {
            setState(() {});
          }
        },
        tooltip: AppLocalizations.of(context)!.keywords,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(
          Icons.notifications_active_outlined,
          color: Colors.white,
        ),
      ),
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
