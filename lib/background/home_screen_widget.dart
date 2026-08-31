/// What the home-screen widget shows, and when it needs saying again.
///
/// Pure: picking the entries and deciding when the text goes stale are both
/// testable without a widget, a channel or a device.
library;

import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rockit/apis/launch_library/api.dart';
import 'package:rockit/apis/launch_library/events_response.dart';
import 'package:rockit/apis/launch_library/launch_response.dart';
import 'package:rockit/background/handler.dart';
import 'package:rockit/l10n/app_localizations.dart';
import 'package:rockit/time/friendly_dates.dart';
import 'package:rockit/time/precision_time.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One row.
///
/// Only strings: the native side places text and nothing else. Dart owns the
/// date formatting, because the app already has rules for it — coarse
/// precision reads "NET October 2026" rather than inventing a day — and a
/// second implementation in Kotlin would drift from the first.
class WidgetEntry {
  const WidgetEntry({
    required this.title,
    required this.subtitle,
    required this.payload,
    required this.at,
  });

  /// The mission, not the API's `name`.
  ///
  /// That field reads "Falcon 9 Block 5 | Starlink Group 15-23", and in a
  /// column this narrow the rocket ate the width and the *mission* was what
  /// got ellipsized — which is the half you are looking for.
  final String title;

  /// The rocket and the time, which is what is left over once the mission has
  /// the line above to itself.
  final String subtitle;

  /// `launch-details::<id>` or `event-details::<id>`, the same string a
  /// notification carries, so tapping a row reuses the app's existing deep
  /// link rather than adding a second way in.
  final String payload;

  /// Kept for scheduling the next refresh; not shown.
  final DateTime at;

  /// What the provider reads. [at] is deliberately absent: it decides when to
  /// look again, and the native side neither needs it nor could use it.
  Map<String, String> toJson() => {
    "title": title,
    "subtitle": subtitle,
    "payload": payload,
  };
}

/// The most rows the widget will ever draw, and so how many are written.
///
/// All of them are written every time. Which of them are *shown* is the
/// provider's decision, taken from the widget's current height, so dragging
/// the widget taller fills the new space straight away instead of waiting for
/// the next refresh to notice — which is only possible because the strings are
/// already there. It is far more than a phone can show; the ceiling is for a
/// tablet, and the cost of the unused ones is a few dozen short strings.
///
/// The provider needs no matching constant: it draws whatever it was handed,
/// so this is the only place the ceiling is written down.
const homeWidgetRows = 25;

/// The next few things worth showing: every upcoming launch, and only the
/// events the user subscribed to.
///
/// Launch listings start a day in the past (`net__gte` yesterday), so the
/// filter to the future is doing real work rather than guarding a hypothetical.
List<WidgetEntry> nextEntries({
  required Iterable<Launch> launches,
  required Iterable<Event> events,
  required DateTime now,
  required String Function(DateTime at, DatePrecision? precision) format,
  int limit = homeWidgetRows,
}) {
  final entries = <WidgetEntry>[];

  void add(
    String? title,
    DateTime? at,
    DatePrecision? precision,
    String? tag, {
    String? rocket,
  }) {
    if (title == null || at == null || tag == null || !at.isAfter(now)) {
      return;
    }

    final when = format(at, precision);

    entries.add(
      WidgetEntry(
        title: title,
        subtitle: rocket == null ? when : "$rocket · $when",
        payload: tag,
        at: at,
      ),
    );
  }

  for (final launch in launches) {
    // The mission has a name of its own; falling back to the API's combined
    // `name` only matters for the handful of launches that carry no mission.
    add(
      launch.mission?.name ?? launch.name,
      launch.net,
      launch.netPrecision,
      launch.id == null
          ? null
          : "${BackgroundHandler.actionLaunchDetails}::${launch.id}",
      rocket: launch.mission?.name == null ? null : launch.rocketName,
    );
  }

  for (final event in events) {
    add(
      event.name,
      event.date,
      event.datePrecision,
      event.id == null
          ? null
          : "${BackgroundHandler.actionEventDetails}::${event.id}",
    );
  }

  entries.sort((a, b) => a.at.compareTo(b.at));

  return entries.take(limit).toList();
}

/// How long until what the widget says stops being true.
///
/// Two things age it, and the sooner one wins:
///
/// - **Midnight**, because every label is relative to today: "Tomorrow, 12:05"
///   means something else at 00:01.
/// - **The first entry passing**, because it then belongs off the list.
///
/// Null when there is nothing to wait for, which cannot happen while a date is
/// shown but does when the cache is empty.
Duration nextRefreshDelay(List<WidgetEntry> entries, DateTime now) {
  var soonest = untilNextLocalMidnight(now);

  for (final entry in entries) {
    final until = entry.at.difference(now);

    // A minute past, so the entry is unambiguously gone rather than exactly on
    // the boundary.
    final after = until + const Duration(minutes: 1);

    if (!after.isNegative && after < soonest) {
      soonest = after;
    }
  }

  return soonest;
}

/// Serialises overlapping refreshes.
///
/// Startup fires three of these in quick succession — `main`, then each
/// listing as its first page lands — and each one reads and parses the whole
/// cached launches page. Joining them means the burst costs one pass.
Future<void>? _inFlight;

/// Writes the widget's rows and asks Android to redraw it.
///
/// Cache only: the widget never causes a request. Everything it shows was
/// already fetched by the listings or the background jobs.
Future<void> refreshHomeWidget() {
  return _inFlight ??= _refreshHomeWidget().whenComplete(() {
    _inFlight = null;
  });
}

Future<void> _refreshHomeWidget() async {
  try {
    final api = LaunchLibraryAPI();
    final handler = BackgroundHandler();
    final locale = _locale();

    // Independent, so they go together rather than one after another. All of
    // it is cache and preferences reads — no request is possible here.
    //
    // initializeDateFormatting is not optional: without it every DateFormat
    // below throws LocaleDataException, and the catch at the bottom turns that
    // into a widget that silently stops updating whenever the app is closed.
    // The UI isolate never needs it because GlobalMaterialLocalizations loads
    // the symbols on the way up; a WorkManager isolate builds no MaterialApp.
    final (cached, subscribedEvents, l10n, use24h, _) = await (
      api.cachedUpcomingLaunches(),
      handler.loadSubscribedEventIDs(),
      AppLocalizations.delegate.load(locale),
      _use24h(),
      initializeDateFormatting(locale.languageCode),
    ).wait;

    final events = (await Future.wait(
      subscribedEvents.map((id) async {
        final parsed = int.tryParse(id);

        return parsed == null ? null : await api.cachedEvent(parsed);
      }),
    )).nonNulls.toList();

    final dates = FriendlyDates(l10n, use24h: use24h);

    final entries = nextEntries(
      launches: cached?.results ?? const [],
      events: events,
      now: DateTime.now(),
      format: (at, precision) => precisionTimeText(dates, at, precision),
    );

    // One key for the whole list, not three per row. `saveWidgetData` is a
    // method channel call whose handler ends in `prefs.commit()` — a
    // synchronous write of the entire preferences file — so a key per slot
    // meant 76 of them, on every resume, for a few dozen short strings.
    await HomeWidget.saveWidgetData("rows", jsonEncode(entries));

    await HomeWidget.saveWidgetData(
      "empty",
      entries.isEmpty ? l10n.widgetNothingUpcoming : "",
    );

    // Qualified, not `androidName`. That would resolve against
    // `context.packageName`, which carries the `.debug` suffix this app adds,
    // while the class stays in the unsuffixed namespace — so it would throw
    // ClassNotFoundException and read as "the widget never updates".
    await HomeWidget.updateWidget(
      qualifiedAndroidName: "io.github.xarantolus.rockit.RockItWidgetProvider",
    );

    await BackgroundHandler().scheduleWidgetRefresh(
      nextRefreshDelay(entries, DateTime.now()),
    );
  } catch (err) {
    debugPrint("Could not refresh the home screen widget: $err");
  }
}

Locale _locale() {
  final tag = PlatformDispatcher.instance.locale.languageCode;

  return AppLocalizations.supportedLocales.any((l) => l.languageCode == tag)
      ? Locale(tag)
      : const Locale('en');
}

/// The clock preference, saved by the UI where `MediaQuery` can be read, so a
/// background refresh does not silently switch the user to a 12-hour clock.
const _use24hKey = "widget:use24h";

Future<bool> _use24h() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();

  return prefs.getBool(_use24hKey) ?? false;
}

Future<void> rememberClockPreference(bool use24h) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_use24hKey, use24h);
}
