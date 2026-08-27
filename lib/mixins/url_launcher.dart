import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:rockit/l10n/app_localizations.dart';

mixin UrlLauncher {
  Future<void> openCustomTab(BuildContext context, String url) async {
    await launchUrl(
      Uri.parse(url),
      customTabsOptions: CustomTabsOptions(
        colorSchemes: CustomTabsColorSchemes.defaults(
          toolbarColor: Theme.of(context).primaryColor,
        ),
        shareState: CustomTabsShareState.on,
        urlBarHidingEnabled: true,
        showTitle: true,
        animations: CustomTabsSystemAnimations.slideIn(),
        browser: const CustomTabsBrowserConfiguration(
          fallbackCustomTabs: <String>[
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
      ),
    );
  }

  Future<void> launchURL(BuildContext context, String url) async {
    try {
      await launchUrl(Uri.parse(url));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${AppLocalizations.of(context)!.failedURLLaunch} ($url)",
          ),
        ),
      );
    }
  }
}
