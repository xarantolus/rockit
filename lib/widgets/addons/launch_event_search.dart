import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rockit/apis/error_details.dart';
import 'package:rockit/apis/launch_library/api.dart';
import 'package:rockit/apis/launch_library/events_response.dart';
import 'package:rockit/apis/launch_library/launch_response.dart';
import 'package:rockit/l10n/app_localizations.dart';
import 'package:rockit/pages/addons/launch_event_listing.dart';
import 'package:rockit/util/keyboard.dart';
import 'package:rockit/widgets/addons/app_bar.dart';
import 'package:rockit/widgets/addons/sort.dart';

class LaunchEventSearchDelegate extends SearchDelegate {
  LaunchEventSearchDelegate({
    required String searchLabel,
    required Color? searchTextColor,
  }) : super(
         searchFieldLabel: searchLabel,
         searchFieldStyle: TextStyle(color: searchTextColor),
       );

  /// Everything searchable, rebuilt as pages arrive.
  final entries = ValueNotifier<List<_Entry>>([]);

  /// True while pages are still being fetched, so the results can say so
  /// rather than looking simply incomplete.
  final completing = ValueNotifier<bool>(false);

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

      void publish() {
        entries.value = sortLaunchesAndEvents(
          List.of(found),
        ).map(_Entry.new).toList();
      }

      /// Reads cached pages until one is missing, and returns where to
      /// continue from — null when the listing is already complete.
      Future<String?> walkCache(
        Future<dynamic> Function(String? next) page,
      ) async {
        String? next;
        do {
          final resp = await page(next);
          if (resp == null) {
            return next;
          }

          found.addAll(resp.results as List<dynamic>);
          next = resp.next as String?;
          publish();
        } while (next != null);

        return null;
      }

      final launchNext = await walkCache(
        (next) => api.cachedUpcomingLaunches(next: next),
      );
      final eventNext = await walkCache(
        (next) => api.cachedUpcomingEvents(next: next),
      );

      if (launchNext == null && eventNext == null) {
        return;
      }

      var budget = await _spendableRequests();
      if (budget <= 0) {
        return;
      }

      completing.value = true;

      /// Continues a listing over the network from [from].
      Future<void> fetchRest(
        String? from,
        Future<ErrorDetails<dynamic>> Function(String? next) page,
      ) async {
        var next = from;
        while (next != null && budget > 0) {
          budget--;

          final resp = await page(next);
          final data = resp.data;
          if (data == null) {
            return;
          }

          found.addAll(data.results as List<dynamic>);
          next = data.next as String?;
          publish();
        }
      }

      await fetchRest(launchNext, (next) => api.upcomingLaunches(next: next));
      await fetchRest(eventNext, (next) => api.upcomingEvents(next: next));
    } catch (e) {
      debugPrint("Error building the search index: $e");
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
  Future<int> _spendableRequests() async {
    final remaining = (await LaunchLibraryAPI().throttle())?.remaining;
    if (remaining == null) {
      return 0;
    }

    return min(_maxExtraPages, remaining - _reserve);
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

    return ValueListenableBuilder(
      valueListenable: entries,
      builder: (context, all, _) => Stack(
        children: [
          LaunchEventListing<dynamic, String>(
            emptyText: AppLocalizations.of(context)!.emptyResults,
            initialItems: _matches(all).map((e) => e.item).toList(),
            scrollOffset: scrollOffset,
            heroPrefix: "search-",
          ),
          // Over the results rather than replacing them: what is already
          // indexed is searchable while the rest arrives, and this is the only
          // thing that distinguishes "still filling" from "that is all there
          // is".
          ValueListenableBuilder(
            valueListenable: completing,
            builder: (context, busy, _) => busy
                ? const Align(
                    alignment: Alignment.topCenter,
                    child: LinearProgressIndicator(minHeight: 2),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
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
    return ValueListenableBuilder(
      valueListenable: entries,
      builder: (context, all, _) => _suggestionList(context, all),
    );
  }

  Widget _suggestionList(BuildContext context, List<_Entry> all) {
    final suggestions = _searchSuggestions(_matches(all));

    if (suggestions.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.emptyResults));
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
