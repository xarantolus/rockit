import 'package:flutter/material.dart';
import 'package:rockit/apis/launch_library/common.dart';
import 'package:rockit/mixins/attribution.dart';
import 'package:rockit/widgets/article.dart';

/// One of the API's `info_urls` or `vid_urls` as a card.
///
/// Shared by the launch and event pages, which render them identically.
class ContentUrlCard extends StatelessWidget with SourceAttribution {
  ContentUrlCard(this.info, {this.customTab = true, this.icon, super.key});

  final ContentUrl info;
  final bool customTab;
  final Icon? icon;

  @override
  Widget build(BuildContext context) {
    final title = info.title?.trim();
    final description = info.description?.trim();

    return ArticleCardWidget(
      title: info.title,
      link: info.url,
      imageUrl: info.featureImage,
      newsSite: urlHost(info.url),
      // The API often repeats the title as the description, and a card that
      // says the same thing twice just looks broken.
      summary: description == title ? null : info.description,
      customTab: customTab,
      icon: icon,
      // These sit inside a DetailCard already, and a card inside a card just
      // draws two edges around the same thing.
      flat: true,
    );
  }
}
