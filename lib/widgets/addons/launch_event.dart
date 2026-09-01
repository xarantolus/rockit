import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rockit/apis/launch_library/launch_response.dart';
import 'package:rockit/widgets/addons/columns.dart';
import 'package:rockit/widgets/addons/precision_time_text.dart';
import 'package:rockit/widgets/addons/shared_image_hero.dart';
import 'package:rockit/widgets/addons/status_pill.dart';
import 'package:rockit/widgets/image.dart';

/// The card used for both launches and events in the listings.
///
/// The image runs to the edges under a gradient scrim rather than a flat bar,
/// and the status and a [precision]-aware date together answer "is this
/// happening, and when".
class LaunchEventWidget extends StatelessWidget {
  const LaunchEventWidget({
    required this.title,
    required this.subtitle,
    this.image,
    this.status,
    this.date,
    this.precision,
    this.heroTag,
    this.heroId,
    super.key,
  });

  final ApiImage? image;

  final String? heroTag;
  final String? heroId;

  final String title;

  /// Null when it is genuinely not known — the line is then left out.
  final String? subtitle;

  final LaunchStatus? status;

  final DateTime? date;
  final DatePrecision? precision;

  /// The photos are a mix of 16:9 and 3:2, so there is no ratio that crops
  /// nothing. 3:2 keeps the image the largest thing on the card.
  static const aspectRatio = 3 / 2;

  /// Past this the card stops growing and the photo crops instead, so a wide
  /// window does not show one enormous card.
  static const maxHeight = 360.0;

  static const margin = EdgeInsets.fromLTRB(10, 6, 10, 6);

  /// Shared with the flight, which lerps it out to square as the card opens.
  static const radius = BorderRadius.all(Radius.circular(14.0));

  static double _getWidth(BuildContext context) {
    try {
      return MediaQuery.of(context).size.width;
    } catch (_) {}

    final view = PlatformDispatcher.instance.implicitView;
    if (view == null) {
      return 0;
    }
    return view.physicalSize.width / view.devicePixelRatio;
  }

  /// How tall the card is when it has [availableWidth] to fill.
  ///
  /// Its own width, deliberately: this used to be a third of the *screen
  /// height*, so the same card grew taller on every taller device until a 20:9
  /// phone showed one card per screen and a short one showed three.
  static double heightForWidth(double availableWidth) {
    final cardWidth = max(availableWidth - margin.horizontal, 0.0);

    return min(cardWidth / aspectRatio, maxHeight) + margin.vertical;
  }

  static double calculateHeight(BuildContext context, {int columns = 1}) {
    return heightForWidth(_getWidth(context) / max(columns, 1));
  }

  /// How many cards fit side by side in [width].
  ///
  /// Derived from the width rather than the orientation, which is what left a
  /// tablet in portrait showing one card per row across 667dp. Aiming at a
  /// column of roughly [_idealColumnWidth] keeps a card about the size it is on
  /// a phone: one column on a phone, two in landscape or on a tablet held
  /// upright, three on a tablet turned sideways.
  static int columnsFor(double width) => columnsForWidth(width);

  static int columnsForContext(BuildContext context) {
    return columnsFor(_getWidth(context));
  }

  /// The card is full width and a third of the screen tall, so it always wants
  /// the full image — a 256px thumbnail would upscale into mush here.
  String? _imageUrl(BuildContext context) {
    final media = MediaQuery.of(context);
    final widthPixels = media.size.width * media.devicePixelRatio;

    return image?.urlFor(widthPixels);
  }

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder rather than the screen width: in a landscape grid the card
    // only gets half of it, and the card should size to what it actually has.
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : LaunchEventWidget._getWidth(context);

        return SizedBox(
          height: LaunchEventWidget.heightForWidth(available),
          child: Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: LaunchEventWidget.radius,
            ),
            elevation: 2,
            margin: LaunchEventWidget.margin,
            // The whole block flies to the detail page, image and overlay
            // together, so nothing on either end is hidden behind it.
            child: SharedImageHero(
              tag: heroTag == null || heroId == null
                  ? null
                  : "$heroTag-$heroId",
              borderRadius: LaunchEventWidget.radius,
              image: ImageWidget(_imageUrl(context)),
              overlay: Stack(
                fit: StackFit.expand,
                children: [
                  const Positioned.fill(child: _CardScrim()),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: _CardInfo(
                      title: title,
                      subtitle: subtitle,
                      date: date,
                      precision: precision,
                    ),
                  ),
                  if (status != null)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: StatusPill(status, compact: true),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The same gradient on every card, so it is built once and reused rather than
/// rebuilt per item.
class _CardScrim extends StatelessWidget {
  const _CardScrim();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          // Only as dark as the text needs. At 0xE6 the bottom of every card
          // was effectively pure black — measured L=0.004, a contrast of
          // 19.6:1 against white text where 4.5:1 is the bar — so the photo
          // simply stopped existing there, which reads worst in the dark
          // theme where the card then blends into the page.
          stops: [0.0, 0.55, 1.0],
          colors: [Color(0xC2000000), Color(0x3D000000), Color(0x00000000)],
        ),
      ),
    );
  }
}

class _CardInfo extends StatelessWidget {
  const _CardInfo({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.precision,
  });

  final String title;
  final String? subtitle;
  final DateTime? date;
  final DatePrecision? precision;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19.0,
              height: 1.15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: subtitle == null
                    ? const SizedBox.shrink()
                    : Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14.0,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              PrecisionTimeText(
                date: date,
                precision: precision,
                // A local time reads better than a wall of ticking clocks;
                // the countdown is on the page you open.
                showCountdown: false,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
