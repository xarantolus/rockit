import 'package:flutter/material.dart';
import 'package:rockit/theme.dart';
import 'package:rockit/apis/launch_library/launch_response.dart';
import 'package:rockit/l10n/app_localizations.dart';
import 'package:rockit/widgets/addons/time_refresh.dart';
import 'package:rockit/apis/launch_library/events_response.dart';
import 'package:rockit/pages/event_details.dart';
import 'package:rockit/pages/launch_details.dart';
import 'package:rockit/mixins/date_format.dart';
import 'package:rockit/mixins/link_copy.dart';
import 'package:rockit/mixins/url_launcher.dart';
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
    this.relatedLaunches = const [],
    this.relatedEvents = const [],
    super.key,
  });

  final String? title;
  final String? link;
  final String? imageUrl;
  final String? newsSite;
  final DateTime? publishDate;

  /// The launches this article names that are already in the cache, so showing
  /// them never costs an API request. An article can name several — a launch
  /// roundup names every launch of the week — and showing only the first made
  /// it look like it was about that one.
  final List<Launch> relatedLaunches;

  /// Same, for the events it names.
  final List<Event> relatedEvents;

  static const _imageSize = 96.0;

  /// The same local, friendly wording the launch and event cards use —
  /// "Today, 11:26" — rather than an age in hours. One way of saying when
  /// something is, everywhere.
  String _timeText(BuildContext context) {
    final published = publishDate;

    return published == null
        ? ""
        : formatDateTimeFriendlyText(context, published.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

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
                  child: ImageWidget(imageUrl, shortLived: true),
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
                    // The date is written relative to today, so it has to be
                    // looked at again when the day turns over.
                    MidnightRefresh(
                      builder: (context) {
                        final meta = [
                          if ((newsSite ?? "").isNotEmpty) newsSite!,
                          if (_timeText(context).isNotEmpty) _timeText(context),
                        ].join(" · ");

                        if (meta.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12.5, color: muted),
                          ),
                        );
                      },
                    ),
                    if (relatedLaunches.isNotEmpty ||
                        relatedEvents.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final launch in relatedLaunches)
                            _RelatedChip(
                              icon: Icons.rocket_launch,
                              label:
                                  launch.name ??
                                  AppLocalizations.of(context)!.relatedLaunch,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => LaunchDetailsPage(launch),
                                ),
                              ),
                            ),
                          for (final event in relatedEvents)
                            _RelatedChip(
                              icon: Icons.event,
                              label:
                                  event.name ??
                                  AppLocalizations.of(context)!.relatedLaunch,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => EventDetailsPage(event),
                                ),
                              ),
                            ),
                        ],
                      ),
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
class _RelatedChip extends StatelessWidget {
  const _RelatedChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: theme.colorScheme.surfaceAccent),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.surfaceAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One row of article cards, side by side.
///
/// The news lists stay `ListView.builder`s over *rows* rather than becoming
/// grids, because an article card has no fixed height — a one-line headline
/// with no chip is much shorter than a three-line one with a launch attached,
/// and a grid would have to pick a single extent for both, clipping the tall
/// ones or padding out the short ones. Cards within a row stretch to match
/// each other, which is what makes the row read as a row.
class ArticleRowGroup extends StatelessWidget {
  const ArticleRowGroup({
    required this.columns,
    required this.children,
    super.key,
  });

  final int columns;
  final List<Widget> children;

  /// The number of rows [count] articles need in [columns] columns.
  static int rowCount(int count, int columns) =>
      (count + columns - 1) ~/ columns;

  @override
  Widget build(BuildContext context) {
    if (columns == 1) {
      return children.first;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < columns; i++)
            // A short final row leaves empty columns rather than letting one
            // card stretch across the whole width.
            Expanded(
              child: i < children.length
                  ? children[i]
                  : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}
