/// Appends [incoming] to [current], skipping anything already in the list.
///
/// Both APIs page with overlapping windows, and a cached page can repeat items
/// that a later page also contains, so without this the same launch, event or
/// article shows up twice in the list.
List<I> mergePages<I, K>(
  List<I> current,
  List<I> incoming,
  K Function(I item) idOf,
) {
  final known = current.map(idOf).toSet();

  for (final item in incoming) {
    if (known.add(idOf(item))) {
      current.add(item);
    }
  }

  return current;
}
