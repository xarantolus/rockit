import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:rockit/apis/launch_library/common.dart';
import 'package:rockit/apis/launch_library/launch_response.dart';
import 'package:rockit/widgets/addons/precision_time_text.dart';
import 'package:rockit/widgets/addons/status_pill.dart';
import 'package:rockit/widgets/image.dart';

/// The card used for both launches and events in the listings.
///
/// The image runs to the edges and the text sits on a gradient scrim rather
/// than a flat grey bar, so the photo is not cut in half by a slab of chrome.
/// Two things were added to what the card used to say — the status and a date
/// that respects [precision] — because between them they answer "is this
/// actually happening, and when", which the old card could not.
class LaunchEventWidget extends StatefulWidget {
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
  final String subtitle;

  final LaunchStatus? status;

  final DateTime? date;
  final DatePrecision? precision;

  static double _getHeight(BuildContext context) {
    try {
      return MediaQuery.of(context).size.height;
    } catch (_) {}

    final view = PlatformDispatcher.instance.implicitView;
    if (view == null) {
      return 0;
    }
    return view.physicalSize.height / view.devicePixelRatio;
  }

  static double calculateHeight(BuildContext context) {
    return max(_getHeight(context) / 3, 250);
  }

  @override
  State<LaunchEventWidget> createState() => _LaunchEventWidgetState();
}

class _LaunchEventWidgetState extends State<LaunchEventWidget> {
  /// The card is full width and a third of the screen tall, so it always wants
  /// the full image — a 256px thumbnail would upscale into mush here.
  String? _imageUrl(BuildContext context) {
    final media = MediaQuery.of(context);
    final widthPixels = media.size.width * media.devicePixelRatio;

    return widget.image?.urlFor(widthPixels);
  }

  Widget _scrim() {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          stops: [0.0, 0.55, 1.0],
          colors: [Color(0xE6000000), Color(0x66000000), Color(0x00000000)],
        ),
      ),
    );
  }

  Widget _info(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
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
                child: Text(
                  widget.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 14.0),
                ),
              ),
              const SizedBox(width: 10),
              PrecisionTimeText(
                date: widget.date,
                precision: widget.precision,
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: LaunchEventWidget.calculateHeight(context),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.0),
        ),
        elevation: 2,
        margin: const EdgeInsets.fromLTRB(10, 6, 10, 6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ImageWidget(
              _imageUrl(context),
              heroTag: widget.heroTag,
              id: widget.heroId,
            ),
            Positioned.fill(child: _scrim()),
            Align(alignment: Alignment.bottomLeft, child: _info(context)),
            if (widget.status != null)
              Positioned(
                top: 10,
                right: 10,
                child: StatusPill(widget.status, compact: true),
              ),
          ],
        ),
      ),
    );
  }
}
