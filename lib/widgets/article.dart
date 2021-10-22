import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rockit/mixins/date_format.dart';
import 'package:rockit/mixins/url_launcher.dart';

class ArticleCardWidget extends StatefulWidget {
  const ArticleCardWidget(
      {this.title,
      this.link,
      this.imageUrl,
      this.newsSite,
      this.summary,
      this.publishDate,
      Key? key})
      : super(key: key);

  final String? title;
  final String? link;
  final String? imageUrl;
  final String? newsSite;
  final String? summary;
  final DateTime? publishDate;

  @override
  _ArticleCardWidgetState createState() => _ArticleCardWidgetState();
}

class _ArticleCardWidgetState extends State<ArticleCardWidget>
    with UrlLauncher, DateFormatter {
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (widget.link != null) {
          await openCustomTab(context, widget.link!);
        }
      },
      child: Center(
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
                  widget.title ?? AppLocalizations.of(context)!.unknown,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if ((widget.imageUrl ?? "").isNotEmpty)
                SizedBox(
                  height: max(MediaQuery.of(context).size.height / 4, 200),
                  width: double.infinity,
                  child: Stack(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: CachedNetworkImage(
                          imageUrl: widget.imageUrl!,
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
                      if (widget.newsSite != null)
                        Container(
                          padding: EdgeInsets.zero,
                          margin: EdgeInsets.zero,
                          alignment: Alignment.bottomRight,
                          child: Text(
                            widget.newsSite!,
                            style: TextStyle(
                              backgroundColor: Theme.of(context)
                                  .backgroundColor
                                  .withOpacity(.75),
                              fontWeight: FontWeight.w500,
                              fontSize: 14.0,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  widget.summary != null
                      ? dottedText(widget.summary!)
                      : AppLocalizations.of(context)!.unknown,
                  style: const TextStyle(
                    fontSize: 15,
                  ),
                ),
              ),
              if (widget.publishDate != null)
                Container(
                  alignment: Alignment.bottomRight,
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    formatDateTimeFriendly(context, widget.publishDate!),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
