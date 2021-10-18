import 'package:flutter/material.dart';
import 'package:rockit/apis/spaceflightnews/api.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rockit/apis/spaceflightnews/article_response.dart';

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
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.articles.length,
      itemBuilder: (BuildContext context, int index) {
        return Text(widget.articles[index].title ?? "Unknown");
      },
    );
  }
}
