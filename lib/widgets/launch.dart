import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rockit/apis/launch_library/launch_response.dart';
import 'package:rockit/widgets/addons/launch_event.dart';

class LaunchWidget extends StatefulWidget {
  const LaunchWidget(this.launch, {Key? key}) : super(key: key);

  final Launch launch;
  @override
  _LaunchWidgetState createState() => _LaunchWidgetState();
}

class _LaunchWidgetState extends State<LaunchWidget> {
  @override
  Widget build(BuildContext context) {
    return LaunchEventWidget(
      title: widget.launch.name ?? AppLocalizations.of(context)!.unknownLaunch,
      subtitle: widget.launch.launchServiceProvider?.name ?? AppLocalizations.of(context)!.unknown,
      heroId: "${widget.launch.id}",
      heroTag: "launch-image",
      imageURL: widget.launch.image,
      netDate: DateTime.tryParse(widget.launch.net ?? widget.launch.windowStart ?? ""),
    );
  }
}
