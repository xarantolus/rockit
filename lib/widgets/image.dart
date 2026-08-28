import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ImageWidget extends StatefulWidget {
  const ImageWidget(this.imageURL, {super.key});

  final String? imageURL;

  @override
  State<ImageWidget> createState() => _ImageWidgetState();
}

class _ImageWidgetState extends State<ImageWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static final BaseCacheManager? _cacheManager = () {
    try {
      return CacheManager(
        Config('images', stalePeriod: const Duration(days: 7)),
      );
    } catch (e) {
      debugPrint("Could not initialize cache manager: $e");
    }
    return null;
  }();

  /// How large the image is allowed to be decoded, in physical pixels, or null
  /// when the box is unbounded and there is nothing to go on.
  ///
  /// Decoding is what makes a *cached* image sit on the loading spinner: a
  /// 1920x1280 photo costs about 9.8 MB of RGBA however small it is drawn, and
  /// the news list decoded one per row because SpaceFlightNews articles have no
  /// thumbnail variant to fall back to. Bounding the decode fixes that without
  /// touching what is stored.
  ///
  /// Twice the longest edge of the box. The bound is a square that the image is
  /// scaled to fit *inside*, so the headroom is what guarantees it still covers
  /// the box afterwards — at 2x that holds for anything between roughly 1:2 and
  /// 2:1, whichever way round it is. Nothing here assumes an orientation.
  ///
  /// Rounded up to [_bucket] because the size is part of the image cache key,
  /// and the box this is measured from is not always still. A hero flight
  /// interpolates it on every frame, so an exact bound would mint a new key
  /// sixty times a second and decode the picture again for each one — the one
  /// way this could genuinely cause jank. Buckets also collapse the listing
  /// card and the detail page, which are both full width, into a single decode
  /// rather than two.
  ///
  /// [_maxBound] sits above anything either API serves (1920x1280 at the
  /// largest), so full-width boxes land there and are never resized at all;
  /// `allowUpscaling: false` leaves them at their natural size.
  int? _decodeBound(BoxConstraints constraints, double devicePixelRatio) {
    final longest = max(
      constraints.maxWidth.isFinite ? constraints.maxWidth : 0.0,
      constraints.maxHeight.isFinite ? constraints.maxHeight : 0.0,
    );

    if (longest <= 0) {
      return null;
    }

    return decodeBucketFor(longest * devicePixelRatio);
  }

  /// The image, decoded no larger than [bound] square.
  ///
  /// Assembled by hand rather than with [CachedNetworkImage], which only
  /// forwards `memCacheWidth`/`memCacheHeight` to [ResizeImage] under its
  /// default [ResizeImagePolicy.exact]: passing both distorts the picture, and
  /// passing one is only correct if you already know which way round the source
  /// is. [ResizeImagePolicy.fit] treats the pair as a bounding box and keeps the
  /// aspect ratio, so it needs to be built here.
  ///
  /// Resizing on *disk* instead (`maxWidthDiskCache`) was the other candidate
  /// and is worse on every count: it keeps the original alongside a second copy
  /// under its own key and re-encodes that copy as PNG, which for photographs
  /// is larger than the JPEG it came from. Measured over the same run of the
  /// news feed it took the image cache from 73.9 MB to 81.0 MB.
  Widget _image(BuildContext context, String? imageURL, int? bound) {
    if (imageURL == null) {
      return _defaultImage();
    }

    try {
      final ImageProvider source = CachedNetworkImageProvider(
        kIsWeb ? "https://fuckcors.app/$imageURL" : imageURL,
        cacheManager: _cacheManager,
      );

      return Image(
        image: bound == null
            ? source
            : ResizeImage(
                source,
                width: bound,
                height: bound,
                policy: ResizeImagePolicy.fit,
                allowUpscaling: false,
              ),
        fit: BoxFit.cover,
        // Keeps the previous picture up while a new one decodes, rather than
        // dropping to the spinner and back.
        gaplessPlayback: true,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) {
            return child;
          }

          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 125),
            child: child,
          );
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) {
            return child;
          }

          final total = progress.expectedTotalBytes;

          return Center(
            child: CircularProgressIndicator(
              value: total == null
                  ? null
                  : progress.cumulativeBytesLoaded / total,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _defaultImage(),
      );
    } catch (e) {
      debugPrint("Error creating cached network image for $imageURL: $e");

      return _defaultImage();
    }
  }

  /// Bounded and dimmed, because this is a placeholder rather than content.
  ///
  /// Left to itself the asset fills whatever box it is given, which in a
  /// launch-pad card with no map meant a rocket the height of the card, and in
  /// a listing card meant a huge glyph competing with the title.
  Widget _defaultImage() {
    final light = Theme.of(context).brightness == Brightness.light;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Opacity(
          opacity: 0.3,
          child: Image.asset(
            light ? "assets/rocket-black.png" : "assets/rocket-white.png",
            width: 88,
            height: 88,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  // Deliberately no Hero here. The shared-element flight carries the whole
  // image-and-overlay block instead (SharedImageHero); flying only the image
  // hid everything drawn over it for the length of the flight.
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return LayoutBuilder(
      builder: (context, constraints) => _image(
        context,
        widget.imageURL,
        _decodeBound(constraints, MediaQuery.devicePixelRatioOf(context)),
      ),
    );
  }
}

const _bucket = 256;
const _maxBound = 2048;

/// The decode bound for a box whose longest edge is [physicalPixels].
///
/// Twice the box, rounded up to a bucket. Doubling is the headroom that keeps a
/// fit-inside resize large enough to still cover the box; bucketing is what
/// keeps the number stable while the box moves.
int decodeBucketFor(double physicalPixels) {
  final wanted = physicalPixels * 2;
  final rounded = (wanted / _bucket).ceil() * _bucket;

  return rounded.clamp(_bucket, _maxBound);
}
