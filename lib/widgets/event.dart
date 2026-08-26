import 'package:flutter/material.dart';
import 'package:rockit/l10n/app_localizations.dart';
import 'package:rockit/apis/launch_library/events_response.dart';
import 'package:rockit/widgets/addons/launch_event.dart';

class EventWidget extends StatefulWidget {
  const EventWidget(this.event, {super.key, this.heroPrefix = ""});

  final Event event;
  final String heroPrefix;

  @override
  _EventWidgetState createState() => _EventWidgetState();
}

class _EventWidgetState extends State<EventWidget> {
  @override
  Widget build(BuildContext context) {
    return LaunchEventWidget(
      title: widget.event.name ?? AppLocalizations.of(context)!.unknownEvent,
      subtitle: widget.event.location ?? AppLocalizations.of(context)!.unknown,
      heroId: "${widget.event.id}",
      heroTag: "${widget.heroPrefix}event-image",
      imageURL: widget.event.featureImage,
      netDate: widget.event.date,
    );
  }
}
