import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rockit/apis/launch_library/api.dart';
import 'package:rockit/apis/launch_library/events_response.dart';
import 'package:rockit/apis/launch_library/launch_response.dart';
import 'package:rockit/apis/spaceflightnews/api.dart';
import 'package:rockit/apis/spaceflightnews/article_response.dart';
import 'package:rockit/l10n/app_localizations.dart';
import 'package:rockit/widgets/addons/app_bar.dart';
import 'package:rockit/widgets/addons/insets.dart';
import 'package:rockit/widgets/addons/planet_loading_animation.dart';
import 'package:rockit/widgets/article_row.dart';

/// Searching the news, server-side.
///
/// Separate from the launches and events search because the two are nothing
/// alike underneath: that one filters a list already in memory and must never
/// spend a Launch Library request, while this asks the news API, which took
/// twenty-five requests in a row without complaint and has no advertised limit.
/// So this one can query as you type.
class NewsSearchDelegate extends SearchDelegate {
  NewsSearchDelegate({
    required String searchLabel,
    required Color? searchTextColor,
  }) : super(
         searchFieldLabel: searchLabel,
         searchFieldStyle: TextStyle(color: searchTextColor),
       );

  final _state = ValueNotifier(const NewsSearchState());

  final _service = SpaceFlightNewsAPI();

  Timer? _debounce;

  /// Bumped on every new query so a slow answer for "star" cannot land on top
  /// of the results for "starship".
  int _generation = 0;

  String _running = "";

  /// Launches and events already cached, so a result can carry the same link
  /// the feed does. Cache only — a decoration is not worth a request.
  Map<String, Launch> _launches = const {};
  Map<int, Event> _events = const {};

  Future<void> loadCachedLinks() async {
    try {
      final launches = await LaunchLibraryAPI().cachedUpcomingLaunches();
      final events = await LaunchLibraryAPI().cachedUpcomingEvents();

      _launches = {
        for (final l in launches?.results ?? const <Launch>[])
          if (l.id != null) l.id!: l,
      };
      _events = {
        for (final e in events?.results ?? const <Event>[])
          if (e.id != null) e.id!: e,
      };
    } catch (e) {
      debugPrint("Could not read cached launches for news search: $e");
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _state.dispose();
    super.dispose();
  }

  /// Waits for a pause in typing before asking.
  void _schedule(String q) {
    final trimmed = q.trim();
    if (trimmed == _running) {
      return;
    }

    _debounce?.cancel();

    if (trimmed.isEmpty) {
      _running = "";
      _generation++;
      _state.value = const NewsSearchState();
      return;
    }

    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => unawaited(_run(trimmed)),
    );
  }

  Future<void> _run(String q, {bool more = false}) async {
    final generation = more ? _generation : ++_generation;
    _running = q;

    final previous = more ? _state.value.articles : const <Article>[];
    _state.value = _state.value.copyWith(
      loading: true,
      failed: false,
      articles: previous,
    );

    try {
      final res = await _service.searchArticles(
        q,
        after: more ? previous.length : null,
      );

      // A newer query started while this was in the air.
      if (generation != _generation) {
        return;
      }

      final combined = more ? [...previous, ...res.data] : res.data;

      _state.value = NewsSearchState(
        articles: combined,
        loading: false,
        finished: res.data.isEmpty,
        searched: true,
      );
    } catch (e) {
      debugPrint("News search failed: $e");

      if (generation != _generation) {
        return;
      }

      _state.value = _state.value.copyWith(
        loading: false,
        failed: true,
        searched: true,
      );
    }
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
        _debounce?.cancel();
        close(context, null);
      },
      tooltip: AppLocalizations.of(context)!.close,
    );
  }

  // Both show the same thing: there is nothing to suggest that is not simply
  // the result, and having them differ would mean the screen changed under the
  // user when the keyboard closed.
  @override
  Widget buildResults(BuildContext context) => _results(context);

  @override
  Widget buildSuggestions(BuildContext context) => _results(context);

  Widget _results(BuildContext context) {
    _schedule(query);

    return ValueListenableBuilder(
      valueListenable: _state,
      builder: (context, state, _) {
        final localizations = AppLocalizations.of(context)!;

        if (state.articles.isEmpty) {
          if (state.loading) {
            return const Center(child: PlanetLoadingAnimation());
          }
          if (state.failed) {
            return Center(child: Text(localizations.loadingNewsFail));
          }
          if (state.searched) {
            return Center(child: Text(localizations.emptyResults));
          }

          return const SizedBox.shrink();
        }

        return Stack(
          children: [
            ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: bottomSystemBarPadding(context),
              itemCount: state.articles.length,
              itemBuilder: (context, index) {
                if (!state.finished &&
                    !state.loading &&
                    index >= state.articles.length ~/ 2) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => unawaited(_run(_running, more: true)),
                  );
                }

                final a = state.articles[index];

                return ArticleRow(
                  title: a.title,
                  link: a.url,
                  imageUrl: a.imageUrl,
                  newsSite: a.newsSite,
                  publishDate: a.publishedAt,
                  relatedLaunch: a.launchIds
                      .map((id) => _launches[id])
                      .whereType<Launch>()
                      .firstOrNull,
                  relatedEvent: a.eventIds
                      .map((id) => _events[id])
                      .whereType<Event>()
                      .firstOrNull,
                );
              },
            ),
            // Kept over the old results rather than replacing them, so typing
            // does not blank the screen between queries.
            if (state.loading)
              const Align(
                alignment: Alignment.topCenter,
                child: LinearProgressIndicator(minHeight: 2),
              ),
          ],
        );
      },
    );
  }
}

/// What the search screen is showing right now.
class NewsSearchState {
  const NewsSearchState({
    this.articles = const [],
    this.loading = false,
    this.failed = false,
    this.finished = false,
    this.searched = false,
  });

  final List<Article> articles;
  final bool loading;
  final bool failed;

  /// The last page came back empty, so there is no point asking for more.
  final bool finished;

  /// A query has actually run, which is what separates "nothing found" from
  /// "you have not typed anything yet".
  final bool searched;

  NewsSearchState copyWith({
    List<Article>? articles,
    bool? loading,
    bool? failed,
    bool? finished,
    bool? searched,
  }) {
    return NewsSearchState(
      articles: articles ?? this.articles,
      loading: loading ?? this.loading,
      failed: failed ?? this.failed,
      finished: finished ?? this.finished,
      searched: searched ?? this.searched,
    );
  }
}
