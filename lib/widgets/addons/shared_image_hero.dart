import 'package:flutter/material.dart';

/// The image-and-overlay block a listing card shares with its detail page.
///
/// The whole composite flies, not just the photo. A [Hero] lifts its widget
/// into the navigator's *overlay*, which paints above every route, so a flight
/// carrying only the image covers everything drawn on top of it at the far end
/// — the scrim, the status pill, the countdown — for the entire flight, and
/// they then appear all at once when the overlay is torn down. Fading them in
/// does not help: fading while occluded changes nothing, and fading afterwards
/// is just a slower snap, disconnected from the motion.
///
/// Carrying the overlay along means what lands is already what the page shows,
/// so there is nothing left to appear.
class SharedImageHero extends StatelessWidget {
  const SharedImageHero({
    required this.tag,
    required this.image,
    required this.overlay,
    this.borderRadius = BorderRadius.zero,
    super.key,
  });

  /// Null disables the flight entirely — used when there is no stable id to
  /// match on, since two heroes cannot share a tag on one route.
  final String? tag;

  final Widget image;

  /// Everything drawn over the image: scrim, text, status pill.
  final Widget overlay;

  /// The card end is rounded and the detail end is not, so this lerps across
  /// the flight rather than popping square the moment it takes off.
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final content = HeroImageContent(
      image: image,
      overlay: overlay,
      borderRadius: borderRadius,
    );

    if (tag == null) {
      return content;
    }

    return Hero(tag: tag!, flightShuttleBuilder: buildFlight, child: content);
  }

  @visibleForTesting
  static Widget buildFlight(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    final from = (fromHeroContext.widget as Hero).child as HeroImageContent;
    final to = (toHeroContext.widget as Hero).child as HeroImageContent;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final progress = flightProgress(direction, animation.value);
        final fade = overlayCrossFade(progress);

        return ClipRRect(
          borderRadius:
              BorderRadius.lerp(from.borderRadius, to.borderRadius, progress) ??
              BorderRadius.zero,
          // A flight renders in the navigator's overlay, outside the Material
          // the page provides, and Text with no Material ancestor falls back
          // to the debug style — yellow double underlines in a fallback font,
          // for the length of every flight. Transparency, so this adds a text
          // ancestor without painting anything over the photo.
          child: Material(
            type: MaterialType.transparency,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Drawn once and fully opaque. Both ends show the same photo, and
                // cross-fading two stacks that each contain it would dip to
                // about three quarters in the middle: `over` compositing is not
                // additive, so two half-transparent copies do not add up to one.
                to.image,
                Opacity(opacity: 1 - fade, child: from.overlay),
                Opacity(opacity: fade, child: to.overlay),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// How far along the flight is: 0 where it started, 1 where it is going,
/// whichever direction that happens to be.
///
/// Worth spelling out, because the framework's two conventions pull opposite
/// ways. The flight animation is the *pushed* route's on a push, running 0 to
/// 1, but the *popped* route's on a pop, running 1 to 0 — while
/// `fromHeroContext` and `toHeroContext` swap ends with the direction. Read
/// either one without the other and the cross-fade runs backwards.
@visibleForTesting
double flightProgress(HeroFlightDirection direction, double animationValue) {
  final value = animationValue.clamp(0.0, 1.0);

  return direction == HeroFlightDirection.push ? value : 1 - value;
}

/// Where the two overlays stand at [progress] along the flight.
///
/// Deliberately not spread across the whole flight. The two ends say the same
/// things in different places and sizes — the card's time is small and
/// right-aligned, the page's countdown is large and left-aligned — so a linear
/// cross-fade spends the middle showing both at half strength, which reads as
/// a ghost rather than a morph. Holding each end and swapping quickly through
/// the middle keeps the ambiguous stretch to about a third of an already short
/// animation.
@visibleForTesting
double overlayCrossFade(double progress) {
  const start = 0.2;
  const end = 0.7;

  final t = ((progress - start) / (end - start)).clamp(0.0, 1.0);

  return Curves.easeInOut.transform(t);
}

/// The three pieces a flight needs to take apart and recombine.
///
/// A named type rather than a bare [Stack] so [SharedImageHero.buildFlight] can
/// reach the image and the overlay separately: a shuttle only receives the two
/// [Hero] widgets, so whatever they wrap has to be inspectable.
class HeroImageContent extends StatelessWidget {
  const HeroImageContent({
    required this.image,
    required this.overlay,
    required this.borderRadius,
    super.key,
  });

  final Widget image;
  final Widget overlay;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(fit: StackFit.expand, children: [image, overlay]),
    );
  }
}
