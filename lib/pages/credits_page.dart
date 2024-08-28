import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rockit/mixins/link_copy.dart';
import 'package:rockit/mixins/url_launcher.dart';
import 'package:rockit/widgets/addons/app_bar.dart';

// This page is not localized because I wanted to keep the original description from the space devs
class CreditPage extends StatelessWidget with LinkCopier, UrlLauncher {
  const CreditPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const titleStyle = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
    );
    const descStyle = TextStyle(
      fontSize: 18,
    );

    const spaceDevsLink = "https://thespacedevs.com/";
    const projectLink = "https://github.com/xarantolus/rockit";
    const twitterBotLink = "https://twitter.com/wenhopbot";


 return Scaffold(

      appBar: CustomAppBar.create(
        context,
        title: AppLocalizations.of(context)!.sources,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              AppLocalizations.of(context)!.sourceSpaceDevs,
              style: titleStyle,
            ),
            Text(
              AppLocalizations.of(context)!.sourceSpaceDevsDescription,
              style: descStyle,
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.open_in_browser),
              onPressed: () async {
                await launchURL(context, spaceDevsLink);
              },
              onLongPress: () => copyLink(context, spaceDevsLink),
              label: Text(AppLocalizations.of(context)!.openWebsite),
            ),
            const Divider(),
            Text(
              AppLocalizations.of(context)!.development,
              style: titleStyle,
            ),
            Text(
              AppLocalizations.of(context)!.developmentDescription,
              style: descStyle,
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.open_in_browser),
              onPressed: () async {
                await launchURL(context, projectLink);
              },
              onLongPress: () => copyLink(context, projectLink),
              label: Text(AppLocalizations.of(context)!.openWebsite),
            ),
            const Divider(),
            Text(
              AppLocalizations.of(context)!.twitterBot,
              style: titleStyle,
            ),
            Text(
              AppLocalizations.of(context)!.twitterBotDescription,
              style: descStyle,
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.open_in_browser),
              onPressed: () async {
                await launchURL(context, twitterBotLink);
              },
              onLongPress: () => copyLink(context, twitterBotLink),
              label: Text(AppLocalizations.of(context)!.openWebsite),
            ),
          ],
        ),
      ),
    );
  }
}
