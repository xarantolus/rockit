import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rockit/apis/error_details.dart';
import 'package:rockit/apis/launch_library/api.dart';
import 'package:rockit/apis/launch_library/events_response.dart';
import 'package:rockit/apis/launch_library/launch_response.dart';
import 'package:rockit/pages/addons/launch_event_listing.dart';
import 'package:rockit/widgets/addons/sort.dart';

class LaunchEventSearchDelegate extends SearchDelegate {
  LaunchEventSearchDelegate(BuildContext context, List<dynamic> launchesAndEvents)
      : launchesAndEvents = sortLaunchesAndEvents(launchesAndEvents),
        super(
          searchFieldLabel: AppLocalizations.of(context)!.search,
        );

  static Future<ErrorDetails<LaunchEventSearchDelegate>> searchLaunchesAndEvents(BuildContext context) async {
    List<dynamic> items = [];

    final api = LaunchLibraryAPI();

    bool hadError = false;
    int numRequests = 0;

    String? launchNext;
    do {
      try {
        final resp = await api.upcomingLaunches(next: launchNext, preferCache: true);
        items.addAll(resp.data.results ?? []);
        launchNext = resp.data.next;
      } catch (e) {
        debugPrint("Error while loading launches for search: $e");
        hadError = true;
      }
      if (++numRequests > 10) {
        debugPrint("Used too many requests while loading launches");
        hadError = true;
        break;
      }
    } while (launchNext != null);

    String? eventNext;
    do {
      try {
        final resp = await api.upcomingEvents(next: eventNext, preferCache: true);
        items.addAll(resp.data.results ?? []);
        eventNext = resp.data.next;
      } catch (e) {
        debugPrint("Error while loading events for search: $e");
        hadError = true;
      }
      if (++numRequests > 10) {
        debugPrint("Used too many requests while loading events");
        hadError = true;
        break;
      }
    } while (eventNext != null);

    return ErrorDetails(
      LaunchEventSearchDelegate(context, items),
      hadError ? error_type.incompleteData : null,
    );
  }

  List<dynamic> launchesAndEvents;

  @override
  ThemeData appBarTheme(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    return Theme.of(context).copyWith(
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: Colors.white,
        selectionColor: Colors.white.withOpacity(.5),
        selectionHandleColor: colorScheme.secondary,
      ),
      hintColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: colorScheme.primary,
          systemNavigationBarColor: colorScheme.primary,
        ),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: () {
          showResults(context);
        },
        tooltip: AppLocalizations.of(context)!.showResults,
      ),
      IconButton(
        icon: const Icon(Icons.clear),
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
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
      tooltip: AppLocalizations.of(context)!.close,
    );
  }

  String _itemText(dynamic item) {
    return (item is Launch ? item.name : (item as Event).name) ?? "";
  }

  List<String> _keyTexts(dynamic item) {
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
        ...(item.rocket?.launcherStage
                ?.map((e) => [e.launcher?.details, e.launcher?.serialNumber])
                .fold(List<String?>.empty(), (l, txts) => txts..addAll(l ?? [])) ??
            []),
        item.rocket?.spacecraftStage?.name,
        item.rocket?.spacecraftStage?.serialNumber,
        item.rocket?.spacecraftStage?.description,
        item.mission?.description,
        item.pad?.name,
        item.pad?.location?.name,
        ...(item.vidUrls
                ?.map((e) => [e.title, e.description])
                .fold(List<String?>.empty(), (l, txts) => txts..addAll(l ?? [])) ??
            []),
      ]);
    } else if (item is Event) {
      texts.addAll([
        item.slug,
        item.name,
        item.description,
        item.location,
        ...(item.spacestations
                ?.map((e) => [e.name, e.description, e.orbit])
                .fold(List<String?>.empty(), (l, txts) => txts..addAll(l ?? [])) ??
            []),
      ]);
    }
    return texts.whereType<String>().toList();
  }

  final _splitBySpaceRegex = RegExp('\\s+');
  List<dynamic> _searchEntries() {
    final searchTerm = query.toLowerCase().trim();
    if (searchTerm.isEmpty) {
      return launchesAndEvents;
    }

    final searchSplit = searchTerm.split(_splitBySpaceRegex);

    return launchesAndEvents.where((item) {
      final list = _keyTexts(item).map((e) => e.toLowerCase());

      // Every search term should be mentioned in any of these texts
      return searchSplit.every((term) {
        return list.any((tl) => tl.contains(term));
      });
    }).toList();
  }

  String lastTerm = "";

  late ValueNotifier<double> scrollOffset = ValueNotifier(0);

  @override
  Widget buildResults(BuildContext context) {
    if (lastTerm != query) {
      scrollOffset.value = 0;
    }

    final items = _searchEntries();
    lastTerm = query;

    return LaunchEventListing<dynamic, String>(
      emptyText: AppLocalizations.of(context)!.emptyResults,
      initialItems: items,
      scrollOffset: scrollOffset,
      heroPrefix: "search-",
    );
  }

  List<String> _searchSuggestions() {
    return _searchEntries().map(_itemText).toList();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = _searchSuggestions();

    if (suggestions.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context)!.emptyResults),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(
            suggestions[index],
            style: Theme.of(context).textTheme.subtitle1,
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
