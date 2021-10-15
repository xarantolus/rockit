import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rockit/launch_library/json_convert.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class LaunchWidget extends StatefulWidget {
  const LaunchWidget(this.launch, {Key? key}) : super(key: key);

  final Launch launch;

  @override
  _LaunchWidgetState createState() => _LaunchWidgetState();
}

class _LaunchWidgetState extends State<LaunchWidget> {
  Widget _image(BuildContext context, Launch launch) {
    if (launch.image != null) {
      return CachedNetworkImage(
        cacheManager: DefaultCacheManager(),
        imageUrl: launch.image!,
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

  String _netText(Launch launch) {
    try {
      var launchDate = DateTime.parse(launch.net ?? launch.windowStart ?? "");

      final DateFormat formatter = DateFormat('yyyy-MM-dd');
      return formatter.format(launchDate);
    } catch (_) {}
    return "NET Unknown";
  }

  GridTileBar _infoBar(Launch launch) {
    return GridTileBar(
      backgroundColor: Colors.grey[800]!.withOpacity(0.75),
      title: Text(
        launch.name ?? "Unknown launch",
        style: const TextStyle(
          overflow: TextOverflow.ellipsis,
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      trailing: Text(_netText(launch)),
      subtitle: Text(
        launch.launchServiceProvider?.name ?? "Unknown",
        style: const TextStyle(
          overflow: TextOverflow.ellipsis,
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final launch = widget.launch;

    return Container(
      height: max(MediaQuery.of(context).size.height / 3, 250),
      child: Card(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 5,
        margin: const EdgeInsets.fromLTRB(10, 5, 10, 5),
        child: GridTile(
          child: _image(context, launch),
          footer: _infoBar(launch),
        ),
      ),
    );
  }
}
