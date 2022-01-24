import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rockit/apis/launch_library/api.dart';
import 'package:rockit/background/handler.dart';
import 'package:rockit/mixins/url_launcher.dart';
import 'package:rockit/notifications/create.dart';
import 'package:rockit/pages/article_listing.dart';
import 'package:rockit/pages/credits_page.dart';
import 'package:rockit/pages/event_details.dart';
import 'package:rockit/pages/launch_details.dart';
import 'package:rockit/pages/upcoming_events_listing.dart';
import 'package:rockit/pages/upcoming_launches_listing.dart';
import 'package:rockit/widgets/addons/app_bar.dart';
import 'package:rockit/widgets/addons/overline_tab_indicator.dart';
import 'package:workmanager/workmanager.dart';

void main() async {
  Paint.enableDithering = true;

  final oldDebugPrint = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    oldDebugPrint("xarantolus.rockit: " + (message ?? "No message"), wrapWidth: wrapWidth);
  };

  WidgetsFlutterBinding.ensureInitialized();

  // Allow a bit more render image cache, this makes images reload less
  // It's a bit annoying to reduce the problem like this instead of being able to solve it in a good way.
  // See https://github.com/flutter/flutter/issues/68700 for more details
  PaintingBinding.instance!.imageCache!.maximumSizeBytes = 500 << 20; // 500 MiB

  ValueNotifier<String> appPayloadNotifier = ValueNotifier("");

  // Initialize the notification handler to make sure the background handler is initialized
  final notifs = await NotificationHandler.create(appPayloadNotifier);
  BackgroundHandler.withNotifications(notifs);

  if (!kIsWeb) {
    // Initialize background tasks
    Workmanager().initialize(
      backgroundTaskCallback,
      isInDebugMode: kDebugMode,
    );
  }

  runApp(RockItApp(appPayloadNotifier));
}

class RockItApp extends StatelessWidget {
  const RockItApp(this.appPayload, {Key? key}) : super(key: key);

  final ValueNotifier<String> appPayload;

  static const _themeColor = Color.fromRGBO(0x3A, 0x88, 0xFF, 1.0);
  static const _secondaryColor = Color.fromRGBO(0x70, 0xA2, 0xFF, 1.0);

  static const _themeColorDark = Color.fromRGBO(0x2B, 0x66, 0xBF, 1.0);
  static const _secondaryColorDark = Color.fromRGBO(0x54, 0x79, 0xBF, 1.0);

  static const appName = 'Rock It!';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData.from(
        colorScheme: const ColorScheme.light().copyWith(
          brightness: Brightness.light,
          primary: _themeColor,
          secondary: _secondaryColor,
          surface: Colors.grey[200],
        ),
        textTheme: Typography.blackHelsinki.copyWith(
          bodyText2: TextStyle(
            color: Colors.grey[800],
            fontSize: 14,
          ),
        ),
      ),
      darkTheme: ThemeData.from(
        colorScheme: const ColorScheme.dark().copyWith(
          brightness: Brightness.dark,
          primary: _themeColorDark,
          secondary: _secondaryColorDark,
          surface: Colors.grey[900],
        ),
        textTheme: Typography.whiteHelsinki.copyWith(
          bodyText2: TextStyle(
            color: Colors.grey[200],
            fontSize: 14,
          ),
        ),
      ),
      home: MyHomePage(appPayload, title: appName),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage(this.appPayload, {Key? key, required this.title}) : super(key: key);

  final ValueNotifier<String> appPayload;

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with UrlLauncher {
  @override
  void initState() {
    super.initState();

    unawaited(pushPayloadPage());
    widget.appPayload.addListener(pushPayloadPage);
  }

  // pushPayloadPage is called when the app is opened via a notification.
  // It checks if we have a payload and then opens the appropriate details page
  Future<void> pushPayloadPage() async {
    try {
      String payload = widget.appPayload.value;
      if (payload.isEmpty) {
        return;
      }

      final splitPayload = payload.split("::");
      if (splitPayload.length < 2) {
        return;
      }

      final action = splitPayload[0];
      final data = splitPayload.sublist(1).join("::");

      switch (action) {
        case BackgroundHandler.actionLaunchDetails:
          // If we received a notification about a launch, we 99% sure have that launch cached
          final launch = await LaunchLibraryAPI().launch(data, true);

          await Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => LaunchDetailsPage(launch.data),
          ));
          break;
        case BackgroundHandler.actionEventDetails:
          final event = await LaunchLibraryAPI().event(data, true);

          await Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => EventDetailsPage(event.data),
          ));
          break;
      }
    } catch (e) {
      debugPrint("Error while pushing initial page: $e");
    }
  }

  Future<void> _openAppDownloadLink() async {
    var ok = await showDialog<bool?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.downloadApp),
        content: Text(AppLocalizations.of(context)!.downloadAppDescription),
        actions: [
          TextButton(
            child: Text(AppLocalizations.of(context)!.cancel),
            onPressed: () {
              Navigator.pop(context, false);
            },
          ),
          TextButton(
            child: Text(AppLocalizations.of(context)!.openWebsite),
            onPressed: () {
              Navigator.pop(context, true);
            },
          ),
        ],
      ),
    );
    if (ok != true) {
      return;
    }

    launchURL(context, "https://github.com/xarantolus/rockit/releases/latest");
  }

  @override
  Widget build(BuildContext context) {
    final lightTheme = Theme.of(context).brightness == Brightness.light;
    final appIcon = ImageIcon(
      lightTheme
          ? const AssetImage("assets/rocket-black-small.png")
          : const AssetImage("assets/rocket-white-small.png"),
    );

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: CustomAppBar.create(
          context,
          title: widget.title,
          titleStyle: const TextStyle(fontWeight: FontWeight.w900),
          icon: appIcon,
          actions: [
            if (kIsWeb)
              IconButton(
                icon: const Icon(Icons.download),
                tooltip: AppLocalizations.of(context)!.downloadApp,
                onPressed: () async {
                  await _openAppDownloadLink();
                },
              ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: AppLocalizations.of(context)!.sources,
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CreditPage(),
                  ),
                );
              },
            ),
          ],
        ),
        bottomNavigationBar: TabBar(
          labelColor: Theme.of(context).textTheme.bodyText2!.color,
          automaticIndicatorColorAdjustment: true,
          indicator: OverlineTabIndicator(
            borderSide: BorderSide(
              color: Theme.of(context).textTheme.bodyText2!.color!,
              width: 3,
            ),
          ),
          tabs: [
            Tab(
              icon: appIcon,
              text: AppLocalizations.of(context)!.launches,
            ),
            Tab(
              icon: const Icon(Icons.event),
              text: AppLocalizations.of(context)!.events,
            ),
            Tab(
              icon: const Icon(Icons.article_outlined),
              text: AppLocalizations.of(context)!.news,
            ),
          ],
        ),
        body: TabBarView(
          children: [
            UpcomingLaunchesPage(),
            UpcomingEventsPage(),
            ArticleListingPage(),
          ],
        ),
      ),
    );
  }
}
