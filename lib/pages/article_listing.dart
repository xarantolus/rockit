import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:loadmore/loadmore.dart';
import 'package:rockit/apis/spaceflightnews/api.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rockit/apis/spaceflightnews/article_response.dart';
import 'package:flutter_custom_tabs_platform_interface/flutter_custom_tabs_platform_interface.dart';
import 'package:rockit/mixins/date_format.dart';

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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Center(
      child: FutureBuilder<List<Article>>(
        future: widget.service.articles(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            final results = snapshot.data!;
            if (results?.isEmpty ?? true) {
              return Center(
                child: Text(AppLocalizations.of(context)!.noNews),
              );
            } else {
              return NewsList(
                results,
                widget.service,
              );
            }
          } else if (snapshot.hasError) {
            return GestureDetector(
              child: ErrorWidget(
                  "${snapshot.error!}\n${AppLocalizations.of(context)!.tapToTryAgain}"),
              onTap: () => setState(() {}),
            );
          } else {
            return const CircularProgressIndicator();
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

class _NewsListState extends State<NewsList> with DateFormatter {
  late List<Article> articles = widget.initialArticles;
  bool _finished = false;

  bool _isLetter(String letter) {
    final RegExp alpha = RegExp(r'\p{Letter}', unicode: true);
    return alpha.hasMatch(letter);
  }

  String dottedText(String text) {
    var lastLetter = text[text.length - 1];
    if (_isLetter(lastLetter)) {
      return text + "...";
    }
    return text;
  }

  Future<bool> _updateArticles([bool? refresh]) async {
    var _newArticles =
        await widget.service.articles(refresh == true ? null : articles.length);

    setState(() {
      if (refresh == true) {
        articles = _newArticles;
      } else {
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

  Widget _articleCard(Article article) {
    return Center(
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        margin: const EdgeInsets.fromLTRB(10, 5, 10, 5),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                article.title ?? AppLocalizations.of(context)!.unknown,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if ((article.imageUrl ?? "").isNotEmpty)
              SizedBox(
                height: max(MediaQuery.of(context).size.height / 4, 200),
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: article.imageUrl!,
                  fadeInDuration: const Duration(milliseconds: 125),
                  fadeOutDuration: const Duration(milliseconds: 250),
                  fit: BoxFit.cover,
                  progressIndicatorBuilder: (context, url, downloadProgress) =>
                      Center(
                    child: CircularProgressIndicator(
                        value: downloadProgress.progress),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(Icons.error),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                article.summary != null
                    ? dottedText(article.summary!)
                    : AppLocalizations.of(context)!.unknown,
                style: const TextStyle(
                  fontSize: 15,
                ),
              ),
            ),
            if (article.publishedAt != null)
              Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.all(4),
                child: Text(
                  formatDateTimeFriendly(context, article.publishedAt!),
                ),
              ),
          ],
        ),
      ),
    );
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
          itemCount: articles.length,
          // We basically pre-compute this much info, that way images are often already there
          cacheExtent: MediaQuery.of(context).size.height * 2,
          itemBuilder: (BuildContext context, int index) {
            return GestureDetector(
              child: _articleCard(articles[index]),
              onTap: () async {
                await launch(
                  articles[index].url ?? "",
                  customTabsOption: CustomTabsOption(
                    toolbarColor: Theme.of(context).primaryColor,
                    enableDefaultShare: true,
                    enableUrlBarHiding: true,
                    showPageTitle: true,
                    animation: CustomTabsSystemAnimation.slideIn(),
                    extraCustomTabs: const <String>[
                      // Browsers that support custom tabs. Could/Should add more
                      "org.bromite.bromite",
                      'org.mozilla.firefox',
                      'com.microsoft.emmx',
                    ],
                  ),
                );
              },
            );
          },
        ),
        textBuilder: _buildLoadingText,
      ),
    );
  }
}
