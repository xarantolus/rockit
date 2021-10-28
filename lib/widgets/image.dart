import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

class _ImageWidgetState extends State<ImageWidget> {
  static final _cacheManager = CacheManager(
    Config(
      'images',
      stalePeriod: const Duration(days: 7),
    ),
  );

  Widget _image(BuildContext context, String? _imageURL) {
    if (_imageURL != null) {
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
