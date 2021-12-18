import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ImageWidget extends StatefulWidget {
  const ImageWidget(this.imageURL, {this.heroTag, this.id, Key? key})
      : super(key: key);

  final String? imageURL;
  final String? heroTag;
  final String? id;

  @override
  _ImageWidgetState createState() => _ImageWidgetState();
}

class _ImageWidgetState extends State<ImageWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static final CacheManager? _cacheManager = () {
    try {
      return CacheManager(
        Config(
          'images',
          stalePeriod: const Duration(days: 7),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Could not initialize cache manager: $e");
      }
    }
    return null;
  }();

  Widget _image(BuildContext context, String? _imageURL) {
    if (_imageURL != null) {
      try {
        if (kIsWeb) {
          return Image.network(
            "https://corsanywhere.herokuapp.com/$_imageURL",
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _defaultImage(),
          );
        }
        return CachedNetworkImage(
          imageUrl: _imageURL,
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
        if (kDebugMode) {
          debugPrint("Creating cached network image for $_imageURL");
        }
      }
    }

    return _defaultImage();
  }

  Widget _defaultImage() {
    if (Theme.of(context).brightness == Brightness.light) {
      return Image.asset("assets/rocket-black.png");
    }
    return Image.asset("assets/rocket-white.png");
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
      tag: (widget.heroTag ?? "unknown") + "-" + (widget.id ?? "unknown"),
      child: launchImage,
    );
  }
}
