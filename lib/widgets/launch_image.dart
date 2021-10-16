import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rockit/launch_library/json_convert.dart';

class LaunchImageWidget extends StatefulWidget {
  const LaunchImageWidget(this.launch, {Key? key}) : super(key: key);

  final Launch launch;

  @override
  _LaunchImageWidgetState createState() => _LaunchImageWidgetState();
}

class _LaunchImageWidgetState extends State<LaunchImageWidget> {
  Widget _image(BuildContext context, Launch launch) {
    if (launch.image != null) {
      return CachedNetworkImage(
        imageUrl: launch.image!,
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
    return Hero(
      tag: "launchimage-" + (widget.launch.id ?? "unknown"),
      child: _image(context, widget.launch),
    );
  }
}
