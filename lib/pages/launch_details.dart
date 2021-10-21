import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pinch_zoom_image_last/pinch_zoom_image_last.dart';
import 'package:rockit/apis/launch_library/upcoming_response.dart';
import 'package:rockit/mixins/date_format.dart';
import 'package:rockit/mixins/url_launcher.dart';
import 'package:rockit/widgets/countdown.dart';
import 'package:rockit/widgets/launch_image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LaunchDetailsPage extends StatefulWidget {
  const LaunchDetailsPage(this.launch, {Key? key}) : super(key: key);

  final Launch launch;

  @override
  _LaunchDetailsPageState createState() => _LaunchDetailsPageState();
}

class _LaunchDetailsPageState extends State<LaunchDetailsPage>
    with DateFormatter, UrlLauncher {
  static const titleStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  Widget _zoomableImage() {
    return SizedBox(
      height: max(MediaQuery.of(context).size.height / 3, 250),
      child: PinchZoomImage(
        image: Center(
          child: LaunchImageWidget(widget.launch),
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
        ),
      ),
      subtitle: Text(
        m.description ?? AppLocalizations.of(context)!.noDescription,
        softWrap: true,
        style: const TextStyle(
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _update(BuildContext context, Update u) {
    final date = formatDateTimeFriendly(context,
        (DateTime.tryParse(u.createdOn ?? "") ?? DateTime.now()).toLocal());

    var infoHost = Uri.tryParse(u.infoUrl ?? "")?.host;
    if (infoHost != null) {
      const wwwPrefix = "www.";
      if (infoHost.startsWith(wwwPrefix)) {
        infoHost = infoHost.substring(wwwPrefix.length);
      }
    }

    final tile = ListTile(
      title: Text(
        u.comment ?? AppLocalizations.of(context)!.unknown,
      ),
      subtitle: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // We need an empty widget here, because if we don't add this, the date text will be on the left
          if (u.infoUrl == null)
            const SizedBox.shrink()
          else
            Align(
              alignment: Alignment.centerLeft,
              child: infoHost == null
                  ? Text(AppLocalizations.of(context)!.clickSource)
                  : Text("${AppLocalizations.of(context)!.source}: $infoHost"),
            ),
          Align(alignment: Alignment.centerRight, child: Text(date)),
        ],
      ),
      visualDensity: VisualDensity.comfortable,
    );

    if (u.infoUrl == null) {
      return tile;
    }

    return GestureDetector(
      child: tile,
      onTap: () async {
        await openCustomTab(context, u.infoUrl!);
      },
    );
  }

  Widget _generalInfo(BuildContext context, Launch l) {
    const tableDescriptionStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
    );
    const tableTextStyle = TextStyle(
      fontSize: 16,
    );

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
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context)!.info,
            style: titleStyle,
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
            if (widget.launch.image != null) ...[
              _zoomableImage(),
              const Divider(),
            ],
            if (widget.launch.mission != null) ...[
              _missionDetails(context, widget.launch.mission!),
              const Divider(),
            ],
            CountDownWidget(widget.launch),
            const Divider(),
            _generalInfo(context, widget.launch),
            const Divider(),
            if ((widget.launch.updates ?? []).isNotEmpty) ...[
              Text(
                AppLocalizations.of(context)!.updates,
                style: titleStyle,
              ),
              ...widget.launch.updates!.map((e) => _update(context, e)),
              const Divider(),
            ],
          ],
        ),
      ),
    );
  }
}
