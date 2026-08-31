/// What the home-screen widget shows, and when it needs saying again.
///
/// Pure: picking the entries and deciding when the text goes stale are both
/// testable without a widget, a channel or a device.
library;

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
}

/// How many rows the layout has.
///
/// All of them are written every time. Which of them are *shown* is the
/// provider's decision, taken from the widget's current height, so dragging
/// the widget taller fills the new space straight away instead of waiting for
/// the next refresh to notice.
const homeWidgetRows = 10;

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
      launch.id == null ? null : "launch-details::${launch.id}",
      rocket: launch.mission?.name == null ? null : launch.rocketName,
    );
  }

  for (final event in events) {
    add(
      event.name,
      event.date,
      event.datePrecision,
      event.id == null ? null : "event-details::${event.id}",
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

/// Writes the widget's rows and asks Android to redraw it.
///
/// Cache only: the widget never causes a request. Everything it shows was
/// already fetched by the listings or the background jobs.
Future<void> refreshHomeWidget() async {
  try {
    final api = LaunchLibraryAPI();
    final handler = BackgroundHandler();

    final cached = await api.cachedUpcomingLaunches();

    final events = <Event>[];
    for (final id in await handler.loadSubscribedEventIDs()) {
      final parsed = int.tryParse(id);
      final event = parsed == null ? null : await api.cachedEvent(parsed);
      if (event != null) {
        events.add(event);
      }
    }

    final locale = _locale();

    // Without this every DateFormat here throws LocaleDataException, and the
    // catch below turns that into a widget that silently stops updating
    // whenever the app is closed. The UI isolate never needs it because
    // GlobalMaterialLocalizations loads the symbols on the way up; a
    // WorkManager isolate builds no MaterialApp, so nothing does it there.
    await initializeDateFormatting(locale.languageCode);

    // The same strings the app shows. Loaded rather than read off a
    // BuildContext, because this also runs in the background isolate.
    final l10n = await AppLocalizations.delegate.load(locale);
    final dates = FriendlyDates(l10n, use24h: await _use24h());

    final entries = nextEntries(
      launches: cached?.results ?? const [],
      events: events,
      now: DateTime.now(),
      format: (at, precision) => precisionTimeText(dates, at, precision),
    );

    for (var i = 0; i < homeWidgetRows; i++) {
      final entry = i < entries.length ? entries[i] : null;

      await HomeWidget.saveWidgetData("title_$i", entry?.title ?? "");
      await HomeWidget.saveWidgetData("subtitle_$i", entry?.subtitle ?? "");
      await HomeWidget.saveWidgetData("payload_$i", entry?.payload ?? "");
    }

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
