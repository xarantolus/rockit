import 'package:flutter/foundation.dart';
import 'package:idb_shim/idb_browser.dart';

/// Response bodies kept in IndexedDB, keyed by URL.
///
/// IndexedDB rather than `localStorage` because of what goes in it: one
/// listing page is about 860 KB of JSON, which `localStorage` counts as ~1.7 MB
/// of its ~5 MB origin quota, and a page also seeds a copy of each of its
/// hundred launches. IndexedDB has room for that; `localStorage` would start
/// throwing on the second page.
///
/// Rather than the Cache API, which fits the job semantically, because it is
/// only available in a secure context — which would leave this untestable over
/// plain http on the emulator.
class ResponseCache {
  const ResponseCache();

  static const _dbName = 'rockit-responses';
  static const _store = 'responses';
  static const _bodyField = 'body';
  static const _writtenField = 'written';

  /// Absolute, by write time, matching `CacheJanitor.maxResponseAge` on
  /// Android. A response that keeps being read is still a response that has
  /// gone stale — a launch that has flown drops out of the listings and would
  /// otherwise say "Go for Launch" for ever.
  static const maxAge = Duration(days: 7);

  /// The same bound `APIClient` gives the file cache, for the same reason: a
  /// listing page writes itself plus one entry per launch in it.
  static const maxEntries = 800;

  static Future<Database>? _opening;

  Future<Database?> _db() async {
    try {
      return await (_opening ??= idbFactoryBrowser.open(
        _dbName,
        version: 1,
        onUpgradeNeeded: (VersionChangeEvent event) {
          event.database.createObjectStore(_store);
        },
      ));
    } catch (err) {
      // Private browsing and blocked site data both land here. The app simply
      // has no cache then, which is what it did before this existed.
      debugPrint("Could not open the response cache: $err");
      _opening = null;

      return null;
    }
  }

  Future<String?> read(Uri url) async {
    try {
      final db = await _db();
      if (db == null) {
        return null;
      }

      final txn = db.transaction(_store, idbModeReadOnly);
      final entry = await txn.objectStore(_store).getObject(url.toString());
      await txn.completed;

      if (entry is! Map) {
        return null;
      }

      final written = entry[_writtenField];
      if (written is int &&
          DateTime.now().millisecondsSinceEpoch - written >
              maxAge.inMilliseconds) {
        return null;
      }

      final body = entry[_bodyField];

      return body is String ? body : null;
    } catch (err) {
      debugPrint("Error reading $url from the response cache: $err");

      return null;
    }
  }

  Future<void> write(Uri url, String body) async {
    try {
      final db = await _db();
      if (db == null) {
        return;
      }

      final txn = db.transaction(_store, idbModeReadWrite);
      await txn.objectStore(_store).put({
        _bodyField: body,
        _writtenField: DateTime.now().millisecondsSinceEpoch,
      }, url.toString());
      await txn.completed;

      await _evict(db);
    } catch (err) {
      // Most likely the quota. Starting over is better than never storing
      // anything again, and the next fetch refills what is actually being used.
      debugPrint("Error writing $url to the response cache: $err");
      await _clear();
    }
  }

  /// Drops what has expired, then the oldest of whatever is left over the cap.
  Future<void> _evict(Database db) async {
    final txn = db.transaction(_store, idbModeReadWrite);
    final store = txn.objectStore(_store);

    final keys = await store.getAllKeys();
    final entries = await store.getAll();

    final now = DateTime.now().millisecondsSinceEpoch;
    final live = <(Object, int)>[];

    for (var i = 0; i < keys.length && i < entries.length; i++) {
      final entry = entries[i];
      final written = entry is Map ? entry[_writtenField] : null;

      if (written is! int || now - written > maxAge.inMilliseconds) {
        await store.delete(keys[i]);
        continue;
      }

      live.add((keys[i], written));
    }

    if (live.length > maxEntries) {
      live.sort((a, b) => a.$2.compareTo(b.$2));

      for (final (key, _) in live.take(live.length - maxEntries)) {
        await store.delete(key);
      }
    }

    await txn.completed;
  }

  Future<void> _clear() async {
    try {
      final db = await _db();
      if (db == null) {
        return;
      }

      final txn = db.transaction(_store, idbModeReadWrite);
      await txn.objectStore(_store).clear();
      await txn.completed;
    } catch (err) {
      debugPrint("Could not clear the response cache: $err");
    }
  }
}

const responseCache = ResponseCache();
