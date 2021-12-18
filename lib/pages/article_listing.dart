import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:loadmore/loadmore.dart';
import 'package:rockit/apis/error_details.dart';
import 'package:rockit/apis/spaceflightnews/api.dart';
import 'package:rockit/apis/spaceflightnews/article_response.dart';
import 'package:rockit/mixins/date_format.dart';
import 'package:rockit/mixins/url_launcher.dart';
import 'package:rockit/widgets/article.dart';

class ArticleListingPage extends StatefulWidget {
  ArticleListingPage({Key? key}) : super(key: key);

  final service = SpaceFlightNewsAPI();

  @override
  _ArticleListingPageState createState() => _ArticleListingPageState();
}

class _ArticleListingPageState extends State<ArticleListingPage>
    with AutomaticKeepAliveClientMixin {
  // Make sure this page is cached, else it would reload often when switching between tabs
  @override
  bool get wantKeepAlive => true;

  late Future<ErrorDetails<List<Article>>> articlesFuture =
      widget.service.articles();

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Center(
      child: FutureBuilder<ErrorDetails<List<Article>>>(
        future: articlesFuture,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
              return const CircularProgressIndicator();
            default:
              if (snapshot.hasError) {
                return GestureDetector(
                  child: ErrorWidget(
                      "${snapshot.error!}\n${AppLocalizations.of(context)!.tapToTryAgain}"),
                  onTap: () => setState(() {
                    articlesFuture = widget.service.articles();
                  }),
                );
              } else {
                final results = snapshot.data!;
                results.maybeShowSnack(context);

                if (results.data?.isEmpty ?? true) {
                  return Center(
                    child: Text(AppLocalizations.of(context)!.noNews),
                  );
                } else {
                  return NewsList(
                    results.data,
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
  const NewsList(this.initialArticles, this.service, {Key? key})
      : super(key: key);

  final List<Article> initialArticles;
  final SpaceFlightNewsAPI service;

  @override
  _NewsListState createState() => _NewsListState();
}

class _NewsListState extends State<NewsList> with DateFormatter, UrlLauncher {
  late List<Article> articles = widget.initialArticles;
  bool _finished = false;

  Future<bool> _updateArticles([bool? refresh]) async {
    var _newArticles =
        await widget.service.articles(refresh == true ? null : articles.length);

    _newArticles.maybeShowSnack(context);

    setState(() {
      if (refresh == true) {
        articles = _newArticles.data;
      } else {
        // See upcoming_launches_listing.dart for more info, but in short:
        // This makes sure that cached responses do not lead to duplicate display of content
        _newArticles.data.removeWhere((newArticle) =>
            articles.any((article) => article.id == newArticle.id));

        articles.addAll(_newArticles.data);
      }

      _finished = _newArticles.data.isEmpty;
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
