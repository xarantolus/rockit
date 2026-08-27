import 'package:flutter/material.dart';
import 'package:rockit/apis/launch_library/common.dart';
import 'package:rockit/apis/launch_library/launch_response.dart';
import 'package:rockit/l10n/app_localizations.dart';
import 'package:rockit/mixins/date_format.dart';
import 'package:rockit/time/precision_time.dart';
import 'package:rockit/widgets/addons/precision_time_text.dart';
import 'package:rockit/widgets/addons/status_pill.dart';
import 'package:rockit/widgets/image.dart';
import 'package:timezone/timezone.dart' as tz;

/// The top of a detail page: the image, the status, and the time.
///
/// These three answer "what is this, is it happening, and when" in one glance,
/// which the old layout could not — it opened on an image, then a mission
/// description, and only mentioned status in a table several screens down.
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
      // Same wall clock as the viewer: nothing extra to say.
      if (local.hour == at.toLocal().hour &&
          local.minute == at.toLocal().minute) {
        return null;
      }

      return formatTime(context, local);
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
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Without a photo the placeholder is a rocket glyph on a plain
          // background — a dark scrim and white text over that is illegible in
          // the light theme, so fall back to a solid colour panel instead.
          if (image?.imageUrl == null)
            DecoratedBox(
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
            )
          else ...[
            ImageWidget(image?.imageUrl, heroTag: heroTag, id: heroId),
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
          ],
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
                  // gets the brighter, larger line...
                  if (showsCountdown && date != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      formatDateTimeLocal(context, date!),
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
    );
  }
}
