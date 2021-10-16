import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pinch_zoom_image_last/pinch_zoom_image_last.dart';
import 'package:rockit/launch_library/json_convert.dart';
import 'package:rockit/widgets/launch_image.dart';

class LaunchDetailsPage extends StatefulWidget {
  const LaunchDetailsPage(this.launch, {Key? key}) : super(key: key);

  final Launch launch;

  @override
  _LaunchDetailsPageState createState() => _LaunchDetailsPageState();
}

class _LaunchDetailsPageState extends State<LaunchDetailsPage> {
  Widget _zoomableImage() {
    return SizedBox(
      height: max(MediaQuery.of(context).size.height / 3, 250),
      child: PinchZoomImage(
        image: Center(
          child: LaunchImageWidget(widget.launch),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final launchName = widget.launch.name ?? "Unknown launch";
    return Scaffold(
      appBar: AppBar(
        title: Text(launchName),
      ),
      body: Column(
        children: [
          if (widget.launch.image != null) _zoomableImage(),
        ],
      ),
    );
  }
}
