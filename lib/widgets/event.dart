import 'package:flutter/material.dart';
import 'package:rockit/l10n/app_localizations.dart';
import 'package:rockit/apis/launch_library/events_response.dart';
import 'package:rockit/widgets/addons/launch_event.dart';

class EventWidget extends StatelessWidget {
  const EventWidget(this.event, {super.key, this.heroPrefix = ""});

  final Event event;
  final String heroPrefix;

  @override
  Widget build(BuildContext context) {
    return LaunchEventWidget(
      title: event.name ?? AppLocalizations.of(context)!.unknownEvent,
      subtitle: event.location ?? AppLocalizations.of(context)!.unknown,
      heroId: "${event.id}",
      heroTag: "${heroPrefix}event-image",
      image: event.image,
      date: event.date,
      precision: event.datePrecision,
    );
  }
}
