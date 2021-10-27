import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pinch_zoom_image_last/pinch_zoom_image_last.dart';
import 'package:rockit/apis/launch_library/events_response.dart';
import 'package:rockit/widgets/launch_image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EventDetailsPage extends StatefulWidget {
  const EventDetailsPage(this.event, {Key? key}) : super(key: key);

  final Event event;

  @override
  _EventDetailsPageState createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  Widget _zoomableImage() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: max(MediaQuery.of(context).size.height / 3, 250),
      ),
      child: PinchZoomImage(
        image: Center(
          child: ImageWidget(
            widget.event.featureImage,
            heroTag: "launch-image",
            id: "${widget.event.id}",
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.event.name ?? AppLocalizations.of(context)!.unknownEvent,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (widget.event.featureImage != null) ...[
              _zoomableImage(),
            ],
          ],
        ),
      ),
    );
  }
}
