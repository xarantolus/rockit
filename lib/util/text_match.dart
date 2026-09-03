final _bySpace = RegExp(r'\s+');

/// A query split into the terms every match has to contain.
///
/// Empty for a query that is blank or only whitespace, which callers decide
/// what to do with: search shows everything, a keyword matches nothing.
List<String> queryTerms(String query) {
  final trimmed = query.toLowerCase().trim();

  return trimmed.isEmpty ? const [] : trimmed.split(_bySpace);
}

/// Whether every term appears somewhere in [haystack], which must already be
/// lowercase.
///
/// Shared so that a word typed into search and the same word saved as a
/// keyword behave the same way. They match over deliberately *different*
/// fields — search reads the provider, the pad and the mission text, while a
/// keyword only ever reads the launch name and the rocket, or "spacex" would
/// mean the whole listing — but the rule applied to those fields is one rule.
///
/// Terms rather than one substring, because the fields are joined: a keyword
/// of "falcon starlink" should find a Starlink mission on a Falcon 9, where
/// neither field contains that phrase on its own. It also makes word order
/// irrelevant, which nobody expects to matter.
bool matchesAllTerms(String haystack, List<String> terms) =>
    terms.isNotEmpty && terms.every(haystack.contains);
