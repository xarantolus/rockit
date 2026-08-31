import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rockit/l10n/app_localizations.dart';
import 'package:home_widget/home_widget.dart';
import 'package:rockit/apis/cache_janitor.dart';
import 'package:rockit/background/home_screen_widget.dart';
import 'package:rockit/background/handler.dart';
import 'package:rockit/notifications/create.dart';
import 'package:rockit/pages/home_page.dart';
import 'package:workmanager/workmanager.dart';

void main() async {
  // Paint.enableDithering = true;

  final oldDebugPrint = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    oldDebugPrint(
      "xarantolus${kDebugMode ? '.debug' : ''}.rockit: ${message ?? "No message"}",
      wrapWidth: wrapWidth,
    );
  };

  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    // Android 15 (API 35) forces edge-to-edge on apps targeting it, and
    // targetSdk follows flutter.*, so we get it whether we ask or not. Opting
    // in explicitly makes API 24-34 lay out the same way, so there is one
    // layout to reason about instead of two.
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
  }

  // Room to scroll back a good way without decoding anything again, and a
  // ceiling that actually bites. A full-width launch photo is ~8-10 MB decoded
  // and a news thumbnail ~1.5 MB, so this holds roughly 25 cards or 170
  // thumbnails; going past it costs a re-decode from the file already on disk,
  // never a request. It was 1 GiB, which is not a cache size so much as the
  // absence of one — and it could not bind anyway while every image was kept
  // permanently live (see ImageWidget).
  PaintingBinding.instance.imageCache.maximumSizeBytes = 256 << 20;

  ValueNotifier<String> appPayloadNotifier = ValueNotifier("");

  // Initialize the notification handler to make sure the background handler is initialized
  final notifs = await NotificationHandler.create(appPayloadNotifier);
  BackgroundHandler.withNotifications(notifs);

  if (!kIsWeb) {
    // Initialize background tasks
    Workmanager().initialize(backgroundTaskCallback);

    // Keeps the listings warm between sessions, so a cold start has something
    // to paint immediately.
    unawaited(BackgroundHandler().scheduleCacheWarming());

    // Nothing waits on this: it only reads directory entries and deletes, and
    // a start should not be held up to tidy a cache.
    unawaited(CacheJanitor().sweep());

    // Not awaited: this ends in a channel round-trip and a cache read, and
    // holding the first frame for them buys nothing. A payload that arrives
    // after the home page is up still lands, because the page listens to the
    // notifier as well as reading it once.
    unawaited(_wireHomeWidget(appPayloadNotifier));
  }

  runApp(RockItApp(appPayloadNotifier));
}

/// Makes a tap on the home-screen widget open the thing it names.
///
/// Both paths are needed, and wiring only the first is the usual reason taps
/// "do nothing": [HomeWidget.initiallyLaunchedFromHomeWidget] answers once, for
/// a cold start, while the [HomeWidget.widgetClicked] stream carries taps that
/// arrive when the app is already running.
///
/// The payload is the same string a notification carries, so both end up in the
/// same notifier and the same handler in `home_page.dart`.
Future<void> _wireHomeWidget(ValueNotifier<String> payloads) async {
  void handle(Uri? uri) {
    final payload = uri?.queryParameters["payload"];
    if (payload != null && payload.isNotEmpty) {
      payloads.value = payload;
    }
  }

  try {
    HomeWidget.widgetClicked.listen(handle);
    handle(await HomeWidget.initiallyLaunchedFromHomeWidget());
  } catch (err) {
    debugPrint("Could not wire up the home screen widget: $err");
  }

  WidgetsBinding.instance.addObserver(_RefreshWidgetOnResume());

  unawaited(refreshHomeWidget());
}

/// Rewrites the home-screen widget whenever the app comes back to the front.
///
/// Its rows answer "when is this, here, now" — "Tomorrow, 02:00 AM" — so they
/// go wrong when the device's timezone, locale or 12/24-hour setting changes,
/// and the app is told about none of that while it is closed. Flying to
/// another timezone also aims the scheduled midnight refresh at the wrong
/// moment.
///
/// The hourly subscription job rewrites the rows and reschedules that refresh
/// regardless, so the widget is never wrong for longer than an hour on its
/// own. This covers the case anyone would actually catch: landing, unlocking
/// the phone, and looking at the widget.
class _RefreshWidgetOnResume with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(refreshHomeWidget());
    }
  }
}

class RockItApp extends StatelessWidget {
  const RockItApp(this.appPayload, {super.key});

  final ValueNotifier<String> appPayload;

  static const _themeColor = Color.fromRGBO(0x3A, 0x88, 0xFF, 1.0);
  static const _secondaryColor = Color.fromARGB(255, 70, 135, 255);

  static const _themeColorDark = Color.fromRGBO(0x2B, 0x66, 0xBF, 1.0);
  static const _secondaryColorDark = Color.fromARGB(255, 58, 111, 207);

  /// Push a detail page up from the bottom, as one piece.
  ///
  /// Flutter's current Android default slides in from the side (the
  /// predictive-back transition), which reads as sideways motion in a list you
  /// scroll vertically and fights the horizontal pager between launches.
  ///
  /// Fade-upwards and not *open*-upwards: the latter reveals the page through a
  /// clip rectangle sweeping bottom to top, so the hero at the top of the page
  /// is uncovered last and its overlaid text snaps in at the very end. This one
  /// is a plain slide plus fade, so the image and the text on it arrive
  /// together.
  static const _pageTransitions = PageTransitionsTheme(
    builders: {TargetPlatform.android: FadeUpwardsPageTransitionsBuilder()},
  );

  static const appName = 'Rock It!';

  /// Exposed so the theming can be asserted directly; building the whole app
  /// in a test would pull in the network and platform plugins.
  @visibleForTesting
  static ThemeData get lightTheme =>
      ThemeData.from(
        colorScheme: const ColorScheme.light().copyWith(
          brightness: Brightness.light,
          primary: _themeColor,
          secondary: _secondaryColor,
          surface: Colors.grey[200],
          surfaceContainerHighest: Colors.transparent,
          surfaceContainerLowest: Colors.transparent,
          onSecondary: Colors.white,
        ),
        textTheme: Typography.blackHelsinki.copyWith(
          bodyMedium: const TextStyle(
            // color: Colors.grey[800],
            fontSize: 14,
          ),
        ),
      ).copyWith(
        pageTransitionsTheme: _pageTransitions,
        appBarTheme: const AppBarTheme(
          backgroundColor: _themeColor,
          centerTitle: true,
          actionsIconTheme: IconThemeData(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          color: Colors.grey[100], // Slightly brighter background
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: BorderSide(color: Colors.grey[300]!), // Border color
          ),
        ),
      );

  @visibleForTesting
  static ThemeData get darkTheme =>
      ThemeData.from(
        colorScheme: const ColorScheme.dark().copyWith(
          brightness: Brightness.dark,
          primary: _themeColorDark,
          secondary: _secondaryColorDark,
          surface: Colors.grey[900],
          surfaceContainerHighest: Colors.transparent,
          surfaceContainerLowest: Colors.transparent,
          onSecondary: Colors.white,
        ),
        textTheme: Typography.whiteHelsinki.copyWith(
          bodyMedium: TextStyle(color: Colors.grey[200], fontSize: 14),
        ),
      ).copyWith(
        pageTransitionsTheme: _pageTransitions,
        cardTheme: CardThemeData(
          color: Colors.grey[850],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: BorderSide(color: Colors.grey[700]!), // Border color
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: lightTheme,
      darkTheme: darkTheme,
      home: RockItHomePage(appPayload, title: appName),
    );
  }
}
