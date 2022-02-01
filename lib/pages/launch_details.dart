import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:pinch_zoom_image_last/pinch_zoom_image_last.dart';
import 'package:rockit/apis/launch_library/launch_response.dart';
import 'package:rockit/background/handler.dart';
import 'package:rockit/mixins/attribution.dart';
import 'package:rockit/mixins/date_format.dart';
import 'package:rockit/mixins/link_copy.dart';
import 'package:rockit/mixins/program_renderer.dart';
import 'package:rockit/mixins/update_renderer.dart';
import 'package:rockit/mixins/url_launcher.dart';
import 'package:rockit/widgets/addons/app_bar.dart';
import 'package:rockit/widgets/addons/planet_loading_animation.dart';
import 'package:rockit/widgets/article.dart';
import 'package:rockit/widgets/image.dart';
import 'package:rockit/widgets/launch_countdown.dart';

class LaunchDetailsPage extends StatefulWidget {
  const LaunchDetailsPage(this.launch, {Key? key}) : super(key: key);

  final Launch launch;

  @override
  _LaunchDetailsPageState createState() => _LaunchDetailsPageState();
}

class _LaunchDetailsPageState extends State<LaunchDetailsPage>
    with DateFormatter, UrlLauncher, SourceAttribution, UpdateRenderer, LinkCopier, ProgramRenderer {
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
    return PinchZoomImage(
      image: Center(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height / 2,
          ),
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
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            m.name ?? AppLocalizations.of(context)!.unknown,
            style: titleStyle,
            textAlign: TextAlign.center,
          ),
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
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          l.name ?? AppLocalizations.of(context)!.unknown,
          textAlign: TextAlign.center,
          style: titleStyle,
        ),
      ),
    );
  }

  Widget _launchPad(BuildContext context, Pad pad) {
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

  Widget _launchServiceProvider(BuildContext context, LaunchServiceProvider provider) {
    return _titleImageDescription(
      context,
      clickURL: provider.infoUrl,
      title: provider.name,
      description: provider.description,
      imageURL: provider.logoUrl ?? provider.imageUrl,
    );
  }

  Widget? _stage(BuildContext context, LauncherStage stage) {
    if (stage.launcher == null) {
      return null;
    }
    return _titleImageDescription(
      context,
      title: stage.launcher?.serialNumber,
      description: stage.launcher?.details,
      imageURL: stage.launcher?.imageUrl,
    );
  }

  Widget _spacecraftStage(BuildContext context, SpaceCraft spaceCraft) {
    return _titleImageDescription(
      context,
      title: spaceCraft.serialNumber,
      description: spaceCraft.description,
      imageURL: spaceCraft.spacecraftConfig?.imageUrl,
    );
  }

  List<Widget> _launcherStages(BuildContext context, List<LauncherStage> stages) {
    return stages.map((s) => _stage(context, s)).whereType<Widget>().toList();
  }

  Widget _rocketConfiguration(BuildContext context, Configuration cfg) {
    return _titleImageDescription(
      context,
      title: cfg.fullName,
      description: cfg.description,
      clickURL: cfg.infoUrl,
      imageURL: cfg.imageUrl,
    );
  }

  Widget _titleImageDescription(
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

    return Material(
      child: InkWell(
        onTap: (clickURL ?? "").isNotEmpty ? openClickURL : null,
        onLongPress: (clickURL ?? "").isEmpty ? null : () => copyLink(context, clickURL),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Text(
                  title ?? AppLocalizations.of(context)!.unknown,
                  style: titleStyle,
                  textAlign: TextAlign.center,
                ),
              ),
              if (imageURL != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  constraints: shrinkImage
                      ? BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height / 5,
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
              Text(
                description ?? AppLocalizations.of(context)!.unknown,
                style: textStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _missionPatches(BuildContext context, List<MissionPatch> l) {
    final importantPatches = l.where((element) => (element.imageUrl ?? "").isNotEmpty);
    if (importantPatches.isEmpty) {
      return List.empty();
    }

    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
        child: Text(
          l.length == 1 ? AppLocalizations.of(context)!.missionPatch : AppLocalizations.of(context)!.missionPatches,
          style: titleStyle,
        ),
      ),
      ...importantPatches.map((e) => _missionPatch(context, e, l.length == 1)),
    ];
  }

  Widget _missionPatch(BuildContext context, MissionPatch patch, bool isSingle) {
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
          if (info.title == null && (info.description == null || info.featureImage == null)) {
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

  Widget _urlInfoArticleWidget(BuildContext context, URLInfo info, [bool customTab = true, Icon? icon]) {
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

  TableRow _descriptionRow(String description, String? value) {
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

  Widget _generalInfo(BuildContext context, Launch l) {
    final lastUpdated = DateTime.tryParse(l.lastUpdated ?? "");

    final windowStart = DateTime.tryParse(l.windowStart ?? "");
    final windowEnd = DateTime.tryParse(l.windowEnd ?? "");

    final landings = (widget.launch.rocket?.launcherStage ?? []);
    final landing = landings.isNotEmpty ? landings[0].landing : null;

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
            border: TableBorder(
              horizontalInside: BorderSide(color: Theme.of(context).textTheme.bodyText2!.color!.withOpacity(.5)),
            ),
            columnWidths: const {
              0: IntrinsicColumnWidth(),
              1: FlexColumnWidth(),
            },
            children: [
              _descriptionRow(
                  AppLocalizations.of(context)!.status, l.status?.name ?? AppLocalizations.of(context)!.unknown),
              _descriptionRow(AppLocalizations.of(context)!.statusDescription,
                  l.status?.description ?? AppLocalizations.of(context)!.unknown),
              if ((l.probability ?? -1) > 0)
                _descriptionRow(AppLocalizations.of(context)!.startProbability, "${l.probability!}%"),
              if ((l.holdreason ?? "").isNotEmpty)
                _descriptionRow(AppLocalizations.of(context)!.holdReason, l.holdreason!),
              if ((l.failreason ?? "").isNotEmpty)
                _descriptionRow(AppLocalizations.of(context)!.failReason, l.failreason!),
              if (l.mission?.orbit != null)
                _descriptionRow(
                  AppLocalizations.of(context)!.targetOrbit,
                  l.mission!.orbit!.name ?? AppLocalizations.of(context)!.unknown,
                ),
              if (windowStart != null)
                _descriptionRow(
                    AppLocalizations.of(context)!.windowStart, formatDateTimeFriendlyText(context, windowStart)),
              if (windowEnd != null)
                _descriptionRow(
                    AppLocalizations.of(context)!.windowEnd,
                    formatDateTimeFriendlyText(context, windowEnd) +
                        (windowStart == windowEnd ? " (${AppLocalizations.of(context)!.likeStartTime})" : "")),
              if (landing != null) ...[
                if (landing.type != null) ...[
                  if (landing.type!.name != null && landing.type!.abbrev != null)
                    _descriptionRow(
                      AppLocalizations.of(context)!.landingType,
                      (landing.type!.name! + " (" + landing.type!.abbrev! + ")"),
                    )
                  else
                    _descriptionRow(
                      AppLocalizations.of(context)!.landingType,
                      landing.type!.name ?? landing.type!.abbrev ?? AppLocalizations.of(context)!.unknown,
                    ),
                ],
                if (landing.location?.name != null)
                  _descriptionRow(AppLocalizations.of(context)!.landingLocation, landing.location?.name),
                if (landing.success == true)
                  _descriptionRow(AppLocalizations.of(context)!.landingSuccess, AppLocalizations.of(context)!.yes)
                else if (landing.success == false)
                  _descriptionRow(AppLocalizations.of(context)!.landingSuccess, AppLocalizations.of(context)!.no),
              ],
              if (lastUpdated != null)
                _descriptionRow(
                    AppLocalizations.of(context)!.lastUpdate, formatDateTimeFriendlyText(context, lastUpdated)),
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

          return LaunchSubscriptionWidget(value, launchId, subscriptionManager);
        }

        return const PlanetLoadingAnimation();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final launchName = widget.launch.name ?? AppLocalizations.of(context)!.unknownLaunch;

    return Scaffold(
      appBar: CustomAppBar.create(
        context,
        title: launchName,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // If we have an image, we show it at the top
            if (widget.launch.image != null) ...[
              _zoomableImage(),
            ],

            // Then a mission description
            ...[
              if (widget.launch.mission == null)
                _reducedMissionDetails(context, widget.launch)
              else
                _missionDetails(context, widget.launch.mission!),
            ],

            if (widget.launch.id != null && !kIsWeb) ...[
              const Divider(),
              _subscription(widget.launch.id!),
            ],

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
              (widget.launch.vidUrls ?? []).length == 1
                  ? AppLocalizations.of(context)!.video
                  : AppLocalizations.of(context)!.videos,
              (ctx, vid) => _urlInfoArticleWidget(
                ctx,
                vid,
                false,
                const Icon(Icons.play_arrow, size: 72),
              ),
            ),

            // Now a list of updates to the data
            if ((widget.launch.updates ?? []).isNotEmpty) ...[
              const Divider(),
              ...renderUpdateList(context, titleStyle, widget.launch.updates!),
            ],

            // An informative description of the rocket
            if (widget.launch.rocket?.configuration?.description != null) ...[
              const Divider(),
              _rocketConfiguration(context, widget.launch.rocket!.configuration!),
            ],

            // Info for the upper stage (e.g. Starship number)
            if ((widget.launch.rocket?.spacecraftStage) != null) ...[
              const Divider(),
              _spacecraftStage(context, widget.launch.rocket!.spacecraftStage!),
            ],

            // Info for the first stage (e.g. Starship/Falcon booster)
            if ((widget.launch.rocket?.launcherStage ?? []).isNotEmpty) ...[
              const Divider(),
              ..._launcherStages(context, widget.launch.rocket?.launcherStage ?? []),
            ],

            // And a bunch of info about the launch provider
            if (widget.launch.launchServiceProvider?.description != null) ...[
              const Divider(),
              _launchServiceProvider(
                context,
                widget.launch.launchServiceProvider!,
              ),
            ],

            // There are some incomplete pads that we shouldn't render6
            if (widget.launch.pad != null && widget.launch.pad?.location?.countryCode != "UNK") ...[
              const Divider(),
              _launchPad(context, widget.launch.pad!),
            ],

            if ((widget.launch.program ?? []).isNotEmpty) ...[
              const Divider(),
              ...renderProgramInfo(context, widget.launch.program!),
            ]
          ],
        ),
      ),
    );
  }
}

class LaunchSubscriptionWidget extends StatefulWidget {
  const LaunchSubscriptionWidget(this.initialValue, this.launchId, this.subscriptionManager, {Key? key})
      : super(key: key);

  final bool initialValue;
  final String launchId;
  final BackgroundHandler subscriptionManager;

  @override
  _LaunchSubscriptionWidgetState createState() => _LaunchSubscriptionWidgetState();
}

class _LaunchSubscriptionWidgetState extends State<LaunchSubscriptionWidget> {
  bool? value;

  void _onCheckChange(newValue) async {
    if (newValue == true) {
      await widget.subscriptionManager.subscribeToLaunch(widget.launchId);
    } else if (newValue == false) {
      await widget.subscriptionManager.unsubscribeFromLaunch(widget.launchId);
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
          title: Text(AppLocalizations.of(context)!.launchSubscribe),
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
