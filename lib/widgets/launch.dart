import 'package:flutter/material.dart';
import 'package:rockit/launch_library/json_convert.dart';

class LaunchWidget extends StatefulWidget {
  const LaunchWidget(this.launch, {Key? key}) : super(key: key);

  final Launch launch;

  @override
  _LaunchWidgetState createState() => _LaunchWidgetState();
}

class _LaunchWidgetState extends State<LaunchWidget> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(widget.launch.name ?? "Unknown launch"),
    );
  }
}
