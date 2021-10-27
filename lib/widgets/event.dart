import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rockit/apis/launch_library/events_response.dart';

class EventWidget extends StatefulWidget {
  const EventWidget(this.event, {Key? key}) : super(key: key);

  final Event event;

  static double calculateHeight(BuildContext context) {
    return max(MediaQuery.of(context).size.height / 3, 250);
  }

  @override
  _EventWidgetState createState() => _EventWidgetState();
}

class _EventWidgetState extends State<EventWidget> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
