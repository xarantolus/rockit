import 'package:flutter/cupertino.dart';
import 'package:rockit/l10n/app_localizations.dart';

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
    "x.com": (context, uri) {
      if (uri.pathSegments.length >= 3 &&
          uri.pathSegments[0] != "i" &&
          uri.pathSegments[1] == "status" &&
          int.tryParse(uri.pathSegments[2]) != null) {
        return AppLocalizations.of(context)!.onTwitter(uri.pathSegments.first);
      }
      return null;
    },
    "facebook.com": (_, _) => "Facebook",

    "youtube.com": (_, _) => "YouTube",
    "youtu.be": (_, _) => "YouTube",
    "m.youtube.com": (_, _) => "YouTube",

    // News sites
    "spacenews.com": (_, _) => "SpaceNews",
    "spaceflightnow.com": (_, _) => "Spaceflight Now",
    "nasaspaceflight.com": (_, _) => "NASASpaceFlight",
    "spaceref.com": (_, _) => "SpaceRef",

    // Other
    "fcc.report": (_, _) => "FCC Report",

    // Forums
    "forum.nasaspaceflight.com": (_, _) => "NASASpaceFlight Forum",

    // Sites from https://en.wikipedia.org/wiki/List_of_government_space_agencies#Budgets
    "nasa.gov": (_, _) => "NASA",
    "blogs.nasa.gov": (_, _) => "NASA",
    "cnsa.gov.cn": (_, _) => "CNSA",
    "esa.int": (_, _) => "ESA",
    "dlr.de": (_, _) => "DLR",
    "cnes.fr": (_, _) => "CNES",
    "roscosmos.ru": (_, _) => "Roscosmos",
    "isro.gov.in": (_, _) => "ISRO",
    "asi.it": (_, _) => "ASI",
    "jaxa.jp": (_, _) => "JAXA",
    "kari.re.kr": (_, _) => "KARI",
    "gov.uk": (_, _) => "UKSA",

    // Private space companies, from https://en.wikipedia.org/wiki/List_of_private_spaceflight_companies
    "spacex.com": (_, _) => "SpaceX",
    "rocketlabusa.com": (_, _) => "Rocket Lab",
    "blueorigin.com": (_, _) => "Blue Origin",
    "boeing.com": (_, _) => "Boeing",
    "astra.com": (_, _) => "Astra",
    "virginorbit.com": (_, _) => "Virgin Orbit",
    "virgingalactic.com": (_, _) => "Virgin Galactic",
    "mhi.com": (_, _) => "Mitsubishi Heavy Industries",
    "northropgrumman.com": (_, _) => "Northrop Grumman",
    "scaled.com": (_, _) => "Scaled Composites",
    "sncorp.com": (_, _) => "Sierra Nevada Corporation",
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
          var newText = specialHostFuncs[infoHost!.toLowerCase()]!(
            context,
            uri,
          );
          if (newText != null) {
            infoText = newText;
          }
        }
      }

      if (infoText != null) {
        bottomLeftText = infoText;
      }
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
