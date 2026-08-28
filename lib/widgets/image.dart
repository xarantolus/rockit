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

  /// How large this may be decoded, in physical pixels, or null for an
  /// unbounded box.
  ///
  /// Decoding is why a *cached* image can still sit on the spinner: a 1920x1280
  /// photo is 9.8 MB of RGBA however small it is drawn, and the news list did
  /// that once a row.
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
  /// Built by hand because [CachedNetworkImage] only forwards its
  /// `memCache*` sizes under [ResizeImagePolicy.exact], which distorts when
  /// both are given and needs a known orientation when only one is.
  /// [ResizeImagePolicy.fit] takes the pair as a bounding box instead.
  Widget _image(BuildContext context, String? imageURL, int? bound) {
    if (imageURL == null) {
      return _defaultImage();
    }

    try {
      final ImageProvider source = CachedNetworkImageProvider(
        kIsWeb ? "https://fuckcors.app/$imageURL" : imageURL,
        cacheManager: _imageCache,
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

  /// Bounded and dimmed: a placeholder, not content. Left alone the asset
  /// fills whatever box it is given.
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

  // No Hero here: SharedImageHero flies the whole image-and-overlay block.
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
/// Doubled so a fit-inside resize still covers the box at any orientation, and
/// bucketed so the number holds still while the box moves — it is part of the
/// image cache key, and a hero flight resizes its box every frame.
int decodeBucketFor(double physicalPixels) {
  final wanted = physicalPixels * 2;
  final rounded = (wanted / _bucket).ceil() * _bucket;

  return rounded.clamp(_bucket, _maxBound);
}

final BaseCacheManager? _imageCache = () {
  try {
    return CacheManager(Config('images', stalePeriod: const Duration(days: 7)));
  } catch (e) {
    debugPrint("Could not initialize cache manager: $e");
  }
  return null;
}();

/// Downloads pictures into the same store [ImageWidget] reads from, for a tab
/// the user has not opened yet.
///
/// One at a time and only the first few, so a tab nobody is looking at cannot
/// crowd out the one they are.
Future<void> warmImages(Iterable<String?> urls, {int limit = 4}) async {
  final cache = _imageCache;
  if (cache == null || kIsWeb) {
    return;
  }

  for (final url
      in urls.whereType<String>().where((u) => u.isNotEmpty).take(limit)) {
    try {
      await cache.downloadFile(url);
    } catch (e) {
      debugPrint("Could not warm image $url: $e");
    }
  }
}
