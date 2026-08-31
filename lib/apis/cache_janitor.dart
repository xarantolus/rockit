import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Keeps the on-disk caches inside a byte budget, which
/// `flutter_cache_manager` does not: it bounds a store by object count only.
///
/// It also collects the files the stores cannot. Cleanup only deletes what the
/// index lists, and that index is a debounced whole-file write both isolates
/// rewrite, so anything one of them loses is unreachable *and* undeletable.
/// Sweeping by mtime catches both without reading either index — orphans are
/// old — and evicting a live file is safe, because the store checks a file
/// exists before serving it and refetches when it does not.
class CacheJanitor {
  /// Both budgets sit above what each store's own object cap allows, so the
  /// stores' least-recently-used eviction bites first and this only ever
  /// catches a runaway. Setting either below its cap hands the eviction back
  /// here. See CLAUDE.md for the measured file sizes behind the numbers.
  static const imageBudget = 64 * 1024 * 1024;

  static const articleImageBudget = 56 * 1024 * 1024;

  /// Enough for the deepest the background job can read — seven listing pages
  /// at ~3 MB, plus a per-launch copy of each entry — with room to spare.
  static const jsonBudget = 48 * 1024 * 1024;

  /// How long a stored *response* may go without being refetched.
  ///
  /// Nothing else expires one: `stalePeriod` counts from the last read rather
  /// than the last write, and a launch that has flown leaves the listings and
  /// is never re-seeded, so it would keep whatever it last said — a status
  /// frozen at "Go for Launch" for a rocket that landed weeks ago.
  ///
  /// Images are exempt: one at a URL does not change.
  static const maxResponseAge = Duration(days: 7);

  /// Names match the `Config` keys the two stores are created with, because
  /// that is what the package names their directories after.
  static const _stores = [
    (dir: 'images', budget: imageBudget, maxAge: null),
    (dir: 'article-images', budget: articleImageBudget, maxAge: null),
    (dir: 'http-cache', budget: jsonBudget, maxAge: maxResponseAge),
  ];

  /// Deletes oldest-first until each store is under its budget.
  ///
  /// Never throws: a cache that cannot be tidied is not worth failing a start
  /// over.
  Future<void> sweep() async {
    if (kIsWeb) {
      return;
    }

    try {
      final root = await getTemporaryDirectory();

      for (final store in _stores) {
        await trim(
          Directory('${root.path}/${store.dir}'),
          store.budget,
          maxAge: store.maxAge,
        );
      }
    } catch (e) {
      debugPrint("Could not sweep the caches: $e");
    }
  }

  /// Deletes everything older than [maxAge], then oldest-first until [dir]
  /// fits [budget]. Returns the number of bytes freed.
  ///
  /// Age is the file's own modification time, which is when it was written —
  /// so this measures how long ago the response was *fetched*, not how
  /// recently someone looked at it. That is the right question for a response,
  /// and it is the only one available anyway: Android mounts `/data` with
  /// `noatime`, so `FileStat.accessed` never moves off the write time. Ordering
  /// by last use is left to the stores themselves, which track it in their own
  /// index.
  @visibleForTesting
  static Future<int> trim(Directory dir, int budget, {Duration? maxAge}) async {
    if (!await dir.exists()) {
      return 0;
    }

    final files = <(File, int, DateTime)>[];
    var total = 0;

    await for (final entry in dir.list(followLinks: false)) {
      if (entry is! File) {
        continue;
      }

      try {
        final stat = await entry.stat();
        total += stat.size;
        files.add((entry, stat.size, stat.modified));
      } catch (e) {
        debugPrint("Could not stat ${entry.path}: $e");
      }
    }

    final expiry = maxAge == null ? null : DateTime.now().subtract(maxAge);
    final expired = expiry != null && files.any((f) => f.$3.isBefore(expiry));

    if (total <= budget && !expired) {
      return 0;
    }

    files.sort((a, b) => a.$3.compareTo(b.$3));

    var freed = 0;
    var removed = 0;

    for (final (file, size, modified) in files) {
      final tooOld = expiry != null && modified.isBefore(expiry);

      if (!tooOld && total - freed <= budget) {
        break;
      }

      try {
        await file.delete();
        freed += size;
        removed++;
      } catch (e) {
        debugPrint("Could not delete ${file.path}: $e");
      }
    }

    debugPrint(
      "Swept ${dir.path}: removed $removed files, "
      "${freed ~/ (1024 * 1024)} MB, leaving ${(total - freed) ~/ (1024 * 1024)} MB",
    );

    return freed;
  }
}
