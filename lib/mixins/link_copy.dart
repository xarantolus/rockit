import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rockit/l10n/app_localizations.dart';

mixin LinkCopier {
  void copyLink(BuildContext context, String? url) async {
    if (url == null) {
      return;
    }

    // Both are looked up before the await: the widget can be gone by the time
    // the clipboard write completes, and the messenger outlives it anyway.
    final messenger = ScaffoldMessenger.of(context);
    final message = AppLocalizations.of(context)!.copiedToClipboard;

    messenger.clearSnackBars();

    await Clipboard.setData(ClipboardData(text: url));

    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}
