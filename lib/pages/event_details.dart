import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pinch_zoom_image_last/pinch_zoom_image_last.dart';
import 'package:rockit/apis/launch_library/events_response.dart';
import 'package:rockit/apis/launch_library/upcoming_response.dart';
import 'package:rockit/mixins/url_launcher.dart';
import 'package:rockit/pages/launch_details.dart';
import 'package:rockit/widgets/article.dart';
import 'package:rockit/widgets/event_countdown.dart';
import 'package:rockit/widgets/launch.dart';
import 'package:rockit/widgets/image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class EventDetailsPage extends StatefulWidget {
  const EventDetailsPage(this.event, {Key? key}) : super(key: key);

  final Event event;

  @override
  _EventDetailsPageState createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> with UrlLauncher {
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

  Widget _eventDetails(BuildContext context, Event e) {
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

  Widget _reducedEventDetails(BuildContext context, Event e) {
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
            id: "${widget.event.id}",
            heroTag: "event",
          ),
        ),
      ),
    );
  }

  List<Widget> _titledList(String title, Iterable<Widget> widgets) {
    return [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          title,
          style: titleStyle,
        ),
      ),
      ...widgets,
    ];
  }

  List<Widget> _renderLaunches(List<Launch> launches) {
    return _titledList(
      launches.length == 1
          ? AppLocalizations.of(context)!.launch
          : AppLocalizations.of(context)!.launches,
      launches.map((l) {
        return GestureDetector(
          child: LaunchWidget(l, hero: false),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => LaunchDetailsPage(l),
              ),
            );
          },
        );
      }),
    );
  }

  List<Widget> _renderSpaceStations(List<Spacestation> stations) {
    return _titledList(
      stations.length == 1
          ? AppLocalizations.of(context)!.station
          : AppLocalizations.of(context)!.stations,
      stations.map(
        (station) {
          // Yes, reusing the article card widget here is a bit weird,
          // especially because we don't have a link, but it works
          return ArticleCardWidget(
            title: station.name,
            summary: station.description,
            imageUrl: station.imageUrl,
            newsSite: station.orbit,
          );
        },
      ),
    );
  }

  Widget _openURLButton(
      IconData icon, String text, bool customTab, String url) {
    return OutlinedButton.icon(
      onPressed: () async {
        if (customTab) {
          await openCustomTab(context, url);
        } else {
          await launch(url);
        }
      },
      icon: Icon(icon),
      label: Text(text),
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
            // Feature image
            if (widget.event.featureImage != null) ...[
              _zoomableImage(),
            ],

            // Mission title & description if possible
            ...[
              const Divider(),
              if (widget.event.description == null)
                _reducedEventDetails(context, widget.event)
              else
                _eventDetails(context, widget.event),
              if (widget.event.videoUrl != null)
                _openURLButton(
                  Icons.play_arrow,
                  AppLocalizations.of(context)!.watchVideo,
                  false,
                  widget.event.videoUrl!,
                ),
              if (widget.event.newsUrl != null)
                _openURLButton(
                  Icons.open_in_browser,
                  AppLocalizations.of(context)!.openArticle,
                  true,
                  widget.event.newsUrl!,
                ),
            ],

            // Show a countdown
            if (widget.event.date != null) ...[
              const Divider(),
              EventCountDownWidget(widget.event),
            ],

            if ((widget.event.launches ?? []).isNotEmpty) ...[
              const Divider(),
              ..._renderLaunches(widget.event.launches!),
            ],

            if ((widget.event.spacestations ?? []).isNotEmpty) ...[
              const Divider(),
              ..._renderSpaceStations(widget.event.spacestations!)
            ],
          ],
        ),
      ),
    );
  }
}
