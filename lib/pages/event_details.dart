import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pinch_zoom_image_last/pinch_zoom_image_last.dart';
import 'package:rockit/apis/launch_library/events_response.dart';
import 'package:rockit/apis/launch_library/upcoming_response.dart';
import 'package:rockit/pages/launch_details.dart';
import 'package:rockit/widgets/event_countdown.dart';
import 'package:rockit/widgets/launch.dart';
import 'package:rockit/widgets/launch_image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EventDetailsPage extends StatefulWidget {
  const EventDetailsPage(this.event, {Key? key}) : super(key: key);

  final Event event;

  @override
  _EventDetailsPageState createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  static const titleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const tableDescriptionStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );
  static const tableTextStyle = TextStyle(
    fontSize: 16,
  );

  static const textStyle = TextStyle(
    fontSize: 16,
  );

  Widget _missionDetails(BuildContext context, Event e) {
    return ListTile(
      title: Center(
        child: Text(
          e.name ?? AppLocalizations.of(context)!.unknown,
          style: titleStyle,
          textAlign: TextAlign.center,
        ),
      ),
      subtitle: Text(
        e.description ?? AppLocalizations.of(context)!.noDescription,
        softWrap: true,
        style: textStyle.copyWith(
          color: Theme.of(context).textTheme.bodyText2!.color,
        ),
      ),
    );
  }

  Widget _reducedMissionDetails(BuildContext context, Event e) {
    return Center(
      child: Text(
        e.name ?? AppLocalizations.of(context)!.unknown,
        textAlign: TextAlign.center,
        style: titleStyle,
      ),
    );
  }

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

  List<Widget> _renderLaunches(List<Launch> launches) {
    return [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          launches.length == 1
              ? AppLocalizations.of(context)!.launch
              : AppLocalizations.of(context)!.launches,
          style: titleStyle,
        ),
      ),
      ...launches.map((l) {
        return GestureDetector(
          child: LaunchWidget(l),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => LaunchDetailsPage(l),
              ),
            );
          },
        );
      }),
    ];
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
            // Feature image
            if (widget.event.featureImage != null) ...[
              _zoomableImage(),
            ],

            // Mission title & description if possible
            ...[
              const Divider(),
              if (widget.event.description == null)
                _reducedMissionDetails(context, widget.event)
              else
                _missionDetails(context, widget.event)
            ],

            // Show a countdown
            if (widget.event.date != null) ...[
              const Divider(),
              EventCountDownWidget(widget.event),
            ],

            if ((widget.event.launches ?? []).isNotEmpty) ...[
              const Divider(),
              ..._renderLaunches(widget.event.launches!),
            ]
          ],
        ),
      ),
    );
  }
}
