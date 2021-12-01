import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rockit/apis/launch_library/events_response.dart';
import 'package:rockit/mixins/date_format.dart';
import 'package:rockit/widgets/image.dart';

class EventWidget extends StatefulWidget {
  const EventWidget(this.event, {Key? key}) : super(key: key);

  final Event event;

  static double calculateHeight(BuildContext context) {
    return max(MediaQuery.of(context).size.height / 3, 250);
  }

  @override
  _EventWidgetState createState() => _EventWidgetState();
}

class _EventWidgetState extends State<EventWidget> with DateFormatter {
  String _netText(Event evt) {
    try {
      return formatDateFriendly(context, evt.date!);
    } catch (_) {}
    return AppLocalizations.of(context)!.netUnknown;
  }

  GridTileBar _infoBar(Event event) {
    return GridTileBar(
      backgroundColor: Colors.grey[800]!.withOpacity(0.75),
      title: Text(
        event.name ?? AppLocalizations.of(context)!.unknownEvent,
        style: const TextStyle(
          overflow: TextOverflow.ellipsis,
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      trailing: Text(
        _netText(event),
        style: const TextStyle(
          color: Colors.white70,
        ),
      ),
      subtitle: Text(
        event.location ?? AppLocalizations.of(context)!.unknown,
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
          footer: _infoBar(widget.event),
        ),
      ),
    );
  }
}
