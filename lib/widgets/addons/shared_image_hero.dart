import 'package:flutter/material.dart';

/// The image-and-overlay block a listing card shares with its detail page.
///
/// The whole composite flies, not just the photo: a [Hero] paints in the
/// navigator's overlay, above every route, so anything the flight leaves
/// behind is hidden until it lands and then appears all at once.
class SharedImageHero extends StatelessWidget {
  const SharedImageHero({
    required this.tag,
    required this.image,
    required this.overlay,
    this.borderRadius = BorderRadius.zero,
    super.key,
  });

  /// Null flies nothing, for when there is no stable id to match on.
  final String? tag;

  final Widget image;

  /// Everything drawn over the image: scrim, text, status pill.
  final Widget overlay;

  /// Lerped across the flight: the card end is rounded, the page end is not.
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
          // A flight paints outside the page's Material, and Text without one
          // falls back to the debug style: yellow underlines, mid-flight.
          child: Material(
            type: MaterialType.transparency,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Once, opaque. Cross-fading two copies of the same photo dips
                // in the middle — `over` compositing is not additive.
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

/// 0 where the flight started, 1 where it is going, either direction.
///
/// The animation counts down on a pop while `from` and `to` also swap ends.
/// Apply one inversion without the other and the cross-fade runs backwards.
@visibleForTesting
double flightProgress(HeroFlightDirection direction, double animationValue) {
  final value = animationValue.clamp(0.0, 1.0);

  return direction == HeroFlightDirection.push ? value : 1 - value;
}

/// Where the two overlays stand at [progress] along the flight.
///
/// Swapped through the middle rather than spread across the whole flight: both
/// ends put the same facts in different places, so a linear fade shows two of
/// everything at half strength and reads as a ghost.
@visibleForTesting
double overlayCrossFade(double progress) {
  const start = 0.2;
  const end = 0.7;

  final t = ((progress - start) / (end - start)).clamp(0.0, 1.0);

  return Curves.easeInOut.transform(t);
}

/// Named so [SharedImageHero.buildFlight] can reach the image and the overlay
/// separately — a shuttle only receives the two [Hero] widgets.
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
