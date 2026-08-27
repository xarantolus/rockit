import 'dart:ui' show FontFeature;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rockit/l10n/app_localizations.dart';
import 'package:rockit/apis/launch_library/launch_response.dart';
import 'package:rockit/background/handler.dart';
import 'package:rockit/mixins/attribution.dart';
import 'package:rockit/mixins/date_format.dart';
import 'package:rockit/mixins/link_copy.dart';
import 'package:rockit/mixins/program_renderer.dart';
import 'package:rockit/mixins/update_renderer.dart';
import 'package:rockit/mixins/url_launcher.dart';
import 'package:rockit/widgets/addons/app_bar.dart';
import 'package:rockit/widgets/addons/detail_section.dart';
import 'package:rockit/widgets/addons/launch_hero.dart';
import 'package:rockit/widgets/addons/insets.dart';
import 'package:rockit/widgets/addons/planet_loading_animation.dart';
import 'package:rockit/widgets/article.dart';
import 'package:rockit/widgets/image.dart';

class LaunchDetailsPage extends StatefulWidget {
  const LaunchDetailsPage(this.launch, {this.heroPrefix = "", super.key});

  final Launch launch;

  final String heroPrefix;

  @override
  State<LaunchDetailsPage> createState() => _LaunchDetailsPageState();
}

class _LaunchDetailsPageState extends State<LaunchDetailsPage>
    with
        DateFormatter,
        UrlLauncher,
        SourceAttribution,
        UpdateRenderer,
        LinkCopier,
        ProgramRenderer {
  static const titleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const tableDescriptionStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );
  static const tableTextStyle = TextStyle(fontSize: 16);

  static const textStyle = TextStyle(fontSize: 16);
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
          color: Theme.of(context).textTheme.bodyMedium!.color,
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

  Widget _launchServiceProvider(BuildContext context, Agency provider) {
    return _titleImageDescription(
      context,
      clickURL: provider.infoUrl,
      title: provider.name,
      description: provider.description,
      imageURL: provider.logo?.imageUrl ?? provider.image?.imageUrl,
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
      imageURL: stage.launcher?.image?.imageUrl,
    );
  }

  Widget _spacecraftStage(BuildContext context, SpacecraftStage spaceCraft) {
    return _titleImageDescription(
      context,
      title: spaceCraft.name,
      description: spaceCraft.description,
      imageURL: spaceCraft.image?.imageUrl,
    );
  }

  List<Widget> _launcherStages(
    BuildContext context,
    List<LauncherStage> stages,
  ) {
    return stages.map((s) => _stage(context, s)).whereType<Widget>().toList();
  }

  Widget _rocketConfiguration(BuildContext context, RocketConfiguration cfg) {
    return _titleImageDescription(
      context,
      title: cfg.fullName,
      description: cfg.description,
      clickURL: cfg.infoUrl,
      imageURL: cfg.image?.imageUrl,
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
        onLongPress: (clickURL ?? "").isEmpty
            ? null
            : () => copyLink(context, clickURL),
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
                      ? InteractiveViewer(child: Center(child: imageWidget))
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
    final importantPatches = l.where(
      (element) => (element.image?.imageUrl ?? "").isNotEmpty,
    );
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
    BuildContext context,
    MissionPatch patch,
    bool isSingle,
  ) {
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
          InteractiveViewer(
            child: Center(child: ImageWidget(patch.image?.imageUrl)),
          ),
        ],
      ),
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
    final lastUpdated = l.lastUpdated;

    final windowStart = l.windowStart;
    final windowEnd = l.windowEnd;

    final landings = widget.launch.rocket?.launcherStage ?? const [];
    final landing = landings.isNotEmpty ? landings.first.landing : null;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
            child: Text(AppLocalizations.of(context)!.info, style: titleStyle),
          ),
          Table(
            border: TableBorder(
              horizontalInside: BorderSide(
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium!.color!.withValues(alpha: .5),
              ),
            ),
            columnWidths: const {
              0: IntrinsicColumnWidth(),
              1: FlexColumnWidth(),
            },
            children: [
              _descriptionRow(
                AppLocalizations.of(context)!.status,
                l.status?.name ?? AppLocalizations.of(context)!.unknown,
              ),
              _descriptionRow(
                AppLocalizations.of(context)!.statusDescription,
                l.status?.description ?? AppLocalizations.of(context)!.unknown,
              ),
              if ((l.probability ?? -1) > 0)
                _descriptionRow(
                  AppLocalizations.of(context)!.startProbability,
                  "${l.probability!}%",
                ),
              if ((l.failreason ?? "").isNotEmpty)
                _descriptionRow(
                  AppLocalizations.of(context)!.failReason,
                  l.failreason!,
                ),
              if (l.mission?.orbit != null)
                _descriptionRow(
                  AppLocalizations.of(context)!.targetOrbit,
                  l.mission!.orbit!.name ??
                      AppLocalizations.of(context)!.unknown,
                ),
              if (windowStart != null)
                _descriptionRow(
                  AppLocalizations.of(context)!.windowStart,
                  formatDateTimeFriendlyText(context, windowStart),
                ),
              if (windowEnd != null)
                _descriptionRow(
                  AppLocalizations.of(context)!.windowEnd,
                  formatDateTimeFriendlyText(context, windowEnd) +
                      (windowStart == windowEnd
                          ? " (${AppLocalizations.of(context)!.likeStartTime})"
                          : ""),
                ),
              if (landing != null) ...[
                if (landing.type != null)
                  _descriptionRow(
                    AppLocalizations.of(context)!.landingType,
                    landing.type!,
                  ),
                if (landing.landingLocation?.name != null)
                  _descriptionRow(
                    AppLocalizations.of(context)!.landingLocation,
                    landing.landingLocation?.name,
                  ),
                if (landing.success == true)
                  _descriptionRow(
                    AppLocalizations.of(context)!.landingSuccess,
                    AppLocalizations.of(context)!.yes,
                  )
                else if (landing.success == false)
                  _descriptionRow(
                    AppLocalizations.of(context)!.landingSuccess,
                    AppLocalizations.of(context)!.no,
                  ),
              ],
              if (lastUpdated != null)
                _descriptionRow(
                  AppLocalizations.of(context)!.lastUpdate,
                  formatDateTimeFriendlyText(context, lastUpdated),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// The facts worth seeing without opening anything: what is flying, where to,
  /// and from where.
  Widget _quickFacts(BuildContext context, Launch l) {
    final chips = <Widget>[
      if (l.rocketName != null)
        InfoChip(label: l.rocketName!, icon: Icons.rocket_launch),
      if (l.mission?.orbit?.abbrev != null || l.mission?.orbit?.name != null)
        InfoChip(
          label: l.mission!.orbit!.abbrev ?? l.mission!.orbit!.name!,
          icon: Icons.track_changes,
        ),
      if (l.mission?.type != null)
        InfoChip(label: l.mission!.type!, icon: Icons.science_outlined),
      if (l.pad?.name != null)
        InfoChip(label: l.pad!.name!, icon: Icons.place_outlined),
    ];

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Wrap(spacing: 8, runSpacing: 8, children: chips),
    );
  }

  /// e.g. "B1072 - flight 35". Shown while the boosters section is collapsed,
  /// because reuse is the part people actually want from it.
  String? _boosterPreview(BuildContext context, Launch l) {
    final stages = l.rocket?.launcherStage ?? const <LauncherStage>[];
    if (stages.isEmpty) {
      return null;
    }

    final parts = <String>[];
    for (final stage in stages) {
      final serial = stage.launcher?.serialNumber;
      final flight = stage.launcherFlightNumber;

      if (serial == null) continue;
      parts.add(
        flight == null
            ? serial
            : "$serial · ${AppLocalizations.of(context)!.boosterFlight(flight)}",
      );
    }

    return parts.isEmpty ? null : parts.join(", ");
  }

  /// The countdown milestones, when the API has them — only about one launch in
  /// eight does.
  Widget _timeline(BuildContext context, List<TimelineEvent> events) {
    String offset(Duration d) {
      final abs = d.abs();
      final sign = d.isNegative ? "T-" : "T+";
      if (abs.inHours > 0) {
        return "$sign${abs.inHours}h ${abs.inMinutes.remainder(60)}m";
      }
      if (abs.inMinutes > 0) {
        return "$sign${abs.inMinutes}m ${abs.inSeconds.remainder(60)}s";
      }
      return "$sign${abs.inSeconds}s";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: events.map((e) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 84,
                  child: Text(
                    e.relativeTime == null ? "" : offset(e.relativeTime!),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                Expanded(child: Text(e.type ?? e.description ?? "")),
              ],
            ),
          );
        }).toList(),
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
    final launchName =
        widget.launch.name ?? AppLocalizations.of(context)!.unknownLaunch;

    return Scaffold(
      appBar: CustomAppBar.create(context, title: launchName),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: bottomSystemBarPadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LaunchHero(
              image: widget.launch.image,
              title:
                  widget.launch.mission?.name ??
                  widget.launch.name ??
                  AppLocalizations.of(context)!.unknownLaunch,
              subtitle: widget.launch.providerName,
              status: widget.launch.status,
              date: widget.launch.net ?? widget.launch.windowStart,
              precision: widget.launch.netPrecision,
              timezoneName: widget.launch.pad?.location?.timezoneName,
              heroTag: "${widget.heroPrefix}launch-image",
              heroId: widget.launch.id,
            ),

            _quickFacts(context, widget.launch),

            if (widget.launch.id != null && !kIsWeb)
              _subscription(widget.launch.id!),

            // Open by default: it is what the page is about.
            DetailSection(
              title: AppLocalizations.of(context)!.mission,
              initiallyExpanded: true,
              child: widget.launch.mission == null
                  ? _reducedMissionDetails(context, widget.launch)
                  : _missionDetails(context, widget.launch.mission!),
            ),

            DetailSection(
              title: AppLocalizations.of(context)!.info,
              preview: widget.launch.status?.description,
              child: _generalInfo(context, widget.launch),
            ),

            if (widget.launch.rocket?.configuration != null)
              DetailSection(
                title: AppLocalizations.of(context)!.rocket,
                preview: widget.launch.rocketName,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.launch.rocket?.configuration?.description !=
                        null)
                      _rocketConfiguration(
                        context,
                        widget.launch.rocket!.configuration!,
                      ),
                    ...widget.launch.rocket!.spacecraftStage.map(
                      (stage) => _spacecraftStage(context, stage),
                    ),
                  ],
                ),
              ),

            if (widget.launch.rocket?.launcherStage.isNotEmpty ?? false)
              DetailSection(
                title: AppLocalizations.of(context)!.boosters,
                count: widget.launch.rocket!.launcherStage.length,
                preview: _boosterPreview(context, widget.launch),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _launcherStages(
                    context,
                    widget.launch.rocket!.launcherStage,
                  ),
                ),
              ),

            if (widget.launch.pad != null &&
                widget.launch.pad?.country != "Unknown")
              DetailSection(
                title: AppLocalizations.of(context)!.launchSite,
                preview: widget.launch.pad?.name,
                child: _launchPad(context, widget.launch.pad!),
              ),

            if (widget.launch.timeline.isNotEmpty)
              DetailSection(
                title: AppLocalizations.of(context)!.timeline,
                count: widget.launch.timeline.length,
                child: _timeline(context, widget.launch.timeline),
              ),

            if (widget.launch.updates.isNotEmpty)
              DetailSection(
                title: AppLocalizations.of(context)!.updates,
                count: widget.launch.updates.length,
                preview: widget.launch.updates.first.comment,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: renderUpdateList(
                    context,
                    titleStyle,
                    widget.launch.updates,
                  ),
                ),
              ),

            if (widget.launch.vidUrls.isNotEmpty)
              DetailSection(
                title: AppLocalizations.of(context)!.videos,
                count: widget.launch.vidUrls.length,
                preview: widget.launch.vidUrls.first.title,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: widget.launch.vidUrls
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

            if (widget.launch.infoUrls.isNotEmpty)
              DetailSection(
                title: AppLocalizations.of(context)!.moreInfo,
                count: widget.launch.infoUrls.length,
                preview: widget.launch.infoUrls.first.title,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: widget.launch.infoUrls
                      .map((info) => _urlInfoArticleWidget(context, info))
                      .toList(),
                ),
              ),

            if (widget.launch.missionPatches.isNotEmpty)
              DetailSection(
                title: AppLocalizations.of(context)!.missionPatches,
                count: widget.launch.missionPatches.length,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _missionPatches(
                    context,
                    widget.launch.missionPatches,
                  ),
                ),
              ),

            if (widget.launch.launchServiceProvider?.description != null)
              DetailSection(
                title: AppLocalizations.of(context)!.source,
                preview: widget.launch.providerName,
                child: _launchServiceProvider(
                  context,
                  widget.launch.launchServiceProvider!,
                ),
              ),

            if (widget.launch.program.isNotEmpty)
              DetailSection(
                title: AppLocalizations.of(context)!.programs,
                count: widget.launch.program.length,
                preview: widget.launch.program.first.name,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: renderProgramInfo(context, widget.launch.program),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class LaunchSubscriptionWidget extends StatefulWidget {
  const LaunchSubscriptionWidget(
    this.initialValue,
    this.launchId,
    this.subscriptionManager, {
    super.key,
  });

  final bool initialValue;
  final String launchId;
  final BackgroundHandler subscriptionManager;

  @override
  State<LaunchSubscriptionWidget> createState() =>
      _LaunchSubscriptionWidgetState();
}

class _LaunchSubscriptionWidgetState extends State<LaunchSubscriptionWidget> {
  bool? value;

  void _onCheckChange(bool? newValue) async {
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
          child: Text(AppLocalizations.of(context)!.notificationDescription),
        ),
      ],
    );
  }
}
