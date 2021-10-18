import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:rockit/apis/spaceflightnews/api.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rockit/apis/spaceflightnews/article_response.dart';
import 'package:flutter_custom_tabs_platform_interface/flutter_custom_tabs_platform_interface.dart';

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
              );
            }
          } else if (snapshot.hasError) {
            return ErrorWidget(snapshot.error!);
          } else {
            return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}

class NewsList extends StatefulWidget {
  const NewsList(this.articles, {Key? key}) : super(key: key);

  final List<Article> articles;

  @override
  _NewsListState createState() => _NewsListState();
}

class _NewsListState extends State<NewsList> {
  String dottedText(String text) {
    if (text.endsWith(".")) {
      return text;
    }
    return text + "...";
  }

  Widget _articleCard(Article article) {
    return Center(
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        margin: const EdgeInsets.all(5),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(3, 0, 3, 0),
                child: SizedBox(
                  height: max(MediaQuery.of(context).size.height / 4, 200),
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: article.imageUrl!,
                    fadeInDuration: const Duration(milliseconds: 125),
                    fadeOutDuration: const Duration(milliseconds: 250),
                    fit: BoxFit.cover,
                    progressIndicatorBuilder:
                        (context, url, downloadProgress) => Center(
                      child: CircularProgressIndicator(
                          value: downloadProgress.progress),
                    ),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.error),
                    ),
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.articles.length,
      itemBuilder: (BuildContext context, int index) {
        return GestureDetector(
          child: _articleCard(widget.articles[index]),
          onTap: () async {
            await launch(
              widget.articles[index].url ?? "",
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
    );
  }
}
