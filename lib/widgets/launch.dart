import 'package:flutter/material.dart';
import 'package:rockit/l10n/app_localizations.dart';
import 'package:rockit/apis/launch_library/launch_response.dart';
import 'package:rockit/widgets/addons/launch_event.dart';

class LaunchWidget extends StatefulWidget {
  const LaunchWidget(this.launch, {super.key, this.heroPrefix = ""});

  final Launch launch;
  final String heroPrefix;

  @override
  State<LaunchWidget> createState() => _LaunchWidgetState();
}

class _LaunchWidgetState extends State<LaunchWidget> {
  @override
  Widget build(BuildContext context) {
    return LaunchEventWidget(
      title: widget.launch.name ?? AppLocalizations.of(context)!.unknownLaunch,
      subtitle:
          widget.launch.launchServiceProvider?.name ??
          AppLocalizations.of(context)!.unknown,
      heroId: "${widget.launch.id}",
      heroTag: "${widget.heroPrefix}launch-image",
      image: widget.launch.image,
      status: widget.launch.status,
      date: widget.launch.net ?? widget.launch.windowStart,
      precision: widget.launch.netPrecision,
    );
  }
}
