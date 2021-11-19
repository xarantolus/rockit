import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rockit/mixins/date_format.dart';
import 'package:rockit/mixins/url_launcher.dart';
import 'package:rockit/widgets/image.dart';
import 'package:url_launcher/url_launcher.dart';

class ArticleCardWidget extends StatefulWidget {
  const ArticleCardWidget({
    this.title,
    this.link,
    this.imageUrl,
    this.newsSite,
    this.summary,
    this.publishDate,
    this.icon,
    this.customTab = true,
    Key? key,
  }) : super(key: key);

  final bool customTab;

  final String? title;
  final String? link;
  final String? imageUrl;
  final String? newsSite;
  final String? summary;
  final DateTime? publishDate;
  final Icon? icon;

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
    final radius = BorderRadius.circular(10.0);
    return Center(
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: radius,
        ),
        margin: const EdgeInsets.fromLTRB(10, 5, 10, 5),
        child: Material(
          color: Theme.of(context).cardColor,
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: () async {
              setState(() {});
              if (widget.link != null) {
                if (widget.customTab) {
                  await openCustomTab(context, widget.link!);
                } else {
                  await launch(widget.link!);
                }
              }
            },
            child: Container(
              margin: (widget.summary ?? "").isEmpty
                  ? const EdgeInsets.only(bottom: 8)
                  : EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      widget.title ?? AppLocalizations.of(context)!.unknown,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
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
                            child: ImageWidget(widget.imageUrl),
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
                          if (widget.icon != null)
                            Center(
                              child: widget.icon,
                            ),
                        ],
                      ),
                    ),
                  if ((widget.summary ?? "").isNotEmpty)
                    Padding(
                      padding: widget.imageUrl == null
                          ? const EdgeInsets.fromLTRB(8, 2, 8, 8)
                          : const EdgeInsets.fromLTRB(8, 8, 8, 4),
                      child: Text(
                        dottedText(widget.summary!),
                        style: const TextStyle(
                          fontSize: 15,
                        ),
                      ),
                    ),
                  if (widget.publishDate != null)
                    Container(
                      alignment: Alignment.bottomRight,
                      padding: const EdgeInsets.fromLTRB(0, 0, 4, 4),
                      child: Text(
                        formatDateTimeFriendly(context, widget.publishDate!),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
