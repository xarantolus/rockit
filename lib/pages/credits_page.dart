import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class CreditPage extends StatelessWidget {
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

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.sources),
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
                await _launchURL("https://thespacedevs.com/");
              },
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
                await _launchURL("https://github.com/xarantolus/rockit");
              },
              label: const Text("Open project page"),
            ),
          ],
        ),
      ),
    );
  }
}