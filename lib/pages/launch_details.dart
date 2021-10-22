import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pinch_zoom_image_last/pinch_zoom_image_last.dart';
import 'package:rockit/apis/launch_library/upcoming_response.dart';
import 'package:rockit/mixins/attribution.dart';
import 'package:rockit/mixins/date_format.dart';
import 'package:rockit/mixins/url_launcher.dart';
import 'package:rockit/widgets/article.dart';
import 'package:rockit/widgets/countdown.dart';
import 'package:rockit/widgets/launch_image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
        style: textStyle.copyWith(
          color: Theme.of(context).textTheme.bodyText2!.color,
        ),
      ),
    );
  }

  List<Widget> _launchServiceProvider(
      BuildContext context, LaunchServiceProvider provider) {
    return [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          provider.name ?? AppLocalizations.of(context)!.unknown,
          style: titleStyle,
          textAlign: TextAlign.center,
        ),
      ),
      if (provider.logoUrl != null)
        GestureDetector(
          onTap: () async {
            if (provider.infoUrl != null) {
              openCustomTab(context, provider.infoUrl!);
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            constraints: BoxConstraints(
              maxHeight: max(MediaQuery.of(context).size.height / 8, 50),
            ),
            child: CachedNetworkImage(
              imageUrl: provider.logoUrl!,
              fadeInDuration: const Duration(milliseconds: 125),
              fadeOutDuration: const Duration(milliseconds: 250),
              fit: BoxFit.cover,
              progressIndicatorBuilder: (context, url, downloadProgress) =>
                  Center(
                child:
                    CircularProgressIndicator(value: downloadProgress.progress),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
        ),
      Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          provider.description ?? AppLocalizations.of(context)!.unknown,
          style: textStyle,
        ),
      )
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
      [bool customTab = true]) {
    return ArticleCardWidget(
      title: info.title,
      link: info.url,
      imageUrl: info.featureImage,
      newsSite: urlHost(info.url),
      summary: info.description,
      customTab: customTab,
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
      padding: const EdgeInsets.all(8.0),
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
            if ((widget.launch.infoUrls ?? []).isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
                child: Text(
                  AppLocalizations.of(context)!.articles,
                  style: titleStyle,
                ),
              ),
              ...widget.launch.infoUrls!.map(
                (info) => _urlInfoArticleWidget(context, info),
              ),
              const Divider(),
            ],
            if ((widget.launch.vidUrls ?? []).isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
                child: Text(
                  AppLocalizations.of(context)!.videos,
                  style: titleStyle,
                ),
              ),
              ...widget.launch.vidUrls!.map(
                (vid) => _urlInfoArticleWidget(context, vid, false),
              ),
              const Divider(),
            ],
            if ((widget.launch.updates ?? []).isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
                child: Text(
                  AppLocalizations.of(context)!.updates,
                  style: titleStyle,
                ),
              ),
              ...widget.launch.updates!.map((e) => _update(context, e)),
              const Divider(),
            ],
            if (widget.launch.launchServiceProvider?.description != null)
              ..._launchServiceProvider(
                  context, widget.launch.launchServiceProvider!),
          ],
        ),
      ),
    );
  }
}
