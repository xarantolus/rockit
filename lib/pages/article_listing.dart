import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:loadmore/loadmore.dart';
import 'package:rockit/apis/spaceflightnews/api.dart';
import 'package:rockit/apis/spaceflightnews/article_response.dart';
import 'package:rockit/mixins/date_format.dart';
import 'package:rockit/mixins/url_launcher.dart';
import 'package:rockit/widgets/addons/planet_loading_animation.dart';
import 'package:rockit/widgets/article.dart';

class ArticleListingPage extends StatefulWidget {
  ArticleListingPage({Key? key}) : super(key: key);

  final service = SpaceFlightNewsAPI();

  @override
  _ArticleListingPageState createState() => _ArticleListingPageState();
}

class _ArticleListingPageState extends State<ArticleListingPage> with AutomaticKeepAliveClientMixin {
  // Make sure this page is cached, else it would reload often when switching between tabs
  @override
  bool get wantKeepAlive => true;

  late Future<List<Article>> articlesFuture = load(context, widget.service);

  static Future<List<Article>> load(
    BuildContext context,
    SpaceFlightNewsAPI api, [
    int? after,
  ]) async {
    try {
      var res = await api.articles(after);

      res.maybeShowSnack(context);

      return res.data;
    } catch (e) {
      debugPrint("Error loading articles: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.loadingFail),
        ),
      );

      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Center(
      child: FutureBuilder<List<Article>>(
        future: articlesFuture,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return const PlanetLoadingAnimation();
            default:
              if (snapshot.hasError) {
                return GestureDetector(
                  child: ErrorWidget("${snapshot.error!}\n${AppLocalizations.of(context)!.tapToTryAgain}"),
                  onTap: () => setState(() {
                    articlesFuture = load(context, widget.service);
                  }),
                );
              } else {
                final results = snapshot.data!;
                if (results.isEmpty) {
                  return Center(
                    child: Text(AppLocalizations.of(context)!.noNews),
                  );
                } else {
                  return NewsList(
                    results,
                    widget.service,
                  );
                }
              }
          }
        },
      ),
    );
  }
}

class NewsList extends StatefulWidget {
  const NewsList(this.initialArticles, this.service, {Key? key}) : super(key: key);

  final List<Article> initialArticles;
  final SpaceFlightNewsAPI service;

  @override
  _NewsListState createState() => _NewsListState();
}

class _NewsListState extends State<NewsList> with DateFormatter, UrlLauncher {
  late List<Article> articles = widget.initialArticles;
  bool _finished = false;

  Future<bool> _updateArticles([bool? refresh]) async {
    var _newArticles = await _ArticleListingPageState.load(
      context,
      widget.service,
      refresh == true ? null : articles.length,
    );

    setState(() {
      if (refresh == true) {
        articles = _newArticles;
      } else {
        // See upcoming_launches_listing.dart for more info, but in short:
        // This makes sure that cached responses do not lead to duplicate display of content
        _newArticles.removeWhere((newArticle) => articles.any((article) => article.id == newArticle.id));

        articles.addAll(_newArticles);
      }

      _finished = _newArticles.isEmpty;
    });

    return articles.isNotEmpty;
  }

  Future<bool> _loadMore() async {
    return await _updateArticles(false);
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
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: articles.length,
          // We basically pre-compute this much info, that way images are often already there
          cacheExtent: MediaQuery.of(context).size.height * 2,
          itemBuilder: (BuildContext context, int index) {
            final a = articles[index];
            return ArticleCardWidget(
              title: a.title,
              link: a.url,
              imageUrl: a.imageUrl,
              newsSite: a.newsSite,
              summary: a.summary,
              publishDate: a.publishedAt,
            );
          },
        ),
        textBuilder: _buildLoadingText,
      ),
    );
  }
}
