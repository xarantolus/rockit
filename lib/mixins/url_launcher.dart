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
          // Browsers that support custom tabs. Could/Should add more
          "org.bromite.bromite",
          'org.mozilla.firefox',
          'com.microsoft.emmx',
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
          content:
              Text("${AppLocalizations.of(context)!.failedURLLaunch} ($_url)"),
        ),
      );
    }
  }
}
