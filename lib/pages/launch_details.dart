import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:pinch_zoom_image_last/pinch_zoom_image_last.dart';
import 'package:rockit/apis/launch_library/upcoming_response.dart';
import 'package:rockit/background/handler.dart';
import 'package:rockit/mixins/attribution.dart';
import 'package:rockit/mixins/date_format.dart';
import 'package:rockit/mixins/url_launcher.dart';
import 'package:rockit/widgets/article.dart';
import 'package:rockit/widgets/image.dart';
import 'package:rockit/widgets/launch_countdown.dart';
import 'package:rockit/widgets/ripple_link.dart';

class LaunchDetailsPage extends StatefulWidget {
  const LaunchDetailsPage(this.launch, {Key? key}) : super(key: key);

  final Launch launch;

  @override
  _LaunchDetailsPageState createState() => _LaunchDetailsPageState();
}

class _LaunchDetailsPageState extends State<LaunchDetailsPage>
    with DateFormatter, UrlLauncher, SourceAttribution {
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

  Widget _zoomableImage() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: max(MediaQuery.of(context).size.height / 3, 250),
      ),
      child: PinchZoomImage(
        image: Center(
          child: ImageWidget(
            widget.launch.image,
            heroTag: "launch-image",
            id: widget.launch.id,
          ),
        ),
      ),
    );
  }

  Widget _missionDetails(BuildContext context, Mission m) {
    return ListTile(
      title: Center(
        child: Text(
          m.name ?? AppLocalizations.of(context)!.unknown,
          style: titleStyle,
          textAlign: TextAlign.center,
        ),
      ),
      subtitle: Text(
        m.description ?? AppLocalizations.of(context)!.noDescription,
        softWrap: true,
        style: textStyle.copyWith(
          color: Theme.of(context).textTheme.bodyText2!.color,
        ),
      ),
    );
  }

  Widget _reducedMissionDetails(BuildContext context, Launch l) {
    return Center(
      child: Text(
        l.name ?? AppLocalizations.of(context)!.unknown,
        textAlign: TextAlign.center,
        style: titleStyle,
      ),
    );
  }

  List<Widget> _launchPad(BuildContext context, Pad pad) {
    return _titleImageDescription(
      context,
      clickURL: pad.mapUrl ?? pad.infoUrl ?? pad.wikiUrl,
      title: pad.name,
      description: pad.location?.name,
      imageURL: pad.mapImage ?? pad.location?.mapImage,
      shrinkImage: false,
      zoomableImage: true,
    );
  }

  List<Widget> _launchServiceProvider(
      BuildContext context, LaunchServiceProvider provider) {
    return _titleImageDescription(
      context,
      clickURL: provider.infoUrl,
      title: provider.name,
      description: provider.description,
      imageURL: provider.logoUrl ?? provider.imageUrl,
    );
  }

  List<Widget> _rocketConfiguration(BuildContext context, Configuration cfg) {
    return _titleImageDescription(
      context,
      title: cfg.fullName,
      description: cfg.description,
      clickURL: cfg.infoUrl,
      imageURL: cfg.imageUrl,
    );
  }

  List<Widget> _titleImageDescription(
    BuildContext context, {
    String? title,
    String? description,
    String? imageURL,
    String? clickURL,
    bool shrinkImage = true,
    bool zoomableImage = false,
  }) {
    void openClickURL() async {
      if ((clickURL ?? "").isNotEmpty) {
        openCustomTab(context, clickURL!);
      }
    }

    final imageWidget = imageURL == null ? null : ImageWidget(imageURL);

    return [
      GestureDetector(
        onTap: openClickURL,
        child: Container(
          margin: const EdgeInsets.all(16),
          child: Text(
            title ?? AppLocalizations.of(context)!.unknown,
            style: titleStyle,
            textAlign: TextAlign.center,
          ),
        ),
      ),
      if (imageURL != null)
        GestureDetector(
          onTap: openClickURL,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            constraints: shrinkImage
                ? BoxConstraints(
                    maxHeight: max(MediaQuery.of(context).size.height / 8, 50),
                  )
                : null,
            child: zoomableImage
                ? PinchZoomImage(
                    image: Center(
                      child: imageWidget,
                    ),
                  )
                : imageWidget,
          ),
        ),
      Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          description ?? AppLocalizations.of(context)!.unknown,
          style: textStyle,
        ),
      )
    ];
  }

  List<Widget> _missionPatches(BuildContext context, List<MissionPatch> l) {
    final importantPatches =
        l.where((element) => (element.imageUrl ?? "").isNotEmpty);
    if (importantPatches.isEmpty) {
      return List.empty();
    }

    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
        child: Text(
          l.length == 1
              ? AppLocalizations.of(context)!.missionPatch
              : AppLocalizations.of(context)!.missionPatches,
          style: titleStyle,
        ),
      ),
      ...importantPatches.map((e) => _missionPatch(context, e, l.length == 1)),
    ];
  }

  Widget _missionPatch(
      BuildContext context, MissionPatch patch, bool isSingle) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // If we only have one mission patch, we don't need to add the title
          if (!isSingle)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                patch.name ?? AppLocalizations.of(context)!.unknown,
                style: titleStyle,
              ),
            ),
          PinchZoomImage(
            image: Center(
              child: ImageWidget(patch.imageUrl),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _urlInfoList(
    BuildContext context,
    List<URLInfo> l,
    String title,
    Widget Function(BuildContext, URLInfo) mapFunction,
  ) {
    final widgets = l
        .map((info) {
          if (info.title == null &&
              (info.description == null || info.featureImage == null)) {
            return null;
          }
          return mapFunction(context, info);
        })
        .where((element) => element != null)
        .map((e) => e!);

    if (widgets.isEmpty) {
      return List.empty();
    }

    return [
      const Divider(),
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
        child: Text(
          title,
          style: titleStyle,
        ),
      ),
      ...widgets,
    ];
  }

  List<Widget> _updateList(BuildContext context, List<Update> updates) {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
        child: Text(
          AppLocalizations.of(context)!.updates,
          style: titleStyle,
        ),
      ),
      ...widget.launch.updates!.map((e) => _update(context, e)),
    ];
  }

  Widget _update(BuildContext context, Update u) {
    final date = formatDateTimeFriendly(context,
        (DateTime.tryParse(u.createdOn ?? "") ?? DateTime.now()).toLocal());

    return RippleLinkWidget(
      u.comment ?? AppLocalizations.of(context)!.unknown,
      bottomRight: date,
      bottomLeft: sourceAttributionText(context, u.infoUrl),
      url: u.infoUrl,
    );
  }

  Widget _urlInfoArticleWidget(BuildContext context, URLInfo info,
      [bool customTab = true, Icon? icon]) {
    return ArticleCardWidget(
      title: info.title,
      link: info.url,
      imageUrl: info.featureImage,
      newsSite: urlHost(info.url),
      summary: info.description,
      customTab: customTab,
      icon: icon,
    );
  }

  Widget _generalInfo(BuildContext context, Launch l) {
    TableRow descriptionRow(String description, String? value) {
      return TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.all(3),
            child: Text(description, style: tableDescriptionStyle),
          ),
          Padding(
            padding: const EdgeInsets.all(3),
            child: Text(
              value ?? AppLocalizations.of(context)!.unknown,
              style: tableTextStyle,
            ),
          ),
        ],
      );
    }

    final lastUpdated = DateTime.tryParse(l.lastUpdated ?? "");

    final windowStart = DateTime.tryParse(l.windowStart ?? "");
    final windowEnd = DateTime.tryParse(l.windowEnd ?? "");

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
            child: Text(
              AppLocalizations.of(context)!.info,
              style: titleStyle,
            ),
          ),
          Table(
            border: TableBorder.symmetric(
              inside: BorderSide(
                  color: Theme.of(context)
                      .textTheme
                      .bodyText2!
                      .color!
                      .withOpacity(.5)),
            ),
            columnWidths: const {
              0: IntrinsicColumnWidth(),
              1: FlexColumnWidth(),
            },
            children: [
              descriptionRow(AppLocalizations.of(context)!.status,
                  l.status?.name ?? AppLocalizations.of(context)!.unknown),
              descriptionRow(
                  AppLocalizations.of(context)!.statusDescription,
                  l.status?.description ??
                      AppLocalizations.of(context)!.unknown),
              if ((l.holdreason ?? "").isNotEmpty)
                descriptionRow(
                    AppLocalizations.of(context)!.holdReason, l.holdreason!),
              if ((l.failreason ?? "").isNotEmpty)
                descriptionRow(
                    AppLocalizations.of(context)!.failReason, l.failreason!),
              if (l.mission?.orbit != null)
                descriptionRow(
                  AppLocalizations.of(context)!.targetOrbit,
                  l.mission!.orbit!.name ??
                      AppLocalizations.of(context)!.unknown,
                ),
              if (windowStart != null)
                descriptionRow(AppLocalizations.of(context)!.windowStart,
                    formatDateTimeLocal(context, windowStart)),
              if (windowEnd != null)
                descriptionRow(
                    AppLocalizations.of(context)!.windowEnd,
                    formatDateTimeLocal(context, windowEnd) +
                        (windowStart == windowEnd
                            ? " (${AppLocalizations.of(context)!.likeStartTime})"
                            : "")),
              if (l.probability is double && (l.probability ?? -1) > 0)
                descriptionRow(AppLocalizations.of(context)!.startProbability,
                    "${((l.probability as double) * 100).toStringAsFixed(0)}%"),
              if (lastUpdated != null)
                descriptionRow(AppLocalizations.of(context)!.lastUpdate,
                    formatDateTimeLocal(context, lastUpdated)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _subscription(String launchId) {
    final subscriptionManager = BackgroundHandler();

    return FutureBuilder<bool>(
      future: subscriptionManager.isSubscribedToLaunch(launchId),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasError) {
          return ErrorWidget(snapshot.error!);
        }
        if (snapshot.hasData) {
          var value = snapshot.data!;

          return Column(
            children: [
              CheckboxListTile(
                title: Text(AppLocalizations.of(context)!.launchSubscribe),
                onChanged: (newValue) async {
                  if (newValue == true) {
                    await subscriptionManager.subscribeToLaunch(launchId);
                  } else if (newValue == false) {
                    await subscriptionManager.unsubscribeFromLaunch(launchId);
                  }

                  setState(() {
                    value = newValue;
                  });
                },
                value: value,
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  AppLocalizations.of(context)!.notificationDescription,
                ),
              ),
            ],
          );
        }

        return const CircularProgressIndicator();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final launchName =
        widget.launch.name ?? AppLocalizations.of(context)!.unknownLaunch;

    return Scaffold(
      appBar: AppBar(
        title: Text(launchName),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // If we have an image, we show it at the top
            if (widget.launch.image != null) ...[
              _zoomableImage(),
            ],

            // Then a mission description
            ...[
              const Divider(),
              if (widget.launch.mission == null)
                _reducedMissionDetails(context, widget.launch)
              else
                _missionDetails(context, widget.launch.mission!),
            ],

            const Divider(),

            if (widget.launch.id != null) _subscription(widget.launch.id!),

            // The countdown should always be displayed
            const Divider(),
            LaunchCountDownWidget(widget.launch),

            // Just like the general info table
            const Divider(),
            _generalInfo(context, widget.launch),

            // Show mission patches
            if (widget.launch.missionPatches?.isNotEmpty ?? false) ...[
              ...() {
                // We only add the divider conditionally;
                // the function might return zero widgets even if
                // the mission patch list contains more than 0 items
                final patches = _missionPatches(
                  context,
                  widget.launch.missionPatches!,
                );

                if (patches.isNotEmpty) {
                  patches.insert(0, const Divider());
                }
                return patches;
              }(),
            ],

            // Render a list of articles/info URLs
            ..._urlInfoList(
              context,
              widget.launch.infoUrls ?? [],
              AppLocalizations.of(context)!.moreInfo,
              (ctx, info) => _urlInfoArticleWidget(ctx, info),
            ),

            // A list of videos with thumbnails
            ..._urlInfoList(
              context,
              widget.launch.vidUrls ?? [],
              AppLocalizations.of(context)!.videos,
              (ctx, vid) => _urlInfoArticleWidget(
                  ctx, vid, false, const Icon(Icons.play_arrow, size: 72)),
            ),

            // Now a list of updates to the data
            if ((widget.launch.updates ?? []).isNotEmpty) ...[
              const Divider(),
              ..._updateList(context, widget.launch.updates!),
            ],

            // An informative description of the rocket
            if (widget.launch.rocket?.configuration?.description != null) ...[
              const Divider(),
              ..._rocketConfiguration(
                  context, widget.launch.rocket!.configuration!),
            ],

            // And a bunch of info about the launch provider
            if (widget.launch.launchServiceProvider?.description != null) ...[
              const Divider(),
              ..._launchServiceProvider(
                context,
                widget.launch.launchServiceProvider!,
              ),
            ],

            // There are some incomplete pads that we shouldn't render6
            if (widget.launch.pad != null &&
                widget.launch.pad?.location?.countryCode != "UNK") ...[
              const Divider(),
              ..._launchPad(context, widget.launch.pad!),
            ],
          ],
        ),
      ),
    );
  }
}
