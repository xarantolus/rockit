import 'package:flutter/material.dart';
import 'package:rockit/apis/launch_library/launch_response.dart';
import 'package:rockit/l10n/app_localizations.dart';
import 'package:rockit/pages/launch_details.dart';
import 'package:rockit/mixins/date_format.dart';
import 'package:rockit/mixins/link_copy.dart';
import 'package:rockit/mixins/url_launcher.dart';
import 'package:rockit/util/relative_time.dart';
import 'package:rockit/widgets/image.dart';

/// One article in the news feed.
///
/// A compact row rather than a card, so the feed can be scanned. No summary:
/// it is almost always a truncated lede that adds nothing to the headline.
class ArticleRow extends StatelessWidget
    with DateFormatter, UrlLauncher, LinkCopier {
  const ArticleRow({
    required this.title,
    required this.link,
    this.imageUrl,
    this.newsSite,
    this.publishDate,
    this.relatedLaunch,
    super.key,
  });

  final String? title;
  final String? link;
  final String? imageUrl;
  final String? newsSite;
  final DateTime? publishDate;

  /// Set only when the article names a launch we already hold in the cache, so
  /// showing it never costs an API request.
  final Launch? relatedLaunch;

  static const _imageSize = 96.0;

  String _timeText(BuildContext context) {
    final published = publishDate;
    if (published == null) {
      return "";
    }

    final localizations = AppLocalizations.of(context)!;
    final relative = relativeTime(published, DateTime.now());

    switch (relative.unit) {
      case RelativeUnit.justNow:
        return localizations.justNow;
      case RelativeUnit.minutes:
        return localizations.agoMinutes(relative.value);
      case RelativeUnit.hours:
        return localizations.agoHours(relative.value);
      case RelativeUnit.days:
        return localizations.agoDays(relative.value);
      case RelativeUnit.absolute:
        return formatDate(context, published.toLocal());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    final meta = [
      if ((newsSite ?? "").isNotEmpty) newsSite!,
      if (_timeText(context).isNotEmpty) _timeText(context),
    ].join(" · ");

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: InkWell(
        onTap: link == null ? null : () => openCustomTab(context, link!),
        onLongPress: link == null ? null : () => copyLink(context, link),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            // Centred rather than top-aligned: a two-line headline next to a
            // 96px thumbnail otherwise leaves an obvious gap beneath the text.
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: _imageSize,
                  height: _imageSize,
                  child: ImageWidget(imageUrl),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title ?? AppLocalizations.of(context)!.unknown,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: muted),
                      ),
                    ],
                    if (relatedLaunch != null) ...[
                      const SizedBox(height: 6),
                      _LaunchChip(launch: relatedLaunch!),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tapping this opens the launch the article is about, rather than the article.
class _LaunchChip extends StatelessWidget {
  const _LaunchChip({required this.launch});

  final Launch launch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = launch.name ?? AppLocalizations.of(context)!.relatedLaunch;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => LaunchDetailsPage(launch))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.rocket_launch,
              size: 13,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
