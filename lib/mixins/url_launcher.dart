import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

mixin UrlLauncher {
  Future<void> openCustomTab(BuildContext context, String url) async {
    await launch(
      url,
      customTabsOption: CustomTabsOption(
        toolbarColor: Theme.of(context).primaryColor,
        enableDefaultShare: true,
        enableUrlBarHiding: true,
        showPageTitle: true,
        animation: CustomTabsSystemAnimation.slideIn(),
        extraCustomTabs: const <String>[
          "com.android.chrome",
          "org.mozilla.firefox",
          "com.microsoft.emmx",
          "com.opera.browser",
          "com.brave.browser",
          "com.vivaldi.browser",
          "com.yandex.browser",
          "com.duckduckgo.mobile.android",
          "org.cromite.cromite",
        ],
      ),
    );
  }

  Future<void> launchURL(BuildContext context, String _url) async {
    try {
      await launch(_url);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${AppLocalizations.of(context)!.failedURLLaunch} ($_url)"),
        ),
      );
    }
  }
}
