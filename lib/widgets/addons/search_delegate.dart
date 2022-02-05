import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rockit/apis/launch_library/events_response.dart';
import 'package:rockit/apis/launch_library/launch_response.dart';
import 'package:rockit/pages/addons/launch_event_listing.dart';
import 'package:rockit/widgets/addons/sort.dart';

class CustomSearchDelegate extends SearchDelegate {
  CustomSearchDelegate(BuildContext context, launchesAndEvents)
      : launchesAndEvents = sortLaunchesAndEvents(launchesAndEvents),
        super(
          searchFieldLabel: AppLocalizations.of(context)!.search,
        );

  List<dynamic> launchesAndEvents;

  @override
  ThemeData appBarTheme(BuildContext context) {
    var barColor = Theme.of(context).colorScheme.primary;

    return Theme.of(context).copyWith(
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: barColor,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: barColor,
          systemNavigationBarColor: barColor,
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
                ?.map((e) => [e.name, e.description])
                .fold(List<String?>.empty(), (l, txts) => txts..addAll(l ?? [])) ??
            []),
      ]);
    }
    return texts.whereType<String>().toList();
  }

  String lastTerm = "";
  double? lastOffset;
  ScrollController? scroll;

  void setScroll() {
    scroll = ScrollController(
      initialScrollOffset: lastOffset ?? 0,
    )..addListener(() {
        lastOffset = scroll?.offset ?? 0;
      });
  }

  final _splitBySpaceRegex = RegExp('\\s+');
  List<dynamic> _searchEntries() {
    final searchTerm = query.toLowerCase().trim();
    if (searchTerm.isEmpty) {
      return launchesAndEvents;
    }

    if (searchTerm != lastTerm) {
      scroll = ScrollController();
      lastOffset = 0;
      lastTerm = searchTerm;
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

  @override
  Widget buildResults(BuildContext context) {
    final items = _searchEntries();

    setScroll();

    return LaunchEventListing<dynamic, String>(
      key: UniqueKey(),
      emptyText: AppLocalizations.of(context)!.emptyResults,
      initialItems: items,
      controller: scroll,
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
          title: Text(suggestions[index]),
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
