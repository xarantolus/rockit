import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:pinch_zoom_image_last/pinch_zoom_image_last.dart';
import 'package:rockit/apis/launch_library/events_response.dart';
import 'package:rockit/apis/launch_library/upcoming_response.dart';
import 'package:rockit/background/handler.dart';
import 'package:rockit/mixins/attribution.dart';
import 'package:rockit/mixins/date_format.dart';
import 'package:rockit/mixins/program_renderer.dart';
import 'package:rockit/mixins/update_renderer.dart';
import 'package:rockit/mixins/url_launcher.dart';
import 'package:rockit/pages/launch_details.dart';
import 'package:rockit/widgets/addons/app_bar.dart';
import 'package:rockit/widgets/article.dart';
import 'package:rockit/widgets/event_countdown.dart';
import 'package:rockit/widgets/image.dart';
import 'package:rockit/widgets/launch.dart';
import 'package:url_launcher/url_launcher.dart';

class EventDetailsPage extends StatefulWidget {
  const EventDetailsPage(this.event, {Key? key}) : super(key: key);

  final Event event;

  @override
  _EventDetailsPageState createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage>
    with
        UrlLauncher,
        DateFormatter,
        SourceAttribution,
        UpdateRenderer,
        ProgramRenderer {
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
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            e.name ?? AppLocalizations.of(context)!.unknown,
            style: titleStyle,
            textAlign: TextAlign.center,
          ),
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
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          e.name ?? AppLocalizations.of(context)!.unknown,
          textAlign: TextAlign.center,
          style: titleStyle,
        ),
      ),
    );
  }

  Widget _zoomableImage() {
    return PinchZoomImage(
      image: Center(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: max(MediaQuery.of(context).size.height / 3, 250),
          ),
          child: ImageWidget(
            widget.event.featureImage,
            id: "${widget.event.id}",
            heroTag: "event",
          ),
        ),
      ),
    );
  }

  Widget _subscription(String eventId) {
    final subscriptionManager = BackgroundHandler();

    return FutureBuilder<bool>(
      future: subscriptionManager.isSubscribedToEvent(eventId),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasError) {
          return ErrorWidget(snapshot.error!);
        }
        if (snapshot.hasData) {
          var value = snapshot.data!;

          return EventSubscriptionWidget(value, eventId, subscriptionManager);
        }

        return const CircularProgressIndicator();
      },
    );
  }

  List<Widget> _renderLaunches(List<Launch> launches) {
    return titledList(
      launches.length == 1
          ? AppLocalizations.of(context)!.launch
          : AppLocalizations.of(context)!.launches,
      launches.map((l) {
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
    );
  }

  List<Widget> _renderSpaceStations(List<Spacestation> stations) {
    return titledList(
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
      appBar: CustomAppBar.create(
        context,
        title: widget.event.name ?? AppLocalizations.of(context)!.unknownEvent,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Feature image
            if (widget.event.featureImage != null) ...[
              _zoomableImage(),
            ],

            // Mission title & description if possible
            ...[
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
                  AppLocalizations.of(context)!.moreInfo,
                  true,
                  widget.event.newsUrl!,
                ),
            ],

            if (!kIsWeb) ...[
              const Divider(),
              _subscription("${widget.event.id}"),
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

            // Now a list of updates to the data
            if ((widget.event.updates ?? []).isNotEmpty) ...[
              const Divider(),
              ...renderUpdateList(context, titleStyle, widget.event.updates!),
            ],
            if ((widget.event.spacestations ?? []).isNotEmpty) ...[
              const Divider(),
              ..._renderSpaceStations(widget.event.spacestations!),
            ],
            if ((widget.event.program ?? []).isNotEmpty) ...[
              const Divider(),
              ...renderProgramInfo(context, widget.event.program!),
            ]
          ],
        ),
      ),
    );
  }
}

class EventSubscriptionWidget extends StatefulWidget {
  const EventSubscriptionWidget(
      this.initialValue, this.eventId, this.subscriptionManager,
      {Key? key})
      : super(key: key);

  final bool initialValue;
  final String eventId;
  final BackgroundHandler subscriptionManager;

  @override
  _EventSubscriptionWidgetState createState() =>
      _EventSubscriptionWidgetState();
}

class _EventSubscriptionWidgetState extends State<EventSubscriptionWidget> {
  bool? value;

  void _onCheckChange(newValue) async {
    if (newValue == true) {
      await widget.subscriptionManager.subscribeToEvent(widget.eventId);
    } else if (newValue == false) {
      await widget.subscriptionManager.unsubscribeFromEvent(widget.eventId);
    }

    setState(() {
      value = newValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CheckboxListTile(
          title: Text(AppLocalizations.of(context)!.eventSubscribe),
          onChanged: _onCheckChange,
          value: value ?? widget.initialValue,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            AppLocalizations.of(context)!.notificationDescription,
          ),
        ),
      ],
    );
  }
}
