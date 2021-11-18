import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rockit/apis/launch_library/upcoming_response.dart';
import 'package:rockit/mixins/attribution.dart';
import 'package:rockit/mixins/date_format.dart';
import 'package:rockit/widgets/ripple_link.dart';

mixin UpdateRenderer on DateFormatter, SourceAttribution {
  List<Widget> renderUpdateList(
    BuildContext context,
    TextStyle titleStyle,
    List<Update> updates,
  ) {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
        child: Text(
          AppLocalizations.of(context)!.updates,
          style: titleStyle,
        ),
      ),
      ...updates.map((e) => _update(context, e)),
    ];
  }

  Widget _update(BuildContext context, Update u) {
    final date = formatDateTimeFriendly(context,
        (DateTime.tryParse(u.createdOn ?? "") ?? DateTime.now()).toLocal());

    return RippleLinkWidget(
      (u.comment ?? "").isNotEmpty
          ? u.comment!
          : AppLocalizations.of(context)!.unknown,
      bottomRight: date,
      bottomLeft: sourceAttributionText(context, u.infoUrl),
      url: u.infoUrl,
    );
  }
}
