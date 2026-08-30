import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rockit/apis/error_details.dart';
import 'package:rockit/apis/paging.dart';
import 'package:rockit/apis/launch_library/api.dart';
import 'package:rockit/apis/launch_library/api_issue.dart';
import 'package:rockit/apis/launch_library/events_response.dart';
import 'package:rockit/apis/launch_library/launch_response.dart';
import 'package:rockit/l10n/app_localizations.dart';
import 'package:rockit/pages/addons/launch_event_listing.dart';
import 'package:rockit/util/keyboard.dart';
import 'package:rockit/widgets/addons/app_bar.dart';
import 'package:rockit/widgets/addons/planet_loading_animation.dart';
import 'package:rockit/widgets/addons/sort.dart';

class LaunchEventSearchDelegate extends SearchDelegate {
  LaunchEventSearchDelegate({
    required String searchLabel,
    required Color? searchTextColor,
  }) : super(
         searchFieldLabel: searchLabel,
         searchFieldStyle: TextStyle(color: searchTextColor),
       );

  /// Identity across both kinds, so a launch and an event cannot collide.
  static String _idOf(dynamic item) {
    if (item is Launch) return "launch:${item.id}";
    if (item is Event) return "event:${item.id}";

    return "other:${identityHashCode(item)}";
  }

  /// Everything searchable, rebuilt as pages arrive.
  final entries = ValueNotifier<List<_Entry>>([]);

  /// True while pages are still being fetched, so the results can say so
  /// rather than looking simply incomplete.
  final completing = ValueNotifier<bool>(false);

  /// Why the index could not be finished, if it could not.
  ///
  /// Kept apart from [completing] because an empty list means something
  /// different in each case, and "no results" is an answer we have not earned
  /// in either. The two reasons are worth telling apart: nobody knows the
  /// launch API rations requests by the hour, so a limit we hit reads as their
  /// phone being offline unless it is named.
  final issue = ValueNotifier<({ApiIssue kind, Duration? retryIn})>((
    kind: ApiIssue.none,
    retryIn: null,
  ));

  /// Set when the user leaves. Pages already in flight will land and be
  /// cached, which is useful, but nothing new is requested for a screen that
  /// is gone — those are requests out of fifteen an hour.
  bool _closed = false;

  @override
  void close(BuildContext context, dynamic result) {
    _closed = true;
    super.close(context, result);
  }

  /// At most this many requests to finish the index, whatever the budget says.
  ///
  /// The whole upcoming set is about three pages — 191 launches and 33 events
  /// against a page size of 100 — and page one of each is normally cached
  /// already, so this is a ceiling that is rarely reached rather than a crawl.
  static const _maxExtraPages = 3;

  /// Left unspent, so searching cannot consume the budget a detail page or a
  /// refresh needs straight afterwards.
  static const _reserve = 4;

  bool _indexing = false;

  /// Indexes the cached listing pages, then fetches whatever the cache was
  /// missing.
  ///
  /// The cache walk comes first and alone decides what is on screen initially:
  /// this used to page with `preferCache: true`, which falls through to the
  /// network on a *miss*, so opening search could spend most of the fifteen
  /// hourly requests before the field even appeared — measured at three
  /// requests and 21 seconds against the dev API. Fetching afterwards keeps
  /// that opening instant while still completing the index, because results
  /// stream into [entries] as they arrive.
  Future<void> indexPages() async {
    if (_indexing) {
      return;
    }

    _indexing = true;

    try {
      final api = LaunchLibraryAPI();
      final found = <dynamic>[];

      /// Offset paging over a list that moves underneath it repeats items: a
      /// launch inserted before the page boundary pushes the last entry of
      /// page one onto page two, and page one here is often cached from an
      /// earlier snapshot than page two was fetched in. The same `mergePages`
      /// the listings use, so there is one rule for it.
      void add(List<dynamic> items) => mergePages(found, items, _idOf);

      void publish() {
        entries.value = sortLaunchesAndEvents(
          List.of(found),
        ).map(_Entry.new).toList();
      }

      /// Reads cached pages until one is missing.
      ///
      /// `complete` and `from` are separate on purpose: a null `from` means
      /// "start at page one", which is exactly what an empty cache needs, and
      /// is not the same as having nothing left to do. Returning one nullable
      /// URL conflated the two, so a cold cache concluded it had already
      /// finished and fetched nothing at all.
      Future<({bool complete, String? from})> walkCache(
        Future<dynamic> Function(String? next) page,
      ) async {
        String? next;
        do {
          final resp = await page(next);
          if (resp == null) {
            return (complete: false, from: next);
          }

          add(resp.results as List<dynamic>);
          next = resp.next as String?;
          publish();
        } while (next != null);

        return (complete: true, from: null);
      }

      final launches = await walkCache(
        (next) => api.cachedUpcomingLaunches(next: next),
      );
      final events = await walkCache(
        (next) => api.cachedUpcomingEvents(next: next),
      );

      if (launches.complete && events.complete) {
        return;
      }

      final spendable = await _spendableRequests();
      var budget = spendable.budget;

      if (budget <= 0) {
        // Known to be short, rather than known to be empty.
        issue.value = (kind: spendable.issue, retryIn: spendable.retryIn);
        return;
      }

      completing.value = true;
      var trouble = (kind: ApiIssue.none, retryIn: null as Duration?);

      /// Continues a listing over the network, where a null `from` starts at
      /// page one.
      Future<void> fetchRest(
        ({bool complete, String? from}) resume,
        Future<ErrorDetails<dynamic>> Function(String? next) page,
      ) async {
        if (resume.complete) {
          return;
        }

        var next = resume.from;
        var more = true;

        while (more) {
          // Leaving is not a failure, so it says nothing to the user.
          if (_closed) {
            return;
          }

          if (budget <= 0) {
            trouble = await diagnoseApiFailure();
            return;
          }

          budget--;

          try {
            final resp = await page(next);
            final data = resp.data;
            if (data == null) {
              trouble = await diagnoseApiFailure();
              return;
            }

            add(data.results as List<dynamic>);
            next = data.next as String?;
            more = next != null;
            publish();
          } catch (e) {
            // A refused or failed request for a page nothing has cached throws
            // rather than degrading, and it must not read as "no results".
            debugPrint("Could not fetch a page for the search index: $e");
            trouble = await diagnoseApiFailure();
            return;
          }
        }
      }

      await fetchRest(launches, (next) => api.upcomingLaunches(next: next));
      await fetchRest(events, (next) => api.upcomingEvents(next: next));

      issue.value = trouble;
    } catch (e) {
      debugPrint("Error building the search index: $e");
      issue.value = (kind: ApiIssue.unreachable, retryIn: null);
    } finally {
      completing.value = false;
      _indexing = false;
    }
  }

  /// What may be spent on completing the index.
  ///
  /// A budget that cannot be read is treated as no budget rather than as
  /// plenty: `/api-throttle/` is free and answers even while everything else is
  /// being refused, so a failure to read it means the network is down, when
  /// fetching would not have worked anyway.
  Future<({int budget, ApiIssue issue, Duration? retryIn})>
  _spendableRequests() async {
    final throttle = await LaunchLibraryAPI().throttle();
    final remaining = throttle?.remaining;

    if (remaining == null) {
      return (budget: 0, issue: ApiIssue.unreachable, retryIn: null);
    }

    final budget = min(_maxExtraPages, remaining - _reserve);

    return (
      budget: budget,
      issue: budget <= 0 ? ApiIssue.rateLimited : ApiIssue.none,
      retryIn: throttle?.untilLimitClears,
    );
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    return Theme.of(context).copyWith(
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: Colors.white,
        selectionColor: Colors.white.withValues(alpha: .5),
        selectionHandleColor: colorScheme.secondary,
      ),
      hintColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        systemOverlayStyle: systemOverlayStyle(context),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.search, color: Colors.white),
        onPressed: () {
          showResults(context);
        },
        tooltip: AppLocalizations.of(context)!.showResults,
      ),
      IconButton(
        icon: const Icon(Icons.clear, color: Colors.white),
        onPressed: () {
          query = '';
          // `showSuggestions` asks the delegate's own field for focus, which it
          // already has, so nothing brings the keyboard back on its own.
          showSuggestions(context);
          showKeyboard();
        },
        tooltip: AppLocalizations.of(context)!.clearSearch,
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () {
        close(context, null);
      },
      tooltip: AppLocalizations.of(context)!.close,
    );
  }

  static final _bySpace = RegExp(r'\s+');

  List<_Entry> _matches(List<_Entry> all) {
    final term = query.toLowerCase().trim();
    if (term.isEmpty) {
      return all;
    }

    final terms = term.split(_bySpace);

    // Every term has to appear somewhere in the entry.
    return all
        .where((e) => terms.every((t) => e.haystack.contains(t)))
        .toList();
  }

  String lastTerm = "";

  late ValueNotifier<double> scrollOffset = ValueNotifier(0);

  @override
  Widget buildResults(BuildContext context) {
    if (lastTerm != query) {
      scrollOffset.value = 0;
    }
    lastTerm = query;

    return _whileIndexing(
      builder: (context, all, busy, why) {
        final matches = _matches(all).map((e) => e.item).toList();
        final short = why.kind != ApiIssue.none;

        // Nothing found *yet* is not the same as nothing to find, and neither
        // is nothing found *because the API refused*. "No results" is only
        // honest once the index is both finished and complete.
        if (matches.isEmpty) {
          if (busy) {
            return _stillLoading(context);
          }
          if (short) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _nothingLoadedReason(context, why),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
        }

        return Column(
          children: [
            // Above the list rather than over it: unlike the progress bar this
            // is not going away on its own, so it should take its own space.
            if (short && !busy) _incompleteNotice(context, why),
            Expanded(
              child: Stack(
                children: [
                  LaunchEventListing<dynamic, String>(
                    emptyText: AppLocalizations.of(context)!.emptyResults,
                    initialItems: matches,
                    scrollOffset: scrollOffset,
                    heroPrefix: "search-",
                  ),
                  // Over the results rather than replacing them: what is
                  // already indexed stays searchable while the rest arrives.
                  if (busy)
                    const Align(
                      alignment: Alignment.topCenter,
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  List<String> _searchSuggestions(List<_Entry> matches) {
    List<String?> launchFunction(Launch item) {
      return [
        if (item.launchServiceProvider?.name?.isNotEmpty ?? false)
          item.launchServiceProvider?.name,
        if (item.rocket?.configuration?.fullName?.isNotEmpty ?? false)
          item.rocket?.configuration?.fullName,
      ];
    }

    return matches
        .map((e) => e.item)
        .map((item) {
          // Check if it's a launch or an event
          if (item is Launch) {
            return [
              if (item.launchServiceProvider?.name?.isNotEmpty ?? false)
                item.launchServiceProvider?.name,
              if (item.rocket?.configuration?.fullName?.isNotEmpty ?? false)
                item.rocket?.configuration?.fullName,
            ];
          } else if (item is Event) {
            return [
              ...item.program.map((p) => p.name),
              ...item.launches.expand(launchFunction),
            ];
          } else {
            return [];
          }
        })
        .whereType<List<String?>>()
        .expand((e) => e)
        .whereType<String>()
        .where((e) => !e.toLowerCase().contains("unknown"))
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _whileIndexing(builder: _suggestionList);
  }

  /// Rebuilds on the index, on whether it is still filling and on whether it
  /// gave up, so every state below is decided in one place.
  Widget _whileIndexing({
    required Widget Function(
      BuildContext,
      List<_Entry>,
      bool,
      ({ApiIssue kind, Duration? retryIn}),
    )
    builder,
  }) {
    return ValueListenableBuilder(
      valueListenable: entries,
      builder: (context, all, _) => ValueListenableBuilder(
        valueListenable: completing,
        builder: (context, busy, _) => ValueListenableBuilder(
          valueListenable: issue,
          builder: (context, why, _) => builder(context, all, busy, why),
        ),
      ),
    );
  }

  /// Names the cause, because "some results are missing" on its own reads as a
  /// bad connection whichever it was.
  String _shortListReason(
    BuildContext context,
    ({ApiIssue kind, Duration? retryIn}) why,
  ) {
    final l = AppLocalizations.of(context)!;

    if (why.kind != ApiIssue.rateLimited) {
      return l.searchOfflineResults;
    }

    final mins = why.retryIn?.inMinutes;

    return mins == null
        ? l.searchLimitedResults
        : l.searchLimitedResultsIn(mins);
  }

  String _nothingLoadedReason(
    BuildContext context,
    ({ApiIssue kind, Duration? retryIn}) why,
  ) {
    final l = AppLocalizations.of(context)!;

    if (why.kind != ApiIssue.rateLimited) {
      return l.apiUnreachable;
    }

    final mins = why.retryIn?.inMinutes;

    return mins == null ? l.apiLimitReached : l.apiLimitReachedIn(mins);
  }

  /// Says the list is short rather than letting it pass for the whole answer.
  Widget _incompleteNotice(
    BuildContext context,
    ({ApiIssue kind, Duration? retryIn}) why,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _shortListReason(context, why),
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Only for when there is nothing to show yet. Once anything matches, the
  /// slim bar over the results says the same thing without taking the screen
  /// away from what the user came for.
  Widget _stillLoading(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PlanetLoadingAnimation(),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.loadingMore,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _suggestionList(
    BuildContext context,
    List<_Entry> all,
    bool busy,
    ({ApiIssue kind, Duration? retryIn}) why,
  ) {
    final suggestions = _searchSuggestions(_matches(all));

    if (suggestions.isEmpty) {
      if (busy) {
        return _stillLoading(context);
      }

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            why.kind == ApiIssue.none
                ? AppLocalizations.of(context)!.emptyResults
                : _nothingLoadedReason(context, why),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(
            suggestions[index],
            style: Theme.of(context).textTheme.titleSmall,
          ),
          onTap: () {
            query = suggestions[index];
            showResults(context);
          },
          onLongPress: () {
            query = suggestions[index];
            showSuggestions(context);
          },
        );
      },
    );
  }
}

/// One searchable item, with its text flattened once.
///
/// The fields used to be gathered and lowercased for every item on every
/// keystroke, and again for the suggestion list.
class _Entry {
  _Entry(this.item) : haystack = _textOf(item).join("\n").toLowerCase();

  final dynamic item;
  final String haystack;

  static List<String> _textOf(dynamic item) {
    List<String?> texts = [];

    if (item is Launch) {
      texts.addAll([
        item.slug,
        item.name,
        item.mission?.orbit?.name,
        item.mission?.orbit?.abbrev,
        item.launchServiceProvider?.name,
        item.launchServiceProvider?.abbrev,
        item.rocket?.configuration?.name,
        item.rocket?.configuration?.description,
        item.rocket?.configuration?.fullName,
        item.rocket?.configuration?.variant,
        ...?item.rocket?.launcherStage.expand(
          (e) => [e.launcher?.details, e.launcher?.serialNumber],
        ),
        ...?item.rocket?.spacecraftStage.expand((e) => [e.name, e.description]),
        item.mission?.description,
        item.pad?.name,
        item.pad?.location?.name,
        ...item.vidUrls.expand((e) => [e.title, e.description]),
      ]);
    } else if (item is Event) {
      texts.addAll([
        item.slug,
        item.name,
        item.description,
        item.location,
        ...item.spacestations.expand((e) => [e.name, e.description]),
      ]);
    }

    return texts.whereType<String>().toList();
  }
}
