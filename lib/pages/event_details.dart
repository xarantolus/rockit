import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rockit/l10n/app_localizations.dart';
import 'package:rockit/apis/launch_library/api.dart';
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
import 'package:rockit/widgets/addons/notification_note.dart';
import 'package:rockit/widgets/addons/detail_section.dart';
import 'package:rockit/widgets/addons/launch_hero.dart';
import 'package:rockit/widgets/addons/insets.dart';
import 'package:rockit/widgets/addons/planet_loading_animation.dart';
import 'package:rockit/widgets/addons/readable_width.dart';
import 'package:rockit/widgets/article.dart';
import 'package:rockit/widgets/launch.dart';

class EventDetailsPage extends StatefulWidget {
  const EventDetailsPage(
    this.event, {
    this.heroPrefix = "",
    this.heroEnabled = true,
    this.openUpdates = false,
    super.key,
  });

  final Event event;

  final String heroPrefix;

  /// See [LaunchDetailsPage.heroEnabled].
  final bool heroEnabled;

  /// See [LaunchDetailsPage.openUpdates].
  final bool openUpdates;

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
  static const textStyle = TextStyle(fontSize: 16);

  /// Just the description — the event name is already the hero title.
  Widget _eventDetails(BuildContext context, Event e) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Text(
        e.description ?? AppLocalizations.of(context)!.noDescription,
        softWrap: true,
        style: textStyle.copyWith(
          color: Theme.of(context).textTheme.bodyMedium!.color,
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
    return launches
        .map(
          (l) => GestureDetector(
            child: LaunchWidget(l),
            onTap: () => _openLaunch(l),
          ),
        )
        .toList();
  }

  /// Opens a launch attached to this event, preferring the cached copy.
  ///
  /// The one embedded in an event is abbreviated — no timeline, no boosters,
  /// no updates — while the same launch from a listing is `mode=detailed` and
  /// filed under its own URL. Cache only: a fuller page is not worth one of
  /// fifteen requests an hour, and the embedded copy is a fine fallback.
  Future<void> _openLaunch(Launch launch) async {
    final id = launch.id;
    final cached = id == null
        ? null
        : await LaunchLibraryAPI().cachedLaunch(id);

    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (ctx) => LaunchDetailsPage(cached ?? launch)),
    );
  }

  List<Widget> _renderSpaceStations(List<SpaceStation> stations) {
    return _stationCards(stations);
  }

  List<Widget> _stationCards(List<SpaceStation> stations) {
    return List.of(
      stations.map((station) {
        // Yes, reusing the article card widget here is a bit weird,
        // especially because we don't have a link, but it works
        return ArticleCardWidget(
          title: station.name,
          summary: station.description,
          imageUrl: station.image?.imageUrl,
          flat: true,
        );
      }),
    );
  }

  Widget _urlInfoArticleWidget(
    BuildContext context,
    ContentUrl info, [
    bool customTab = true,
    Icon? icon,
  ]) {
    return ArticleCardWidget(
      title: info.title,
      link: info.url,
      imageUrl: info.featureImage,
      newsSite: urlHost(info.url),
      // The API often repeats the title as the description, and a card that
      // says the same thing twice just looks broken.
      summary: info.description?.trim() == info.title?.trim()
          ? null
          : info.description,
      customTab: customTab,
      icon: icon,
      flat: true,
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
      // Who is running it. The one field every upcoming event has that the page
      // was dropping. Listings return agencies in `list` mode, so there is a
      // name and an abbreviation and nothing else — a chip is all it supports.
      for (final agency in e.agencies)
        if ((agency.abbrev ?? agency.name) != null)
          InfoChip(
            label: agency.abbrev ?? agency.name!,
            icon: Icons.apartment_outlined,
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
        child: ReadableWidth(
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
                heroTag: widget.heroEnabled
                    ? "${widget.heroPrefix}event-image"
                    : null,
                heroId: "${widget.event.id}",
              ),

              _quickFacts(context, widget.event),

              if (!kIsWeb) _subscription("${widget.event.id}"),

              DetailCard(
                title: AppLocalizations.of(context)!.info,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.event.description != null)
                      _eventDetails(context, widget.event),
                    if (widget.event.lastUpdated != null)
                      DetailRow(
                        label: AppLocalizations.of(context)!.lastUpdate,
                        value: formatDateTime(
                          context,
                          widget.event.lastUpdated!.toLocal(),
                        ),
                      ),
                  ],
                ),
              ),

              // These were being dropped. The page rendered `news_url`, which
              // 2.3.0 does not have — it moved to the `info_urls` list — so that
              // button never appeared, and only the first video was ever offered.
              if (widget.event.vidUrls.isNotEmpty)
                DetailCard(
                  title: AppLocalizations.of(context)!.videos,
                  padded: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: widget.event.vidUrls
                        .map(
                          (vid) => _urlInfoArticleWidget(
                            context,
                            vid,
                            false,
                            const Icon(Icons.play_arrow, size: 72),
                          ),
                        )
                        .toList(),
                  ),
                ),

              if (widget.event.infoUrls.isNotEmpty)
                DetailCard(
                  title: AppLocalizations.of(context)!.moreInfo,
                  padded: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: widget.event.infoUrls
                        .map((info) => _urlInfoArticleWidget(context, info))
                        .toList(),
                  ),
                ),

              // Events often hang off a launch; this is the way through to it.
              if (widget.event.launches.isNotEmpty)
                SectionLabel(title: AppLocalizations.of(context)!.launches),
              ..._renderLaunches(widget.event.launches),

              if (widget.event.spacestations.isNotEmpty)
                DetailCard(
                  title: AppLocalizations.of(context)!.stations,
                  padded: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _renderSpaceStations(widget.event.spacestations),
                  ),
                ),

              if (widget.event.updates.isNotEmpty)
                DetailCard(
                  title: AppLocalizations.of(context)!.updates,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: renderUpdateList(context, widget.event.updates),
                  ),
                ),

              if (widget.event.program.isNotEmpty)
                DetailCard(
                  title: AppLocalizations.of(context)!.programs,
                  padded: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: renderProgramInfo(context, widget.event.program),
                  ),
                ),
            ],
          ),
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
        NotificationNote(
          description: AppLocalizations.of(
            context,
          )!.notificationDescriptionEvent,
        ),
      ],
    );
  }
}
