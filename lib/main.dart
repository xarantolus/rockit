import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:rockit/background/handler.dart';
import 'package:rockit/notifications/create.dart';
import 'package:rockit/pages/home_page.dart';
import 'package:workmanager/workmanager.dart';

void main() async {
  Paint.enableDithering = true;

  final oldDebugPrint = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    oldDebugPrint("xarantolus${kDebugMode ? '.debug' : ''}.rockit: ${message ?? "No message"}", wrapWidth: wrapWidth);
  };

  WidgetsFlutterBinding.ensureInitialized();

  // Allow significantly more render image cache. This makes images reload less
  // It's a bit annoying to reduce the problem like this instead of being able to solve it in a good way.
  // See https://github.com/flutter/flutter/issues/68700 for more details
  PaintingBinding.instance.imageCache.maximumSizeBytes = 1000 << 20; // 1GiB

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
  static const _secondaryColor = Color.fromARGB(255, 70, 135, 255);

  static const _themeColorDark = Color.fromRGBO(0x2B, 0x66, 0xBF, 1.0);
  static const _secondaryColorDark = Color.fromARGB(255, 58, 111, 207);

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
          onSecondary: Colors.white,
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
          onSecondary: Colors.white,
        ),
        textTheme: Typography.whiteHelsinki.copyWith(
          bodyText2: TextStyle(
            color: Colors.grey[200],
            fontSize: 14,
          ),
        ),
      ),
      home: RockItHomePage(appPayload, title: appName),
    );
  }
}
