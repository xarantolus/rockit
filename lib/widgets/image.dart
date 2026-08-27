import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ImageWidget extends StatefulWidget {
  const ImageWidget(this.imageURL, {this.heroTag, this.id, super.key});

  final String? imageURL;
  final String? heroTag;
  final String? id;

  @override
  State<ImageWidget> createState() => _ImageWidgetState();
}

class _ImageWidgetState extends State<ImageWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static final CacheManager? _cacheManager = () {
    try {
      return CacheManager(
        Config('images', stalePeriod: const Duration(days: 7)),
      );
    } catch (e) {
      debugPrint("Could not initialize cache manager: $e");
    }
    return null;
  }();

  Widget _image(BuildContext context, String? imageURL) {
    if (imageURL != null) {
      try {
        return CachedNetworkImage(
          imageUrl: kIsWeb ? "https://fuckcors.app/$imageURL" : imageURL,
          cacheManager: _cacheManager,
          fadeInDuration: const Duration(milliseconds: 125),
          fadeOutDuration: const Duration(milliseconds: 250),
          fit: BoxFit.cover,
          progressIndicatorBuilder: (context, url, downloadProgress) => Center(
            child: CircularProgressIndicator(value: downloadProgress.progress),
          ),
          errorWidget: (context, url, error) => _defaultImage(),
        );
      } catch (e) {
        debugPrint("Error creating cached network image for $imageURL");
      }
    }

    return _defaultImage();
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

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final launchImage = _image(context, widget.imageURL);

    // This prevents having multiple "unknown-unknown" hero tags, which crash the app
    if (widget.heroTag == null || widget.id == null) {
      return launchImage;
    }

    return Hero(
      tag: "${widget.heroTag ?? "unknown"}-${widget.id ?? "unknown"}",
      child: launchImage,
    );
  }
}
