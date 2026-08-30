import 'package:flutter/cupertino.dart';
import 'package:rockit/l10n/app_localizations.dart';

mixin SourceAttribution {
  /// The two hosts whose name depends on the link itself rather than only on
  /// the domain: a post reads as "@someone on Twitter", anything else there
  /// does not.
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
  };

  /// Everything whose name is just the domain's name.
  static const hostNames = <String, String>{
    "facebook.com": "Facebook",

    "youtube.com": "YouTube",
    "youtu.be": "YouTube",

    // News sites
    "spacenews.com": "SpaceNews",
    "spaceflightnow.com": "Spaceflight Now",
    "nasaspaceflight.com": "NASASpaceFlight",
    "spaceref.com": "SpaceRef",

    // Other
    "fcc.report": "FCC Report",

    // Forums. Ahead of nasaspaceflight.com below, though the lookup would find
    // it either way: the longest match wins.
    "forum.nasaspaceflight.com": "NASASpaceFlight Forum",

    // Sites from https://en.wikipedia.org/wiki/List_of_government_space_agencies#Budgets
    "nasa.gov": "NASA",
    "cnsa.gov.cn": "CNSA",
    "esa.int": "ESA",
    "dlr.de": "DLR",
    "cnes.fr": "CNES",
    "roscosmos.ru": "Roscosmos",
    "isro.gov.in": "ISRO",
    "asi.it": "ASI",
    "jaxa.jp": "JAXA",
    "kari.re.kr": "KARI",

    // Private space companies, from https://en.wikipedia.org/wiki/List_of_private_spaceflight_companies
    "spacex.com": "SpaceX",
    "rocketlabusa.com": "Rocket Lab",
    "blueorigin.com": "Blue Origin",
    "boeing.com": "Boeing",
    "astra.com": "Astra",
    "virginorbit.com": "Virgin Orbit",
    "virgingalactic.com": "Virgin Galactic",
    "mhi.com": "Mitsubishi Heavy Industries",
    "northropgrumman.com": "Northrop Grumman",
    "scaled.com": "Scaled Composites",
    "sncorp.com": "Sierra Nevada Corporation",

    // The rest of this list comes from surveying what actually appears in
    // `updates[].info_url` and `info_urls[]` across 436 launches: 193 distinct
    // hosts, of which these are the ones that are a company or an agency
    // talking about its own launch. News outlets are deliberately left out —
    // their own domain reads perfectly well as a source, and there is no end
    // to them.
    //
    // Launch providers and operators
    "rocketlabcorp.com": "Rocket Lab",
    "arianespace.com": "Arianespace",
    "ulalaunch.com": "United Launch Alliance",
    "isaraerospace.com": "Isar Aerospace",
    "fireflyspace.com": "Firefly Aerospace",
    "relativityspace.com": "Relativity Space",
    "rfa.space": "Rocket Factory Augsburg",
    "avio.com": "Avio",
    "orbex.space": "Orbex",
    "impulsespace.com": "Impulse Space",
    "vastspace.com": "Vast",
    "varda.com": "Varda",
    "trueanomaly.space": "True Anomaly",
    "k2space.com": "K2 Space",
    "sierraspace.com": "Sierra Space",
    "intuitivemachines.com": "Intuitive Machines",
    "astrobotic.com": "Astrobotic",
    "astrolab.space": "Astrolab",
    "astroscale.com": "Astroscale",
    "lockheedmartin.com": "Lockheed Martin",
    "aboutamazon.com": "Amazon",

    // Satellite operators and manufacturers
    "astranis.com": "Astranis",
    "axelspace.com": "Axelspace",
    "blacksky.com": "BlackSky",
    "i-qps.net": "iQPS",
    "open-cosmos.com": "Open Cosmos",
    "synspective.com": "Synspective",
    "telesat.com": "Telesat",
    "ses.com": "SES",
    "planet.com": "Planet",
    "globalstar.com": "Globalstar",
    "echostar.com": "EchoStar",
    "ohb-italia.it": "OHB Italia",
    "aegisaero.com": "Aegis Aerospace",

    // Spaceports
    "saxavord.com": "SaxaVord Spaceport",
    "andoyaspace.no": "Andøya Space",

    // More agencies and regulators
    "eumetsat.int": "EUMETSAT",
    "kasa.go.kr": "KASA",
    "inspace.gov.in": "IN-SPACe",
    "shar.gov.in": "ISRO",
    "mext.go.jp": "MEXT",
    "spaceforce.mil": "U.S. Space Force",
    "nro.gov": "NRO",
    "nrl.navy.mil": "U.S. Naval Research Laboratory",
    "faa.gov": "FAA",
    "fcc.gov": "FCC",

    // Where a subdomain says something the domain does not. The lookup takes
    // the longest match, so these win over their parent.
    //
    // The weather squadron is the clearest case: it is the single most linked
    // host in the whole survey after the launch providers themselves, and
    // "U.S. Space Force" tells you nothing about a launch weather forecast.
    "45thweathersquadron.nebula.spaceforce.mil": "45th Weather Squadron",
    "ssc.spaceforce.mil": "Space Systems Command",
    "fly.faa.gov": "FAA Advisory",
    "notams.aim.faa.gov": "FAA NOTAM",
    "apps.fcc.gov": "FCC Filing",
    "licensing.fcc.gov": "FCC Filing",
    "navcen.uscg.gov": "USCG Navigation Center",
    "centrespatialguyanais.cnes.fr": "Guiana Space Centre",
    "space.oscar.wmo.int": "WMO OSCAR",
    "iaru.amsat-uk.org": "IARU Satellite Coordination",

    // Official sources that are not space agencies but publish about launches:
    // filings, licences, notices to airmen and mariners, parliamentary
    // answers. Worth naming for the same reason an agency is — it says who is
    // speaking — even though nobody would call them space organisations.
    "sam.gov": "SAM.gov",
    "gao.gov": "GAO",
    "uscg.gov": "U.S. Coast Guard",
    "pib.gov.in": "Press Information Bureau (India)",
    "sansad.in": "Parliament of India",
    "mbie.govt.nz": "MBIE (New Zealand)",
    "mil.ru": "Russian Ministry of Defence",
    "avinor.no": "Avinor",

    // Smaller firms and the bodies that coordinate them, from the same survey
    "etaspace.com": "Eta Space",
    "portalsystems.space": "Portal Space Systems",
    "libre.space": "Libre Space Foundation",
    "amsat-uk.org": "AMSAT-UK",
    "aerospace.org": "The Aerospace Corporation",
    "celestrak.org": "CelesTrak",
    "eohandbook.com": "CEOS EO Handbook",
    "cgms-info.org": "CGMS",
    "nsmc.org.cn": "NSMC",
    "itu.int": "ITU",

    // Precise rather than by domain: amazonaws.com is not NASA, but this
    // bucket is.
    "nasa-public-data.s3.amazonaws.com": "NASA",
    "wmo.int": "WMO",
    "cao.go.jp": "Cabinet Office (Japan)",
    "forum.novosti-kosmonavtiki.ru": "Novosti Kosmonavtiki Forum",

    // Where announcements are posted
    "t.me": "Telegram",
    "weibo.com": "Weibo",
    "weibo.cn": "Weibo",
    "linkedin.com": "LinkedIn",
    "reddit.com": "Reddit",
    "bilibili.com": "Bilibili",
    "weixin.qq.com": "WeChat",
  };

  String? sourceAttributionText(BuildContext context, String? infoURL) {
    var infoHost = urlHost(infoURL);

    String? bottomLeftText;
    if (infoURL != null) {
      // For some hosts, we can have special text instead of the host name

      var infoText = infoHost;
      final uri = Uri.tryParse(infoURL);
      if (infoHost != null && uri != null) {
        infoText = attributionFor(context, infoHost, uri) ?? infoText;
      }

      if (infoText != null) {
        bottomLeftText = infoText;
      }
    }

    return bottomLeftText;
  }

  /// The friendly name for [host], or null to fall back to the host itself.
  ///
  /// Matches on domain rather than exact host, walking up a label at a time:
  /// `investors.rocketlabcorp.com` finds `rocketlabcorp.com` without needing
  /// its own entry. The API links to press rooms, investor pages and blogs on
  /// subdomains constantly, and listing each one is a losing game.
  ///
  /// Longest match wins, so `forum.nasaspaceflight.com` still reads as the
  /// forum rather than the site. A parent that returns null — `x.com` for a
  /// link that is not a post — keeps walking rather than stopping there.
  String? attributionFor(BuildContext context, String host, Uri uri) {
    return _walk(host, (candidate) {
      final special = specialHostFuncs[candidate];
      if (special != null) {
        final text = special(context, uri);
        if (text != null) {
          return text;
        }
      }

      return hostNames[candidate];
    });
  }

  /// The same lookup for the entries that do not depend on the link, which is
  /// all but two of them.
  static String? nameForHost(String host) => _walk(host, (c) => hostNames[c]);

  static String? _walk(String host, String? Function(String) lookup) {
    var candidate = host.toLowerCase();

    while (true) {
      final found = lookup(candidate);
      if (found != null) {
        return found;
      }

      final dot = candidate.indexOf('.');
      if (dot < 0) {
        return null;
      }

      candidate = candidate.substring(dot + 1);
    }
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
