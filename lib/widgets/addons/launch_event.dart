import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rockit/mixins/date_format.dart';
import 'package:rockit/widgets/image.dart';

class LaunchEventWidget extends StatefulWidget {
  const LaunchEventWidget({
    required this.title,
    required this.subtitle,
    this.imageURL,
    this.heroTag,
    this.heroId,
    this.netDate,
    Key? key,
  }) : super(key: key);

  final String? imageURL;

  final String? heroTag;
  final String? heroId;

  final String title;
  final String subtitle;

  final DateTime? netDate;

  static double _getHeight(BuildContext context) {
    try {
      return MediaQuery.of(context).size.height;
    } catch (_) {}

    final w = WidgetsBinding.instance!.window;
    return w.physicalSize.height / w.devicePixelRatio;
  }

  static double calculateHeight(BuildContext context) {
    return max(_getHeight(context) / 3, 250);
  }

  @override
  _LaunchEventWidgetState createState() => _LaunchEventWidgetState();
}

class _LaunchEventWidgetState extends State<LaunchEventWidget> with DateFormatter {
  String _netText() {
    if (widget.netDate == null) {
      return AppLocalizations.of(context)!.netUnknown;
    }
    return formatDateFriendly(context, widget.netDate!.toLocal());
  }

  GridTileBar _infoBar() {
    return GridTileBar(
      backgroundColor: Colors.grey[800]!.withOpacity(0.75),
      title: Text(
        widget.title,
        style: const TextStyle(
          overflow: TextOverflow.ellipsis,
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      trailing: Text(
        _netText(),
        style: const TextStyle(
          color: Colors.white70,
        ),
      ),
      subtitle: Text(
        widget.subtitle,
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
      height: LaunchEventWidget.calculateHeight(context),
      child: Card(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 5,
        margin: const EdgeInsets.fromLTRB(10, 5, 10, 5),
        child: GridTile(
          child: ImageWidget(
            widget.imageURL,
            heroTag: widget.heroTag,
            id: widget.heroId,
          ),
          footer: _infoBar(),
        ),
      ),
    );
  }
}
