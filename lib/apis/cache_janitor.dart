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
  /// Names match the `Config` keys the two stores are created with, because
  /// that is what the package names their directories after.
  static const _stores = {'images': imageBudget, 'http-cache': jsonBudget};

  static const imageBudget = 128 * 1024 * 1024;

  /// Enough for the deepest the background job can read — seven listing pages
  /// at ~3 MB, plus a per-launch copy of each entry — with room to spare.
  static const jsonBudget = 48 * 1024 * 1024;

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

      for (final store in _stores.entries) {
        await trim(Directory('${root.path}/${store.key}'), store.value);
      }
    } catch (e) {
      debugPrint("Could not sweep the caches: $e");
    }
  }

  /// Deletes oldest-first from [dir] until it fits [budget], returning the
  /// number of bytes freed.
  @visibleForTesting
  static Future<int> trim(Directory dir, int budget) async {
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

    if (total <= budget) {
      return 0;
    }

    files.sort((a, b) => a.$3.compareTo(b.$3));

    var freed = 0;
    var removed = 0;

    for (final (file, size, _) in files) {
      if (total - freed <= budget) {
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
