import 'package:flutter/material.dart';
import 'package:rockit/pages/upcoming_launches_listing.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
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
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        bottomNavigationBar: TabBar(
          labelColor: Theme.of(context).textTheme.bodyText2!.color,
          automaticIndicatorColorAdjustment: true,
          tabs: [
            Tab(
              icon: const Icon(Icons.home),
              child: Text(AppLocalizations.of(context)!.launches),
            ),
            Tab(
              icon: const Icon(Icons.article),
              child: Text(AppLocalizations.of(context)!.news),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            UpcomingLaunchesPage(),
            Icon(Icons.article),
          ],
        ),
      ),
    );
  }
}
