import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rockit/l10n/app_localizations.dart';
import 'package:rockit/apis/launch_library/events_response.dart';
import 'package:rockit/apis/launch_library/launch_response.dart';
import 'package:rockit/background/handler.dart';
import 'package:rockit/mixins/attribution.dart';
import 'package:rockit/mixins/date_format.dart';
import 'package:rockit/mixins/link_copy.dart';
import 'package:rockit/mixins/program_renderer.dart';
import 'package:rockit/mixins/update_renderer.dart';
import 'package:rockit/mixins/url_launcher.dart';
import 'package:rockit/pages/launch_details.dart';
import 'package:rockit/widgets/addons/app_bar.dart';
import 'package:rockit/widgets/addons/detail_section.dart';
import 'package:rockit/widgets/addons/launch_hero.dart';
import 'package:rockit/widgets/addons/insets.dart';
import 'package:rockit/widgets/addons/planet_loading_animation.dart';
import 'package:rockit/widgets/article.dart';
import 'package:rockit/widgets/launch.dart';

class EventDetailsPage extends StatefulWidget {
  const EventDetailsPage(this.event, {this.heroPrefix = "", super.key});

  final Event event;

  final String heroPrefix;

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage>
    with
        UrlLauncher,
        DateFormatter,
        SourceAttribution,
        UpdateRenderer,
        ProgramRenderer,
        LinkCopier {
  static const titleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const textStyle = TextStyle(fontSize: 16);

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
          color: Theme.of(context).textTheme.bodyMedium!.color,
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

        return const PlanetLoadingAnimation();
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
            await Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (ctx) => LaunchDetailsPage(l)));
          },
        );
      }),
    );
  }

  List<Widget> _renderSpaceStations(List<SpaceStation> stations) {
    return titledList(
      stations.length == 1
          ? AppLocalizations.of(context)!.station
          : AppLocalizations.of(context)!.stations,
      stations.map((station) {
        // Yes, reusing the article card widget here is a bit weird,
        // especially because we don't have a link, but it works
        return ArticleCardWidget(
          title: station.name,
          summary: station.description,
          imageUrl: station.image?.imageUrl,
        );
      }),
    );
  }

  Widget _openURLButton(
    IconData icon,
    String text,
    bool customTab,
    String url,
  ) {
    return OutlinedButton.icon(
      onPressed: () async {
        if (customTab) {
          await openCustomTab(context, url);
        } else {
          await launchURL(context, url);
        }
      },
      onLongPress: () => copyLink(context, url),
      icon: Icon(icon),
      label: Text(text),
    );
  }

  Widget _quickFacts(BuildContext context, Event e) {
    final chips = <Widget>[
      if (e.type != null) InfoChip(label: e.type!, icon: Icons.event_outlined),
      if (e.location != null)
        InfoChip(label: e.location!, icon: Icons.place_outlined),
      if (e.duration != null)
        InfoChip(
          label: AppLocalizations.of(context)!.daysUnit(e.duration!.inDays),
          icon: Icons.schedule,
        ),
    ];

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Wrap(spacing: 8, runSpacing: 8, children: chips),
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
        padding: bottomSystemBarPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LaunchHero(
              image: widget.event.image,
              title:
                  widget.event.name ??
                  AppLocalizations.of(context)!.unknownEvent,
              subtitle: widget.event.type ?? widget.event.location,
              // Events have no launch status, and their dates are never
              // precise to a time, so this always renders a window.
              date: widget.event.date,
              precision: widget.event.datePrecision,
              heroTag: "${widget.heroPrefix}event-image",
              heroId: "${widget.event.id}",
            ),

            _quickFacts(context, widget.event),

            if (!kIsWeb) _subscription("${widget.event.id}"),

            DetailSection(
              title: AppLocalizations.of(context)!.info,
              initiallyExpanded: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.event.description == null)
                    _reducedEventDetails(context, widget.event)
                  else
                    _eventDetails(context, widget.event),
                  if (widget.event.vidUrls.isNotEmpty)
                    _openURLButton(
                      Icons.play_arrow,
                      AppLocalizations.of(context)!.watchVideo,
                      false,
                      widget.event.vidUrls.first.url!,
                    ),
                  if (widget.event.newsUrl != null)
                    _openURLButton(
                      Icons.open_in_browser,
                      AppLocalizations.of(context)!.moreInfo,
                      true,
                      widget.event.newsUrl!,
                    ),
                ],
              ),
            ),

            // Events often hang off a launch; this is the way through to it.
            if (widget.event.launches.isNotEmpty)
              DetailSection(
                title: AppLocalizations.of(context)!.launches,
                count: widget.event.launches.length,
                preview: widget.event.launches.first.name,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _renderLaunches(widget.event.launches),
                ),
              ),

            if (widget.event.spacestations.isNotEmpty)
              DetailSection(
                title: AppLocalizations.of(context)!.stations,
                count: widget.event.spacestations.length,
                preview: widget.event.spacestations.first.name,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _renderSpaceStations(widget.event.spacestations),
                ),
              ),

            if (widget.event.updates.isNotEmpty)
              DetailSection(
                title: AppLocalizations.of(context)!.updates,
                count: widget.event.updates.length,
                preview: widget.event.updates.first.comment,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: renderUpdateList(
                    context,
                    titleStyle,
                    widget.event.updates,
                  ),
                ),
              ),

            if (widget.event.program.isNotEmpty)
              DetailSection(
                title: AppLocalizations.of(context)!.programs,
                count: widget.event.program.length,
                preview: widget.event.program.first.name,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: renderProgramInfo(context, widget.event.program),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class EventSubscriptionWidget extends StatefulWidget {
  const EventSubscriptionWidget(
    this.initialValue,
    this.eventId,
    this.subscriptionManager, {
    super.key,
  });

  final bool initialValue;
  final String eventId;
  final BackgroundHandler subscriptionManager;

  @override
  State<EventSubscriptionWidget> createState() =>
      _EventSubscriptionWidgetState();
}

class _EventSubscriptionWidgetState extends State<EventSubscriptionWidget> {
  bool? value;

  void _onCheckChange(bool? newValue) async {
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
          child: Text(AppLocalizations.of(context)!.notificationDescription),
        ),
      ],
    );
  }
}
