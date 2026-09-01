/// The no-op used off the web, where `flutter_cache_manager` does the real
/// storing. Nothing calls these — every call site is behind `kIsWeb` — but they
/// have to exist for the conditional export to typecheck.
class ResponseCache {
  const ResponseCache();

  Future<String?> read(Uri url) async => null;

  Future<void> write(Uri url, String body) async {}
}

const responseCache = ResponseCache();
