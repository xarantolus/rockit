import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:rockit/apis/bounded_image_service.dart';

class ImageWidget extends StatefulWidget {
  const ImageWidget(this.imageURL, {this.shortLived = false, super.key});

  final String? imageURL;

  /// True for a thumbnail that goes stale with its article rather than one
  /// worth keeping, which picks the seven-day store instead of the sixty-day
  /// one. See [_articleImageCache].
  final bool shortLived;

  @override
  State<ImageWidget> createState() => _ImageWidgetState();
}

/// Deliberately not an [AutomaticKeepAliveClientMixin] client.
///
/// It used to be, and that quietly disabled the image cache: Flutter never
/// evicts a *live* image, and keeping every row mounted keeps every image it
/// ever built live. Measured while scrolling, `liveImageCount` equalled the
/// whole cache — 36 images and 283 MB with nothing evictable, growing with how
/// far you had scrolled. Letting rows recycle moves an off-screen decode into
/// the evictable half of the cache, where the byte budget can bound it.
///
/// Scrolling back does not refetch: the bytes are still in
/// `flutter_cache_manager` for days, so the worst case is decoding a local
/// file again, and the budget is sized so that normally does not happen
/// either.
class _ImageWidgetState extends State<ImageWidget> {
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
      return const ImagePlaceholder();
    }

    try {
      // Straight to the origin, on the web too. This used to go through a
      // third-party CORS proxy, which has since stopped resolving at all —
      // so every picture on the web build was the placeholder. It is not
      // needed: both image hosts answer with `access-control-allow-origin: *`.
      final ImageProvider source = CachedNetworkImageProvider(
        imageURL,
        cacheManager: widget.shortLived ? _articleImageCache : _imageCache,
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
        errorBuilder: (context, error, stackTrace) => const ImagePlaceholder(),
      );
    } catch (e) {
      debugPrint("Error creating cached network image for $imageURL: $e");

      return const ImagePlaceholder();
    }
  }

  // No Hero here: SharedImageHero flies the whole image-and-overlay block.
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => _image(
        context,
        widget.imageURL,
        _decodeBound(constraints, MediaQuery.devicePixelRatioOf(context)),
      ),
    );
  }
}

/// Shown when there is no picture, or the one there is will not load.
///
/// Sized from its box rather than fixed at 88px inside 24px of padding, which
/// collapsed to nothing in anything small: a 44px crew avatar and the 96px
/// news thumbnails rendered an empty hole where a missing image should be.
class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = min(
          constraints.hasBoundedWidth ? constraints.maxWidth : 136.0,
          constraints.hasBoundedHeight ? constraints.maxHeight : 136.0,
        );

        return Center(
          child: Image.asset(
            light ? "assets/rocket-black.png" : "assets/rocket-white.png",
            width: side * 0.6,
            height: side * 0.6,
            fit: BoxFit.contain,
            // A dimmed colour rather than an Opacity layer, which the
            // performance guidance says to avoid for simple content.
            color: Colors.white.withValues(alpha: 0.3),
            colorBlendMode: BlendMode.modulate,
          ),
        );
      },
    );
  }
}

const _bucket = 256;

/// The widest a decode ever gets.
///
/// A full-width card is about 1100 physical pixels on a phone, and the API's
/// photos are at most 1920x1280, so a 2048 ceiling meant every card held the
/// picture at full size: 9.8 MB each, and 45 of them on screen after a detail
/// page filled the entire image cache. 1280 still covers a full-width box for
/// anything up to a 16:9 photo, at 4.4 MB.
const _maxBound = 1280;

/// The decode bound for a box whose longest edge is [physicalPixels].
///
/// Larger than the box because the resize fits the image *inside* a square of
/// this size while the box is filled with `BoxFit.cover`: a landscape photo
/// scaled to fit 1000 wide is only 667 tall, so it would be stretched to cover
/// a 1000x667 box exactly and blurred in anything taller.
///
/// Bucketed so the number holds still while the box moves — it is part of the
/// image cache key, and a hero flight resizes its box every frame.
int decodeBucketFor(double physicalPixels) {
  final wanted = physicalPixels * 1.5;
  final rounded = (wanted / _bucket).ceil() * _bucket;

  return rounded.clamp(_bucket, _maxBound);
}

/// Article and link-preview thumbnails, kept on a much shorter leash.
///
/// A launch photo is worth keeping: it is shown large, it is the same picture
/// every time you open that launch, and there are only so many of them. A news
/// thumbnail is the opposite — the feed moves on within days, the picture is
/// drawn at 96 dp, and the biggest files in the whole cache are these. Seven
/// days is longer than the feed stays interesting.
final BaseCacheManager? _articleImageCache = () {
  try {
    return CacheManager(
      Config(
        'article-images',
        stalePeriod: const Duration(days: 7),
        maxNrOfCacheObjects: 150,
        fileService: BoundedImageFileService(),
      ),
    );
  } catch (e) {
    debugPrint("Could not initialize the article image cache: $e");
  }
  return null;
}();

final BaseCacheManager? _imageCache = () {
  try {
    return CacheManager(
      Config(
        'images',
        // Both of these are measured from the last *read*: the package
        // refreshes `touched` on every lookup that reaches its database, and
        // both `getOldObjects` and `getObjectsOverCapacity` key off that. So
        // this is a genuine least-recently-used bound, and it is the one that
        // should normally do the work.
        //
        // Long, because an image at a URL does not change — expiring one only
        // means downloading it again — and short of that nothing here goes
        // out of date the way a response does.
        stalePeriod: const Duration(days: 60),
        // Sized so this, and not CacheJanitor's byte budget, is what usually
        // bites: images average ~350 KB once bounded, so 300 of them is about
        // 105 MB against a 128 MB budget. The janitor cannot order by last
        // use — Android mounts /data `noatime`, so the filesystem never
        // records a read — and falling back to write time would evict a photo
        // that is looked at daily just for being old.
        maxNrOfCacheObjects: 300,
        fileService: BoundedImageFileService(),
      ),
    );
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
Future<void> warmImages(
  Iterable<String?> urls, {
  int limit = 4,
  bool shortLived = false,
}) async {
  final cache = shortLived ? _articleImageCache : _imageCache;
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
