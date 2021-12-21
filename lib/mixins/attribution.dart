import 'package:flutter/cupertino.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

mixin SourceAttribution {
  static final specialHostFuncs = <String, String? Function(BuildContext, Uri)>{
    // Social media sites used for announcements
    "twitter.com": (context, uri) {
      // Make sure it's a link to a tweet, e.g. like
      // https://twitter.com/accountname/status/1897358912732835
      if (uri.pathSegments.length >= 3 &&
          uri.pathSegments[0] != "i" &&
          uri.pathSegments[1] == "status" &&
          int.tryParse(uri.pathSegments[2]) != null) {
        return AppLocalizations.of(context)!.onTwitter(uri.pathSegments.first);
      }
      return null;
    },
    "facebook.com": (_, __) => "Facebook",

    // News sites
    "spacenews.com": (_, __) => "SpaceNews",
    "spaceflightnow.com": (_, __) => "Spaceflight Now",
    "nasaspaceflight.com": (_, __) => "NASASpaceFlight",
    "spaceref.com": (_, __) => "SpaceRef",

    // Other
    "fcc.report": (_, __) => "FCC Report",

    // Forums
    "forum.nasaspaceflight.com": (_, __) => "NASASpaceFlight Forum",

    // Sites from https://en.wikipedia.org/wiki/List_of_government_space_agencies#Budgets
    "nasa.gov": (_, __) => "NASA",
    "cnsa.gov.cn": (_, __) => "CNSA",
    "esa.int": (_, __) => "ESA",
    "dlr.de": (_, __) => "DLR",
    "cnes.fr": (_, __) => "CNES",
    "roscosmos.ru": (_, __) => "Roscosmos",
    "isro.gov.in": (_, __) => "ISRO",
    "asi.it": (_, __) => "ASI",
    "jaxa.jp": (_, __) => "JAXA",
    "kari.re.kr": (_, __) => "KARI",
    "gov.uk": (_, __) => "UKSA",

    // Private space companies, from https://en.wikipedia.org/wiki/List_of_private_spaceflight_companies
    "spacex.com": (_, __) => "SpaceX",
    "blueorigin.com": (_, __) => "Blue Origin",
    "boeing.com": (_, __) => "Boeing",
    "astra.com": (_, __) => "Astra",
    "virginorbit.com": (_, __) => "Virgin Orbit",
    "virgingalactic.com": (_, __) => "Virgin Galactic",
    "mhi.com": (_, __) => "Mitsubishi Heavy Industries",
    "northropgrumman.com": (_, __) => "Northrop Grumman",
    "scaled.com": (_, __) => "Scaled Composites",
    "sncorp.com": (_, __) => "Sierra Nevada Corporation"
  };

  String? sourceAttributionText(BuildContext context, String? infoURL) {
    var infoHost = urlHost(infoURL);

    String? bottomLeftText;
    if (infoURL != null) {
      // For some hosts, we can have special text instead of the host name

      var infoText = infoHost;
      if (specialHostFuncs.containsKey(infoHost?.toLowerCase())) {
        final uri = Uri.tryParse(infoURL);
        if (uri != null) {
          var newText =
              specialHostFuncs[infoHost!.toLowerCase()]!(context, uri);
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

  String? urlHost(String? url) {
    var host = Uri.tryParse(url ?? "")?.host;
    if (host != null) {
      const wwwPrefix = "www.";
      if (host.startsWith(wwwPrefix)) {
        host = host.substring(wwwPrefix.length);
      }
    }

    if (host?.isEmpty ?? true) {
      return null;
    }

    return host;
  }
}
