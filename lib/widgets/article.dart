import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rockit/mixins/date_format.dart';
import 'package:rockit/mixins/link_copy.dart';
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
    this.fullImage,
    Key? key,
  }) : super(key: key);

  final bool customTab;
  final bool? fullImage;

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
    with UrlLauncher, DateFormatter, LinkCopier {
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

  Widget _newsSite({bool? background}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: Container(
          color: background == true
              ? Theme.of(context).backgroundColor.withOpacity(.75)
              : null,
          padding: const EdgeInsets.all(4),
          child: Text(
            widget.newsSite!,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _renderImage() {
    final imageStack = Stack(
      children: [
        if (widget.fullImage == true)
          ImageWidget(widget.imageUrl)
        else
          // This SizedBox makes sure the image covers the entire area it's shown in,
          // cutting off parts of the image if it is too high/wide
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: ImageWidget(widget.imageUrl),
          ),
        if (widget.newsSite != null)
          Align(
            alignment: Alignment.bottomRight,
            child: _newsSite(background: true),
          ),
        if (widget.icon != null)
          Center(
            child: widget.icon,
          ),
      ],
    );

    if (widget.fullImage == true) {
      return imageStack;
    }

    return SizedBox(
      height: max(MediaQuery.of(context).size.height / 3, 200),
      child: imageStack,
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(10.0);
    final hasImage = (widget.imageUrl ?? "").isNotEmpty;
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
            onLongPress: widget.link == null
                ? null
                : () => copyLink(context, widget.link),
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
                  if (hasImage) _renderImage(),
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

                  // Show publish date and news site next to each other
                  // If we have an image, the newsSite is rendered on top of it (and thus not needed here).
                  // But if we don't have an image, we still want to display the newsSite
                  if (widget.publishDate != null ||
                      !hasImage && widget.newsSite != null)
                    Padding(
                      padding: EdgeInsets.only(
                        left: 8,
                        right: 8,
                        bottom: 4,
                        top: (widget.summary ?? "").isNotEmpty ? 0 : 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (!hasImage && widget.newsSite != null)
                            _newsSite()
                          else
                            // Put an empty box here to make sure the next widget will be right-aligned
                            const SizedBox(),
                          if (widget.publishDate != null)
                            Text(
                              formatDateTimeFriendly(
                                context,
                                widget.publishDate!,
                              ),
                            )
                        ],
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
