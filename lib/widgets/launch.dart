import 'package:flutter/material.dart';
import 'package:rockit/l10n/app_localizations.dart';
import 'package:rockit/apis/launch_library/launch_response.dart';
import 'package:rockit/widgets/addons/launch_event.dart';

class LaunchWidget extends StatelessWidget {
  const LaunchWidget(this.launch, {super.key, this.heroPrefix = ""});

  final Launch launch;
  final String heroPrefix;

  @override
  Widget build(BuildContext context) {
    return LaunchEventWidget(
      title: launch.name ?? AppLocalizations.of(context)!.unknownLaunch,
      // Null rather than "Unknown": a launch embedded in an event is
      // `response_mode: list`, which carries no provider at all, and no
      // request can change that — the schema hardcodes LaunchBasic there.
      // Saying nothing is honest; saying "Unknown" reads as a fact about the
      // launch.
      subtitle: launch.providerName,
      heroId: "${launch.id}",
      heroTag: "${heroPrefix}launch-image",
      image: launch.image,
      status: launch.status,
      date: launch.net ?? launch.windowStart,
      precision: launch.netPrecision,
    );
  }
}
