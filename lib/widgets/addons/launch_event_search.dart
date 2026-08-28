import 'package:flutter/material.dart';
import 'package:rockit/l10n/app_localizations.dart';
import 'package:rockit/apis/launch_library/api.dart';
import 'package:rockit/apis/launch_library/events_response.dart';
import 'package:rockit/apis/launch_library/launch_response.dart';
import 'package:rockit/pages/addons/launch_event_listing.dart';
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

  /// Everything searchable, rebuilt as cached pages arrive.
  final entries = ValueNotifier<List<_Entry>>([]);

  /// Walks the *cached* listing pages and indexes what it finds.
  ///
  /// Cache only. This used to page with `preferCache: true`, which falls
  /// through to the network on a miss, so opening search could spend most of
  /// the fifteen hourly requests before the field even appeared — measured at
  /// three requests and 21 seconds against the dev API, and it is capped at
  /// ten. Now an uncached page simply is not searched.
  Future<void> indexCachedPages() async {
    final api = LaunchLibraryAPI();
    final found = <dynamic>[];

    Future<void> walk(Future<dynamic> Function(String? next) page) async {
      String? next;
      do {
        final resp = await page(next);
        if (resp == null) {
          return;
        }

        found.addAll(resp.results as List<dynamic>);
        next = resp.next as String?;

        entries.value = sortLaunchesAndEvents(
          List.of(found),
        ).map(_Entry.new).toList();
      } while (next != null);
    }

    try {
      await walk((next) => api.cachedUpcomingLaunches(next: next));
      await walk((next) => api.cachedUpcomingEvents(next: next));
    } catch (e) {
      debugPrint("Error building the search index: $e");
    }
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
          showSuggestions(context);
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
      builder: (context, all, _) => LaunchEventListing<dynamic, String>(
        emptyText: AppLocalizations.of(context)!.emptyResults,
        initialItems: _matches(all).map((e) => e.item).toList(),
        scrollOffset: scrollOffset,
        heroPrefix: "search-",
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
