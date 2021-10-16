import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rockit/launch_library/json_convert.dart';
import 'package:intl/intl.dart';
import 'package:rockit/widgets/launch_image.dart';

class LaunchWidget extends StatefulWidget {
  const LaunchWidget(this.launch, {Key? key}) : super(key: key);

  final Launch launch;

  @override
  _LaunchWidgetState createState() => _LaunchWidgetState();
}

class _LaunchWidgetState extends State<LaunchWidget> {
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
    return SizedBox(
      height: max(MediaQuery.of(context).size.height / 3, 250),
      child: Card(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 5,
        margin: const EdgeInsets.fromLTRB(10, 5, 10, 5),
        child: GridTile(
          child: LaunchImageWidget(widget.launch),
          footer: _infoBar(widget.launch),
        ),
      ),
    );
  }
}
