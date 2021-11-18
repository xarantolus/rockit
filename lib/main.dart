import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rockit/background/handler.dart';
import 'package:rockit/pages/article_listing.dart';
import 'package:rockit/pages/credits_page.dart';
import 'package:rockit/pages/upcoming_events_listing.dart';
import 'package:rockit/pages/upcoming_launches_listing.dart';
import 'package:rockit/widgets/addons/overline_tab_indicator.dart';
import 'package:workmanager/workmanager.dart';

void main() async {
  // Disable debug print messages when not in debug mode
  if (!kDebugMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
  Paint.enableDithering = true;

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize background tasks
  Workmanager().initialize(
    backgroundTaskCallback,
    isInDebugMode: kDebugMode,
  );

  // Allow a bit more render image cache, this makes images reload less
  // It's a bit annoying to reduce the problem like this instead of being able to solve it in a good way.
  // See https://github.com/flutter/flutter/issues/68700 for more details
  PaintingBinding.instance!.imageCache!.maximumSizeBytes = 500 << 20; // 500 MiB

  runApp(const RockItApp());
}

class RockItApp extends StatelessWidget {
  const RockItApp({Key? key}) : super(key: key);

  static const _themeColor = Color.fromRGBO(0x3A, 0x88, 0xFF, 1.0);
  static const _secondaryColor = Color.fromRGBO(0x70, 0xA2, 0xFF, 1.0);

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
          primary: _themeColor,
          secondary: _secondaryColor,
          surface: Colors.grey[900],
        ),
        textTheme: Typography.whiteHelsinki.copyWith(
          bodyText2: TextStyle(
            color: Colors.grey[200],
            fontSize: 14,
          ),
        ),
      ),
      home: const MyHomePage(title: appName),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
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
              icon: ImageIcon(
                Theme.of(context).brightness == Brightness.light
                    ? const AssetImage("assets/rocket-black.png")
                    : const AssetImage("assets/rocket-white.png"),
              ),
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
