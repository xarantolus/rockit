import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rockit/apis/launch_library/upcoming_response.dart';
import 'package:intl/intl.dart';
import 'package:rockit/widgets/launch_image.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LaunchWidget extends StatefulWidget {
  const LaunchWidget(this.launch, {Key? key}) : super(key: key);

  final Launch launch;

  static double calculateHeight(BuildContext context) {
    return max(MediaQuery.of(context).size.height / 3, 250);
  }

  @override
  _LaunchWidgetState createState() => _LaunchWidgetState();
}

class _LaunchWidgetState extends State<LaunchWidget> {
  String _netText(Launch launch) {
    try {
      var launchDate =
          DateTime.parse(launch.net ?? launch.windowStart ?? "").toLocal();

      final DateFormat formatter = DateFormat(
          AppLocalizations.of(context)!.dateFormat,
          AppLocalizations.of(context)!.localeName);
      return formatter.format(launchDate);
    } catch (_) {}
    return AppLocalizations.of(context)!.netUnknown;
  }

  GridTileBar _infoBar(Launch launch) {
    return GridTileBar(
      backgroundColor: Colors.grey[800]!.withOpacity(0.75),
      title: Text(
        launch.name ?? AppLocalizations.of(context)!.unknownLaunch,
        style: const TextStyle(
          overflow: TextOverflow.ellipsis,
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      trailing: Text(
        _netText(launch),
        style: const TextStyle(
          color: Colors.white70,
        ),
      ),
      subtitle: Text(
        launch.launchServiceProvider?.name ??
            AppLocalizations.of(context)!.unknown,
        style: const TextStyle(
          overflow: TextOverflow.ellipsis,
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: LaunchWidget.calculateHeight(context),
      child: Card(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 5,
        margin: const EdgeInsets.fromLTRB(10, 5, 10, 5),
        child: GridTile(
          child: LaunchImageWidget(widget.launch),
          footer: _infoBar(widget.launch),
        ),
      ),
    );
  }
}
