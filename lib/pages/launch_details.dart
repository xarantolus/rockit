import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pinch_zoom_image_last/pinch_zoom_image_last.dart';
import 'package:rockit/apis/launch_library/upcoming_response.dart';
import 'package:rockit/apis/spaceflightnews/article_response.dart';
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
    with DateFormatter, UrlLauncher {
  static const titleStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
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
        style: const TextStyle(
          fontSize: 16,
        ),
      ),
    );
  }

  String? _urlHost(String? url) {
    var host = Uri.tryParse(url ?? "")?.host;
    if (host != null) {
      const wwwPrefix = "www.";
      if (host.startsWith(wwwPrefix)) {
        host = host.substring(wwwPrefix.length);
      }
    }
    return host;
  }

  String? _sourceAttributionText(String? infoURL) {
    var infoHost = _urlHost(infoURL);

    String? bottomLeftText;
    if (infoURL != null) {
      // For some hosts, we can have special text instead of the host name
      final specialHostFuncs = <String, String? Function(Uri)>{
        // Social media sites used for announcements
        "twitter.com": (uri) {
          // Make sure it's a link to a tweet, e.g. like
          // https://twitter.com/accountname/status/1897358912732835
          if (uri.pathSegments.length >= 3 &&
              uri.pathSegments[1] == "status" &&
              int.tryParse(uri.pathSegments[2]) != null) {
            return "@${uri.pathSegments.first} on Twitter";
          }
          return null;
        },
        "facebook.com": (_) => "Facebook",

        // News sites
        "spacenews.com": (_) => "SpaceNews",
        "spaceflightnow.com": (_) => "Spaceflight Now",
        "nasaspaceflight.com": (_) => "NASASpaceFlight",
        "spaceref.com": (_) => "SpaceRef",

        // Other
        "fcc.report": (_) => "FCC Report",

        // Forums
        "forum.nasaspaceflight.com": (_) => "NASASpaceFlight Forum",

        // Sites from https://en.wikipedia.org/wiki/List_of_government_space_agencies#Budgets
        "nasa.gov": (_) => "NASA",
        "cnsa.gov.cn": (_) => "CNSA",
        "esa.int": (_) => "ESA",
        "dlr.de": (_) => "DLR",
        "cnes.fr": (_) => "CNES",
        "roscosmos.ru": (_) => "Roscosmos",
        "isro.gov.in": (_) => "ISRO",
        "asi.it": (_) => "ASI",
        "jaxa.jp": (_) => "JAXA",
        "kari.re.kr": (_) => "KARI",
        "gov.uk": (_) => "UKSA",

        // Private space companies, from https://en.wikipedia.org/wiki/List_of_private_spaceflight_companies
        "spacex.com": (_) => "SpaceX",
        "blueorigin.com": (_) => "Blue Origin",
        "boeing.com": (_) => "Boeing",
        "virginorbit.com": (_) => "Virgin Orbit",
        "virgingalactic.com": (_) => "Virgin Galactic",
        "mhi.com": (_) => "Mitsubishi Heavy Industries",
        "northropgrumman.com": (_) => "Northrop Grumman",
        "scaled.com": (_) => "Scaled Composites",
        "sncorp.com": (_) => "Sierra Nevada Corporation"
      };

      var infoText = infoHost;
      if (specialHostFuncs.containsKey(infoHost?.toLowerCase())) {
        final uri = Uri.tryParse(infoURL);
        if (uri != null) {
          var newText = specialHostFuncs[infoHost!.toLowerCase()]!(uri);
          if (newText != null) {
            infoText = newText;
          }
        }
      }

      bottomLeftText = infoHost == null
          ? AppLocalizations.of(context)!.clickSource
          : "${AppLocalizations.of(context)!.source}: $infoText";
    }

    return bottomLeftText;
  }

  Widget _update(BuildContext context, Update u) {
    final date = formatDateTimeFriendly(context,
        (DateTime.tryParse(u.createdOn ?? "") ?? DateTime.now()).toLocal());

    return RippleLinkWidget(
      u.comment ?? AppLocalizations.of(context)!.unknown,
      bottomRight: date,
      bottomLeft: _sourceAttributionText(u.infoUrl),
      url: u.infoUrl,
    );
  }

  Widget _urlInfoArticleWidget(BuildContext context, URLInfo info,
      [bool customTab = true]) {
    return ArticleCardWidget(
      title: info.title,
      link: info.url,
      imageUrl: info.featureImage,
      newsSite: _urlHost(info.url),
      summary: info.description,
      customTab: customTab,
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
          ],
        ),
      ),
    );
  }
}
