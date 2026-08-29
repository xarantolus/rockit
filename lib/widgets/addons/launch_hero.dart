import 'package:flutter/material.dart';
import 'package:rockit/apis/launch_library/launch_response.dart';
import 'package:rockit/l10n/app_localizations.dart';
import 'package:rockit/mixins/date_format.dart';
import 'package:rockit/time/precision_time.dart';
import 'package:rockit/widgets/addons/precision_time_text.dart';
import 'package:rockit/widgets/addons/shared_image_hero.dart';
import 'package:rockit/widgets/addons/status_pill.dart';
import 'package:rockit/widgets/image.dart';
import 'package:timezone/timezone.dart' as tz;

/// The top of a detail page: the image, the status, and the time — what it is,
/// whether it is happening, and when, in one glance.
class LaunchHero extends StatelessWidget with DateFormatter {
  const LaunchHero({
    required this.image,
    required this.title,
    this.subtitle,
    this.status,
    this.date,
    this.precision,
    this.timezoneName,
    this.heroTag,
    this.heroId,
    super.key,
  });

  final ApiImage? image;
  final String title;
  final String? subtitle;
  final LaunchStatus? status;
  final DateTime? date;
  final DatePrecision? precision;

  /// IANA zone of the launch site, used for the "at the pad" line.
  final String? timezoneName;

  /// Matches the listing card's image, so it flies from the card to here.
  final String? heroTag;
  final String? heroId;

  static const _height = 300.0;

  /// The launch time where the rocket is, which is often the number people
  /// actually discuss. Returns null when the zone database is unavailable —
  /// it is initialised by the notification handler, not guaranteed here.
  String? _siteTime(BuildContext context) {
    final at = date;
    final zone = timezoneName;
    if (at == null || zone == null || !hasUsableTime(precision)) {
      return null;
    }

    try {
      final local = tz.TZDateTime.from(at, tz.getLocation(zone));
      final here = at.toLocal();

      final sameDay =
          local.year == here.year &&
          local.month == here.month &&
          local.day == here.day;

      // Nothing worth saying only when the pad reads the same clock on the
      // same day.
      if (sameDay && local.hour == here.hour && local.minute == here.minute) {
        return null;
      }

      // Nearly half of launches fall on a different calendar day at the pad,
      // and a bare time there reads as today.
      return sameDay
          ? formatTime(context, local)
          : formatDateTime(context, local);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final siteTime = _siteTime(context);
    final showsCountdown =
        timeDisplayFor(date, precision) == TimeDisplay.countdown;

    return SizedBox(
      height: _height,
      child: SharedImageHero(
        tag: heroTag == null || heroId == null ? null : "$heroTag-$heroId",
        image: _backdrop(context),
        overlay: Stack(
          fit: StackFit.expand,
          children: [
            // The scrim only belongs over a photo: on the colour panel below
            // it would just muddy an already dark background.
            if (image?.imageUrl != null)
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: [0.0, 0.6, 1.0],
                      colors: [
                        Color(0xF2000000),
                        Color(0x59000000),
                        Color(0x1A000000),
                      ],
                    ),
                  ),
                ),
              ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusPill(status),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if ((subtitle ?? "").isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    PrecisionTimeText(
                      date: date,
                      precision: precision,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                      countdownStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    // The viewer's own timezone is the one that matters, so it
                    // gets the brighter, larger line. Friendly, because the
                    // question is "today, tomorrow, or this week" — a full
                    // date takes longer to read and only earns its place once
                    // the launch is further out than that.
                    if (showsCountdown && date != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        formatDateTimeFriendlyText(context, date!),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    // ...and the launch site's is a quieter footnote under it.
                    if (siteTime != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          localizations.localSiteTime(siteTime),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// What the flight actually carries: the photo, or a colour panel when there
  /// is none.
  ///
  /// The placeholder rocket glyph would leave white text on a pale background
  /// in the light theme, so a saturated gradient stands in for it instead.
  Widget _backdrop(BuildContext context) {
    if (image?.imageUrl == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              const Color(0xFF11151C),
            ],
          ),
        ),
      );
    }

    return ImageWidget(image?.imageUrl);
  }
}
