import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rockit/apis/launch_library/api.dart';
import 'package:rockit/apis/launch_library/events_response.dart';
import 'package:rockit/apis/launch_library/launch_response.dart';
import 'package:rockit/apis/spaceflightnews/api.dart';
import 'package:rockit/apis/spaceflightnews/article_response.dart';
import 'package:rockit/l10n/app_localizations.dart';
import 'package:rockit/util/keyboard.dart';
import 'package:rockit/widgets/addons/app_bar.dart';
import 'package:rockit/widgets/addons/columns.dart';
import 'package:rockit/widgets/addons/insets.dart';
import 'package:rockit/widgets/addons/planet_loading_animation.dart';
import 'package:rockit/widgets/article_row.dart';

/// Searching the news, server-side.
///
/// Nothing like the launches and events search underneath: that one filters a
/// list already in memory and must never spend a Launch Library request, while
/// the news API has no advertised limit and answered twenty-five rapid requests
/// without complaint. So this one queries as you type.
///
/// A page rather than a `SearchDelegate`. The delegate swaps its body between
/// "suggestions" and "results" — pushing a launch and coming back switches it —
/// and each swap destroys the list, losing the scroll position and re-running
/// the query. Keys cannot save it either, because the delegate cross-fades the
/// two bodies and both are briefly mounted. Owning the page outright is
/// simpler than fighting that.
class NewsSearchPage extends StatefulWidget {
  const NewsSearchPage({super.key});

  @override
  State<NewsSearchPage> createState() => _NewsSearchPageState();
}

class _NewsSearchPageState extends State<NewsSearchPage> {
  final _service = SpaceFlightNewsAPI();
  final _scroll = ScrollController();
  final _field = TextEditingController();
  final _focus = FocusNode();

  Timer? _debounce;

  /// Bumped on every new query so a slow answer for "star" cannot land on top
  /// of the results for "starship".
  int _generation = 0;

  String _running = "";

  List<Article> _articles = const [];
  bool _loading = false;
  bool _failed = false;
  bool _finished = false;
  bool _searched = false;

  /// Launches and events already cached, so a result can carry the same link
  /// the feed does. Cache only — a decoration is not worth a request.
  Map<String, Launch> _launches = const {};
  Map<int, Event> _events = const {};

  @override
  void initState() {
    super.initState();

    _field.addListener(() => _schedule(_field.text));
    unawaited(_loadCachedLinks());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _field.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _loadCachedLinks() async {
    try {
      final launches = await LaunchLibraryAPI().cachedUpcomingLaunches();
      final events = await LaunchLibraryAPI().cachedUpcomingEvents();

      if (!mounted) {
        return;
      }

      setState(() {
        _launches = {
          for (final l in launches?.results ?? const <Launch>[])
            if (l.id != null) l.id!: l,
        };
        _events = {
          for (final e in events?.results ?? const <Event>[])
            if (e.id != null) e.id!: e,
        };
      });
    } catch (e) {
      debugPrint("Could not read cached launches for news search: $e");
    }
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
      setState(() {
        _articles = const [];
        _loading = false;
        _searched = false;
      });
      return;
    }

    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => unawaited(_run(trimmed)),
    );
  }

  Future<void> _run(String q, {bool more = false}) async {
    if (!mounted || (more && _loading)) {
      return;
    }

    final generation = more ? _generation : ++_generation;
    _running = q;

    final previous = more ? _articles : const <Article>[];
    setState(() {
      _articles = previous;
      _loading = true;
      _failed = false;
    });

    try {
      final res = await _service.searchArticles(
        q,
        after: more ? previous.length : null,
      );

      // A newer query started while this was in the air.
      if (!mounted || generation != _generation) {
        return;
      }

      setState(() {
        _articles = more ? [...previous, ...res.data] : res.data;
        _loading = false;
        _finished = res.data.isEmpty;
        _searched = true;
      });
    } catch (e) {
      debugPrint("News search failed: $e");

      if (!mounted || generation != _generation) {
        return;
      }

      setState(() {
        _loading = false;
        _failed = true;
        _searched = true;
      });
    }
  }

  Widget _row(Article a) {
    return ArticleRow(
      title: a.title,
      link: a.url,
      imageUrl: a.imageUrl,
      newsSite: a.newsSite,
      publishDate: a.publishedAt,
      relatedLaunches: a.launchIds
          .map((id) => _launches[id])
          .whereType<Launch>()
          .toList(),
      relatedEvents: a.eventIds
          .map((id) => _events[id])
          .whereType<Event>()
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: scheme.primary,
        systemOverlayStyle: systemOverlayStyle(context),
        iconTheme: const IconThemeData(color: Colors.white),
        title: TextField(
          controller: _field,
          focusNode: _focus,
          autofocus: true,
          textInputAction: TextInputAction.search,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: localizations.searchNews,
            // Dim enough to read as a placeholder, no dimmer. At 0.7 this
            // measured 2.4:1 on the light app bar and 3.6:1 on the dark one,
            // against 4.5:1 for small text; 0.85 clears the bar in the dark
            // theme. The light theme cannot pass here at any alpha — white on
            // that blue is 3.4:1 even opaque — which is a fact about the
            // brand colour rather than about this line.
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.white),
            // Tapping the button takes focus, which closes the keyboard —
            // and clearing the query is almost always the start of typing a
            // new one, not the end of searching.
            onPressed: () {
              _field.clear();
              // Both, because either can be the one that is missing: focus if
              // the user had tapped away, the keyboard if it was merely
              // dismissed while the field kept the caret.
              _focus.requestFocus();
              showKeyboard();
            },
            tooltip: localizations.clearSearch,
          ),
        ],
      ),
      body: _body(localizations),
    );
  }

  Widget _body(AppLocalizations localizations) {
    if (_articles.isEmpty) {
      if (_loading) {
        return const Center(child: PlanetLoadingAnimation());
      }
      if (_failed) {
        return Center(child: Text(localizations.loadingNewsFail));
      }
      if (_searched) {
        return Center(child: Text(localizations.emptyResults));
      }

      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // Scrolling means the user is reading rather than typing, so the
        // keyboard should be out of the way — and once focus is gone, coming
        // back from an article does not bring it up again either.
        NotificationListener<ScrollStartNotification>(
          onNotification: (_) {
            _focus.unfocus();
            return false;
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = columnsForWidth(constraints.maxWidth);

              return ListView.builder(
                controller: _scroll,
                physics: const BouncingScrollPhysics(),
                padding: bottomSystemBarPadding(context),
                itemCount: ArticleRowGroup.rowCount(_articles.length, columns),
                itemBuilder: (context, row) {
                  final first = row * columns;

                  if (!_finished &&
                      !_loading &&
                      first >= _articles.length ~/ 2) {
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => unawaited(_run(_running, more: true)),
                    );
                  }

                  return ArticleRowGroup(
                    columns: columns,
                    children: [
                      for (
                        var i = first;
                        i < first + columns && i < _articles.length;
                        i++
                      )
                        _row(_articles[i]),
                    ],
                  );
                },
              );
            },
          ),
        ),
        // Kept over the old results rather than replacing them, so typing does
        // not blank the screen between queries.
        if (_loading)
          const Align(
            alignment: Alignment.topCenter,
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }
}
