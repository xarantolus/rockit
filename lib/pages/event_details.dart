import 'package:flutter/material.dart';
import 'package:rockit/apis/launch_library/events_response.dart';

class EventDetailsPage extends StatefulWidget {
  EventDetailsPage(this.event, {Key? key}) : super(key: key);

  final Event event;

  @override
  _EventDetailsPageState createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
