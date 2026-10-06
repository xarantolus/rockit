/// Earliest first. Anything without a date goes last, and ties keep their
/// original order — `List.sort` is not stable, hence the index.
List<T> sortedByDate<T>(Iterable<T> items, DateTime? Function(T) dateOf) {
  final indexed = items.indexed.toList();
  indexed.sort((a, b) {
    final da = dateOf(a.$2);
    final db = dateOf(b.$2);
    if (da != null && db != null) {
      final byDate = da.compareTo(db);
      if (byDate != 0) {
        return byDate;
      }
    } else if (da != null) {
      return -1;
    } else if (db != null) {
      return 1;
    }
    return a.$1.compareTo(b.$1);
  });
  return [for (final (_, item) in indexed) item];
}
