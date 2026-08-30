import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Keeps the on-disk caches inside a byte budget.
///
/// `flutter_cache_manager` bounds a store by *object count* — 200 by default —
/// and never by size, so a store of news photos is unbounded in practice: the
/// originals run to 16 MB each. It also only ever deletes files its own index
/// lists, and that index is a whole-file write debounced by three seconds
/// which the UI and background isolates both rewrite; whatever one of them
/// loses becomes a file nothing will ever reclaim. Measured on a test device:
/// 459 files against 200 index entries, so 259 were unreachable *and*
/// undeletable.
///
/// Sweeping by mtime handles both without reading either index: orphans are
/// old, so they go first, and deleting a file the index still knows about is
/// safe — the store checks that a file exists before serving it, drops the
/// entry when it does not, and refetches.
class CacheJanitor {
  /// Both budgets are set so the *stores'* own least-recently-used caps bite
  /// first and this only ever catches a runaway. Sized from what the files
  /// actually weigh rather than a round number:
  ///
  /// - Launch and event photos are **163 KB** on average and 473 KB at worst
  ///   (measured across 37 of them), and none is over the 2 MB threshold at
  ///   which `BoundedImageFileService` would shrink one — so they are stored
  ///   exactly as the API serves them. At 300 objects the store tops out
  ///   around 49 MB.
  /// - Article thumbnails are the shrunk-down press photos, ~350 KB each. At
  ///   150 objects that is about 52 MB.
  ///
  /// The old split gave launch photos 96 MB they could never use while
  /// capping thumbnails below what their own object limit allows, which had
  /// the byte budget doing the evicting for one store and the LRU for the
  /// other.
  static const imageBudget = 64 * 1024 * 1024;

  static const articleImageBudget = 56 * 1024 * 1024;

  /// Enough for the deepest the background job can read — seven listing pages
  /// at ~3 MB, plus a per-launch copy of each entry — with room to spare.
  static const jsonBudget = 48 * 1024 * 1024;

  /// How long a stored *response* may go without being refetched.
  ///
  /// Nothing else expires one. The store's `stalePeriod` counts from the last
  /// *read*, not the last write, so an entry that keeps being read is kept
  /// forever, and the cache-only reads never fall through to the network. A
  /// launch that has since flown drops out of the listings — they start at
  /// `net__gte` yesterday — so it is never re-seeded either: whatever it said
  /// the last time it was fetched is what it would say for good, including a
  /// status frozen at "Go for Launch" for a rocket that has long since landed.
  ///
  /// Only responses age out. An image at a URL does not change, so evicting a
  /// good one only means downloading it again.
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
