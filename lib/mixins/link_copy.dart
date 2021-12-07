import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

mixin LinkCopier {
  void copyLink(BuildContext context, String? url) async {
    if (url != null) {
      ScaffoldMessenger.of(context).clearSnackBars();

      await Clipboard.setData(ClipboardData(text: url));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.copiedToClipboard),
      ));
    }
  }
}
