/// Remembers what the user has already been told about, so a repeated failure
/// is not repeated at them.
///
/// The subscriptions listing reloads every time the user comes back from a
/// detail page, and each reload used to announce the same failure again — as a
/// modal dialog, so it had to be dismissed each time.
///
/// Deliberately keyed by item rather than a single "did anything fail" flag: a
/// *new* subscription failing is worth saying, even if an older one has been
/// failing all along.
class FailureReporter {
  final _reported = <String>{};

  /// The failures worth mentioning now, given everything mentioned before.
  ///
  /// Anything that has started working again is forgotten, so if it breaks
  /// later that is news again.
  Set<String> take(Set<String> failed) {
    _reported.removeWhere((id) => !failed.contains(id));

    final fresh = failed.difference(_reported);
    _reported.addAll(fresh);

    return fresh;
  }
}
