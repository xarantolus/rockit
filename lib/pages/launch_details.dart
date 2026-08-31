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
import 'package:rockit/widgets/addons/notification_note.dart';
import 'package:rockit/widgets/addons/detail_section.dart';
import 'package:rockit/widgets/addons/launch_hero.dart';
import 'package:rockit/widgets/addons/launch_timeline.dart';
import 'package:rockit/time/precision_time.dart';
import 'package:rockit/util/ordinal.dart';
import 'package:rockit/widgets/addons/insets.dart';
import 'package:rockit/widgets/addons/planet_loading_animation.dart';
import 'package:rockit/widgets/addons/readable_width.dart';
import 'package:rockit/widgets/addons/content_url_card.dart';
import 'package:rockit/widgets/image.dart';

class LaunchDetailsPage extends StatefulWidget {
  const LaunchDetailsPage(
    this.launch, {
    this.heroPrefix = "",
    this.heroEnabled = true,
    this.openUpdates = false,
    super.key,
  });

  final Launch launch;

  final String heroPrefix;

  /// False for a page that is built but not the one being looked at.
  ///
  /// The detail pages live in a horizontal PageView, which builds its
  /// neighbours. Every one of them carrying a hero meant a pop flew several
  /// images back to the list at once — most visible when the system back
  /// gesture also nudged the PageView, so two pages were partly on screen.
  final bool heroEnabled;

  /// Set when the user arrived from an update notification. Nothing collapses
  /// any more, so this scrolls to the updates rather than expanding them.
  final bool openUpdates;

  /// Patches that actually have artwork.
  ///
  /// The API sometimes lists a patch with no image, and rendering is filtered
  /// on that — so the section's count has to be filtered the same way, or it
  /// advertises "1" and expands to nothing.
  static List<MissionPatch> renderablePatches(List<MissionPatch> all) {
    return all
        .where((patch) => (patch.image?.imageUrl ?? "").isNotEmpty)
        .toList();
  }

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
  /// Anchors the updates card so an update notification can scroll to it.
  final _updatesKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    if (widget.openUpdates) {
      // After the first frame, so the card exists and its offset is known.
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToUpdates());
    }
  }

  void _scrollToUpdates() {
    final target = _updatesKey.currentContext;
    if (target == null || !mounted) {
      return;
    }

    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  static const titleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static const textStyle = TextStyle(fontSize: 16);

  /// Just the description. The mission name is already the hero title, so
  /// repeating it here said the same thing twice.
  Widget _missionDetails(BuildContext context, Mission m) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Text(
        m.description ?? AppLocalizations.of(context)!.noDescription,
        softWrap: true,
        style: textStyle.copyWith(
          color: Theme.of(context).textTheme.bodyMedium!.color,
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
      showTitle: false,
    );
  }

  Widget _launchServiceProvider(BuildContext context, Agency provider) {
    return _titleImageDescription(
      context,
      clickURL: provider.infoUrl,
      title: provider.name,
      description: provider.description,
      imageURL: provider.logo?.imageUrl ?? provider.image?.imageUrl,
      showTitle: false,
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

  Widget _rocketConfiguration(BuildContext context, RocketConfiguration cfg) {
    return _titleImageDescription(
      context,
      title: cfg.fullName,
      description: cfg.description,
      clickURL: cfg.infoUrl,
      imageURL: cfg.image?.imageUrl,
      showTitle: false,
    );
  }

  Widget _titleImageDescription(
    BuildContext context, {
    String? title,
    String? description,
    String? imageURL,
    String? clickURL,
    bool shrinkImage = true,
    // The card label already names these, so repeating it as a heading inside
    // would say the same thing twice.
    bool showTitle = true,
  }) {
    void openClickURL() async {
      if ((clickURL ?? "").isNotEmpty) {
        openCustomTab(context, clickURL!);
      }
    }

    // Nothing to say. This used to render "Unknown" under "Unknown", which is
    // how an unnamed spacecraft stage ended up at the bottom of every rocket.
    if ((title ?? "").isEmpty &&
        (description ?? "").isEmpty &&
        (imageURL ?? "").isEmpty) {
      return const SizedBox.shrink();
    }

    final imageWidget = imageURL == null ? null : ImageWidget(imageURL);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: (clickURL ?? "").isNotEmpty ? openClickURL : null,
        onLongPress: (clickURL ?? "").isEmpty
            ? null
            : () => copyLink(context, clickURL),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              if (showTitle && (title ?? "").isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    title!,
                    style: titleStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
              if (imageURL != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  // A flat cap, not a fraction of the screen height: these
                  // are logos and diagrams, and they do not get more
                  // informative on a taller phone.
                  constraints: shrinkImage
                      ? const BoxConstraints(maxHeight: 200)
                      : null,
                  child: imageWidget,
                ),
              if ((description ?? "").isNotEmpty)
                Text(description!, style: textStyle),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _missionPatchCards(
    BuildContext context,
    List<MissionPatch> patches,
  ) {
    return patches
        .map((e) => _missionPatch(context, e, patches.length == 1))
        .toList();
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
          Center(child: ImageWidget(patch.image?.imageUrl)),
        ],
      ),
    );
  }

  Widget _descriptionRow(String description, String? value) {
    return DetailRow(
      label: description,
      value: value ?? AppLocalizations.of(context)!.unknown,
    );
  }

  Widget _generalInfo(BuildContext context, Launch l) {
    final lastUpdated = l.lastUpdated;

    final windowStart = l.windowStart;
    final windowEnd = l.windowEnd;

    final landings = widget.launch.rocket?.launcherStage ?? const [];
    final landing = landings.isNotEmpty ? landings.first.landing : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            if (l.mission?.orbit?.label != null)
              _descriptionRow(
                AppLocalizations.of(context)!.targetOrbit,
                l.mission!.orbit!.name ?? l.mission!.orbit!.label!,
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
    );
  }

  /// Two or three quiet lines of context the API sends on every launch and the
  /// app used to drop entirely: where this flight sits in the provider's year,
  /// in the pad's history, and how fast the pad was turned around.
  Widget _launchStats(BuildContext context, Launch l) {
    final localizations = AppLocalizations.of(context)!;
    final lines = <String>[];

    final agencyYear = l.agencyLaunchAttemptCountYear;
    final provider = l.providerName;
    if (agencyYear != null && agencyYear > 0 && provider != null) {
      lines.add(
        localizations.agencyLaunchThisYear(
          englishOrdinal(agencyYear),
          provider,
        ),
      );
    }

    final padCount = l.padLaunchAttemptCount;
    final padName = l.pad?.name;
    if (padCount != null && padCount > 0 && padName != null) {
      lines.add(
        localizations.padLaunchNumber(englishOrdinal(padCount), padName),
      );
    }

    final turnaround = l.padTurnaround;
    if (turnaround != null && turnaround.inDays >= 1) {
      final days = localizations.daysUnit(turnaround.inDays);

      // The gap is measured from this launch, so subtracting it lands on the
      // previous one. Only worth doing when this launch's own time is real:
      // taking 122 days off a date known to the month invents precision.
      final net = l.net;
      final lastUsed =
          net != null && showsExactDay(timeDisplayFor(net, l.netPrecision))
          ? formatDate(context, net.subtract(turnaround).toLocal())
          : null;

      lines.add(
        lastUsed == null
            ? localizations.padLastUsed(days)
            : localizations.padLastUsedOn(days, lastUsed),
      );
    }

    if (lines.isEmpty) {
      return const SizedBox.shrink();
    }

    final muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines
            .map(
              (line) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(line, style: TextStyle(fontSize: 13, color: muted)),
              ),
            )
            .toList(),
      ),
    );
  }

  /// One booster, with the reuse story spelled out. A 56dp avatar is one of the
  /// few places the 256x256 thumbnail is genuinely the right image.
  Widget _boosterCard(BuildContext context, LauncherStage stage) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.65);

    final launcher = stage.launcher;
    final landing = stage.landing;

    final facts = <String>[];
    if (stage.launcherFlightNumber != null) {
      facts.add(localizations.boosterFlight(stage.launcherFlightNumber!));
    }
    if (stage.turnAroundTime != null && stage.turnAroundTime!.inDays >= 1) {
      facts.add(
        localizations.boosterTurnaround(
          localizations.daysUnit(stage.turnAroundTime!.inDays),
        ),
      );
    }

    final dpr = MediaQuery.of(context).devicePixelRatio;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (launcher?.image != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                height: 56,
                child: ImageWidget(launcher!.image!.urlFor(56 * dpr)),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        launcher?.serialNumber ?? stage.type ?? "",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (stage.reused != null)
                      InfoChip(
                        label: stage.reused!
                            ? localizations.boosterReused
                            : localizations.boosterNew,
                      ),
                  ],
                ),
                if (facts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      facts.join(" · "),
                      style: TextStyle(fontSize: 13.5, color: muted),
                    ),
                  ),
                if (landing != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    landing.attempt == false
                        ? localizations.boosterNoLanding
                        : [
                            localizations.boosterLanding,
                            [
                              landing.type,
                              landing.landingLocation?.abbrev ??
                                  landing.landingLocation?.name,
                            ].whereType<String>().join(", "),
                          ].where((p) => p.isNotEmpty).join(": "),
                    style: TextStyle(fontSize: 13.5, color: muted),
                  ),
                  if (landing.downrangeDistance != null)
                    Text(
                      localizations.downrange(
                        landing.downrangeDistance!.toStringAsFixed(1),
                      ),
                      style: TextStyle(fontSize: 13, color: muted),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The physical numbers. Only rows the API actually filled in are rendered,
  /// so a sparsely-described rocket shows a short table rather than a wall of
  /// "Unknown".
  Widget _rocketSpecs(BuildContext context, RocketConfiguration cfg) {
    final localizations = AppLocalizations.of(context)!;
    final rows = <(String, String)>[];

    void add(String label, String? value) {
      if (value != null) rows.add((label, value));
    }

    String? number(num? value) {
      if (value == null) {
        return null;
      }

      return value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
    }

    add(
      localizations.specHeight,
      cfg.length == null ? null : localizations.metres(number(cfg.length)!),
    );
    add(
      localizations.specDiameter,
      cfg.diameter == null ? null : localizations.metres(number(cfg.diameter)!),
    );
    add(
      localizations.specMassToLeo,
      cfg.leoCapacity == null
          ? null
          : localizations.kilograms(_thousands(cfg.leoCapacity!)),
    );
    add(
      localizations.specMassToGto,
      cfg.gtoCapacity == null
          ? null
          : localizations.kilograms(_thousands(cfg.gtoCapacity!)),
    );
    add(localizations.specStages, cfg.maxStage?.toString());
    add(
      localizations.specMaidenFlight,
      cfg.maidenFlight == null ? null : formatDate(context, cfg.maidenFlight!),
    );
    if (cfg.successfulLaunches != null && cfg.failedLaunches != null) {
      add(
        localizations.specRecord,
        localizations.specRecordValue(
          cfg.successfulLaunches!,
          cfg.failedLaunches!,
        ),
      );
    }

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows
          .map((row) => DetailRow(label: row.$1, value: row.$2))
          .toList(),
    );
  }

  static String _thousands(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// The facts worth seeing without opening anything: what is flying, where to,
  /// and from where.
  Widget _quickFacts(BuildContext context, Launch l) {
    final chips = <Widget>[
      if (l.rocketName != null)
        InfoChip(label: l.rocketName!, icon: Icons.rocket_launch),
      if (l.mission?.orbit?.label != null)
        InfoChip(label: l.mission!.orbit!.label!, icon: Icons.track_changes),
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

    final patches = LaunchDetailsPage.renderablePatches(
      widget.launch.missionPatches,
    );

    return Scaffold(
      appBar: CustomAppBar.create(context, title: launchName),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: bottomSystemBarPadding(context),
        child: ReadableWidth(
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
                heroTag: widget.heroEnabled
                    ? "${widget.heroPrefix}launch-image"
                    : null,
                heroId: widget.launch.id,
              ),

              _quickFacts(context, widget.launch),

              _launchStats(context, widget.launch),

              if (widget.launch.id != null && !kIsWeb)
                _subscription(widget.launch.id!),

              // Open by default: it is what the page is about. Dropped entirely
              // when there is no description, since the name is already the hero.
              if ((widget.launch.mission?.description ?? "").isNotEmpty)
                DetailCard(
                  title: AppLocalizations.of(context)!.mission,
                  child: _missionDetails(context, widget.launch.mission!),
                ),

              DetailCard(
                title: AppLocalizations.of(context)!.info,
                child: _generalInfo(context, widget.launch),
              ),

              if (widget.launch.rocket?.configuration != null)
                DetailCard(
                  title: AppLocalizations.of(context)!.rocket,
                  trailing: widget.launch.rocketName,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if ((widget.launch.rocket?.configuration?.description ??
                              "")
                          .isNotEmpty)
                        _rocketConfiguration(
                          context,
                          widget.launch.rocket!.configuration!,
                        ),
                      _rocketSpecs(
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
                DetailCard(
                  title: AppLocalizations.of(context)!.boosters,

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: widget.launch.rocket!.launcherStage
                        .map((stage) => _boosterCard(context, stage))
                        .toList(),
                  ),
                ),

              if (widget.launch.pad != null &&
                  widget.launch.pad?.country != "Unknown")
                DetailCard(
                  title: AppLocalizations.of(context)!.launchSite,
                  trailing: widget.launch.pad?.name,
                  child: _launchPad(context, widget.launch.pad!),
                ),

              if (widget.launch.timeline.isNotEmpty)
                DetailCard(
                  title: AppLocalizations.of(context)!.timeline,
                  child: LaunchTimeline(
                    events: widget.launch.timeline,
                    net: widget.launch.net,
                    precision: widget.launch.netPrecision,
                  ),
                ),

              if (widget.launch.updates.isNotEmpty)
                DetailCard(
                  key: _updatesKey,
                  title: AppLocalizations.of(context)!.updates,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: renderUpdateList(context, widget.launch.updates),
                  ),
                ),

              if (widget.launch.vidUrls.isNotEmpty)
                DetailCard(
                  title: AppLocalizations.of(context)!.videos,
                  // The article pads its own text; letting it reach the card's
                  // edges gives the image the same full-bleed width a listing
                  // card's photo has.
                  padded: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: widget.launch.vidUrls
                        .map(
                          (vid) => ContentUrlCard(
                            vid,
                            customTab: false,
                            icon: const Icon(Icons.play_arrow, size: 72),
                          ),
                        )
                        .toList(),
                  ),
                ),

              if (widget.launch.infoUrls.isNotEmpty)
                DetailCard(
                  title: AppLocalizations.of(context)!.moreInfo,
                  // The article pads its own text; letting it reach the card's
                  // edges gives the image the same full-bleed width a listing
                  // card's photo has.
                  padded: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: widget.launch.infoUrls
                        .map((info) => ContentUrlCard(info))
                        .toList(),
                  ),
                ),

              if (patches.isNotEmpty)
                DetailCard(
                  title: patches.length == 1
                      ? AppLocalizations.of(context)!.missionPatch
                      : AppLocalizations.of(context)!.missionPatches,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _missionPatchCards(context, patches),
                  ),
                ),

              if ((widget.launch.launchServiceProvider?.description ?? "")
                  .isNotEmpty)
                DetailCard(
                  title: AppLocalizations.of(context)!.source,
                  trailing: widget.launch.providerName,
                  child: _launchServiceProvider(
                    context,
                    widget.launch.launchServiceProvider!,
                  ),
                ),

              if (widget.launch.program.isNotEmpty)
                DetailCard(
                  title: AppLocalizations.of(context)!.programs,
                  padded: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: renderProgramInfo(context, widget.launch.program),
                  ),
                ),
            ],
          ),
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
        NotificationNote(
          description: AppLocalizations.of(
            context,
          )!.notificationDescriptionLaunch,
        ),
      ],
    );
  }
}
