import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rockit/mixins/link_copy.dart';
import 'package:rockit/widgets/addons/app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class CreditPage extends StatelessWidget with LinkCopier {
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

    Future<void> _launchURL(String _url) async {
      try {
        await launch(_url);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "${AppLocalizations.of(context)!.failedURLLaunch} ($_url)"),
          ),
        );
      }
    }

    const spaceDevsLink = "https://thespacedevs.com/";
    const projectLink = "https://github.com/xarantolus/rockit";

    return Scaffold(
      appBar: CustomAppBar.create(
        context,
        title: AppLocalizations.of(context)!.sources,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            const Text('Data from The Space Devs', style: titleStyle),
            const Text(
              'The Space Devs is a group of space enthusiast developers working on a range of services, united in a common goal to improve public knowledge and accessibility of spaceflight information. They aim to bring space app developers together into a thriving community by providing helpful data and tools, accessible to everyone for free.',
              style: descStyle,
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.open_in_browser),
              onPressed: () async {
                await _launchURL(spaceDevsLink);
              },
              onLongPress: () => copyLink(context, spaceDevsLink),
              label: const Text("Open Website"),
            ),
            const Divider(),
            const Text("Development", style: titleStyle),
            const Text(
              "This app is developed on GitHub. If you want to see or contribute to the code, feel free to check it out!",
              style: descStyle,
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.open_in_browser),
              onPressed: () async {
                await _launchURL(projectLink);
              },
              onLongPress: () => copyLink(context, projectLink),
              label: const Text("Open project page"),
            ),
          ],
        ),
      ),
    );
  }
}
