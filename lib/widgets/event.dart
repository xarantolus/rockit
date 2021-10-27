import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rockit/apis/launch_library/events_response.dart';
import 'package:rockit/widgets/launch_image.dart';

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
    return SizedBox(
      height: EventWidget.calculateHeight(context),
      child: Card(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 5,
        margin: const EdgeInsets.fromLTRB(10, 5, 10, 5),
        child: GridTile(
          child: ImageWidget(
            widget.event.featureImage,
            id: "${widget.event.id}",
            heroTag: "event",
          ),
          // footer: _infoBar(widget.launch),
        ),
      ),
    );
  }
}
