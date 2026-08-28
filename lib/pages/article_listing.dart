import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:rockit/l10n/app_localizations.dart';
import 'package:loadmore/loadmore.dart';
import 'package:rockit/apis/cache_first.dart';
import 'package:rockit/apis/launch_library/api.dart';
import 'package:rockit/apis/launch_library/launch_response.dart';
import 'package:rockit/apis/error_details.dart';
import 'package:rockit/apis/paging.dart';
import 'package:rockit/apis/spaceflightnews/api.dart';
import 'package:rockit/apis/spaceflightnews/article_response.dart';
import 'package:rockit/mixins/date_format.dart';
import 'package:rockit/mixins/url_launcher.dart';
import 'package:rockit/widgets/addons/insets.dart';
import 'package:rockit/widgets/addons/planet_loading_animation.dart';
import 'package:rockit/widgets/addons/refreshing_overlay.dart';
import 'package:rockit/widgets/article_row.dart';

class ArticleListingPage extends StatefulWidget {
  ArticleListingPage({super.key});

  final service = SpaceFlightNewsAPI();

  @override
  State<ArticleListingPage> createState() => _ArticleListingPageState();
}

class _ArticleListingPageState extends State<ArticleListingPage>
    with AutomaticKeepAliveClientMixin {
  // Make sure this page is cached, else it would reload often when switching between tabs
  @override
  bool get wantKeepAlive => true;

  late final CacheFirstController<List<Article>> controller =
      CacheFirstController(
        loadCached: () => widget.service.cachedArticles(),
        loadFresh: () async {
          final res = await widget.service.articles();
          controller.noteNotice(res.error);
          return res.data;
        },
      );

  /// Cached launches keyed by id, for the "related launch" chip.
  Map<String, Launch>? _launchesById;

  @override
  void initState() {
    super.initState();

    controller.addListener(_onControllerUpdate);
    unawaited(controller.start());
    unawaited(_loadCachedLaunches());
  }

  /// Reads whatever launches are already cached so an article can link to the
  /// one it is about. Deliberately cache-only: the Launch Library allows 15
  /// requests an hour and a decoration is not worth one of them.
  Future<void> _loadCachedLaunches() async {
    try {
      final cached = await LaunchLibraryAPI().cachedUpcomingLaunches();
      if (cached == null || !mounted) {
        return;
      }

      setState(() {
        _launchesById = {
          for (final launch in cached.results)
            if (launch.id != null) launch.id!: launch,
        };
      });
    } catch (e) {
      debugPrint("Could not read cached launches for article links: $e");
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerUpdate);
    controller.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (!mounted) {
      return;
    }

    final notice = controller.takeNotice();

    setState(() {});

    notice?.showSnack(context);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final articles = controller.data;

    if (articles == null) {
      if (controller.status == ListingStatus.failed) {
        return Center(
          child: GestureDetector(
            child: ErrorWidget(
              "${controller.fatalError}\n${AppLocalizations.of(context)!.tapToTryAgain}",
            ),
            onTap: () => unawaited(controller.refresh()),
          ),
        );
      }

      return const Center(child: PlanetLoadingAnimation());
    }

    // An empty cached page while the refresh is still running is not "nothing
    // to show" yet, so keep waiting rather than flashing the empty text.
    if (articles.isEmpty && !controller.isRefreshing) {
      return Center(child: Text(AppLocalizations.of(context)!.noNews));
    }

    return RefreshingOverlay(
      refreshing: controller.isRefreshing,
      child: NewsList(articles, widget.service, launchesById: _launchesById),
    );
  }
}

class NewsList extends StatefulWidget {
  const NewsList(
    this.initialArticles,
    this.service, {
    this.launchesById,
    super.key,
  });

  final List<Article> initialArticles;
  final SpaceFlightNewsAPI service;

  /// Launches already in the cache, keyed by id. Only used to decorate rows,
  /// so a miss simply means no chip — never an extra request.
  final Map<String, Launch>? launchesById;

  @override
  State<NewsList> createState() => _NewsListState();
}

class _NewsListState extends State<NewsList> with DateFormatter, UrlLauncher {
  late List<Article> articles = widget.initialArticles;
  bool _finished = false;

  /// Whether the user has paged past the first page.
  bool _paged = false;

  @override
  void didUpdateWidget(NewsList oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (identical(widget.initialArticles, oldWidget.initialArticles)) {
      return;
    }

    // See _ItemListState.didUpdateWidget: don't shrink the list under a user
    // who has already paged further.
    if (_paged) {
      return;
    }

    articles = widget.initialArticles;
    _finished = false;
  }

  Future<bool> _updateArticles([bool? refresh]) async {
    final ErrorDetails<List<Article>> res;

    try {
      res = await widget.service.articles(
        refresh == true ? null : articles.length,
      );
    } catch (e) {
      debugPrint("Error loading articles: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.loadingFail)),
        );
      }

      // Keep whatever is on screen; a failed page load must not blank the list.
      return articles.isNotEmpty;
    }

    if (!mounted) {
      return true;
    }

    setState(() {
      if (refresh == true) {
        articles = res.data;
        _paged = false;
      } else {
        articles = mergePages(articles, res.data, (article) => article.id);
        _paged = true;
      }

      _finished = res.data.isEmpty;
    });

    res.maybeShowSnack(context);

    return articles.isNotEmpty;
  }

  Future<bool> _loadMore() async {
    return await _updateArticles(false);
  }

  bool _loadingMore = false;

  /// Fetches the next page once the list is built out past its middle, rather
  /// than waiting for the bottom.
  ///
  /// `LoadMore` only asks when its footer appears, which on a ten-second API
  /// means staring at a spinner at the end of every page.
  void _loadMoreEarly(int index) {
    if (_finished || _loadingMore || index < articles.length ~/ 2) {
      return;
    }

    _loadingMore = true;

    // Not during the build that asked for it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMore().whenComplete(() => _loadingMore = false);
    });
  }

  String _buildLoadingText(LoadMoreStatus status) {
    switch (status) {
      case LoadMoreStatus.fail:
        return AppLocalizations.of(context)!.loadingNewsFail;
      case LoadMoreStatus.idle:
        return AppLocalizations.of(context)!.loadingNewsIdle;
      case LoadMoreStatus.loading:
        return AppLocalizations.of(context)!.loadingNewsLoading;
      case LoadMoreStatus.nomore:
        return AppLocalizations.of(context)!.loadingNewsNoMore;
      default:
        return AppLocalizations.of(context)!.unknown;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await _updateArticles(true);
      },
      child: LoadMore(
        isFinish: _finished,
        onLoadMore: _loadMore,
        textBuilder: _buildLoadingText,
        child: ListView.builder(
          scrollCacheExtent: ScrollCacheExtent.pixels(
            MediaQuery.of(context).size.height * 2,
          ),
          physics: const BouncingScrollPhysics(),
          padding: bottomSystemBarPadding(context),
          itemCount: articles.length,
          itemBuilder: (BuildContext context, int index) {
            _loadMoreEarly(index);

            final a = articles[index];
            return ArticleRow(
              title: a.title,
              link: a.url,
              imageUrl: a.imageUrl,
              newsSite: a.newsSite,
              publishDate: a.publishedAt,
              relatedLaunch: widget.launchesById == null
                  ? null
                  : a.launchIds
                        .map((id) => widget.launchesById![id])
                        .whereType<Launch>()
                        .firstOrNull,
            );
          },
        ),
      ),
    );
  }
}
