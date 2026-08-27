import 'package:flutter/material.dart';
import 'package:rockit/l10n/app_localizations.dart';
import 'package:rockit/apis/launch_library/launch_response.dart';
import 'package:rockit/mixins/attribution.dart';
import 'package:rockit/mixins/date_format.dart';
import 'package:rockit/widgets/ripple_link.dart';

mixin UpdateRenderer on DateFormatter, SourceAttribution {
  /// Just the entries. The enclosing section already carries the heading, and
  /// a second one inside it was both redundant and indented differently to
  /// everything around it.
  List<Widget> renderUpdateList(BuildContext context, List<Update> updates) {
    return updates.map((e) => _update(context, e)).toList();
  }

  Widget _update(BuildContext context, Update u) {
    final date = formatDateTimeFriendlyText(
      context,
      (u.createdOn ?? DateTime.now()).toLocal(),
    );

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
