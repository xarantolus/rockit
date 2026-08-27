import 'package:flutter/foundation.dart';
import 'package:rockit/apis/error_details.dart';

/// What a cache-first listing is currently showing.
enum ListingStatus {
  /// Nothing to show yet and a load is running.
  loading,

  /// Data is on screen and nothing is in flight.
  ready,

  /// Data is on screen — possibly stale — while a refresh runs behind it.
  refreshing,

  /// Nothing to show and the load failed.
  failed,
}

/// Loads a listing cache-first: whatever is stored shows up immediately, a
/// refresh runs behind it, and a refresh that fails leaves the old data alone.
///
/// Deliberately knows nothing about widgets or `BuildContext` — it exposes
/// state and the UI reacts to it, which keeps async gaps out of the widget tree
/// and makes the rules testable without pumping a widget.
class CacheFirstController<T> extends ChangeNotifier {
  CacheFirstController({
    required this.loadCached,
    required this.loadFresh,
  });

  /// Returns what is stored locally, or null when nothing is. Must not touch
  /// the network — the whole point is that it returns in milliseconds.
  final Future<T?> Function() loadCached;

  /// Goes to the network. Throwing is how a failed refresh is reported.
  final Future<T> Function() loadFresh;

  T? _data;
  T? get data => _data;

  ListingStatus _status = ListingStatus.loading;
  ListingStatus get status => _status;

  bool get isRefreshing => _status == ListingStatus.refreshing;

  bool _showingCached = false;

  /// True while the data on screen came out of the cache rather than the
  /// network.
  bool get showingCached => _showingCached;

  Object? _fatalError;

  /// Set only when there is nothing to show at all. A failure with data on
  /// screen is reported through [takeNotice] instead, and the data stays.
  Object? get fatalError => _fatalError;

  ErrorType? _notice;

  /// A one-shot notice about the last load — a failed refresh, or a response
  /// that itself fell back to the cache. Reading it clears it, so the UI shows
  /// each notice exactly once.
  ErrorType? takeNotice() {
    final notice = _notice;
    _notice = null;
    return notice;
  }

  /// Records a notice raised inside [loadFresh], which succeeded but only
  /// partially.
  void noteNotice(ErrorType? notice) {
    if (notice != null) {
      _notice = notice;
    }
  }

  bool _disposed = false;

  /// Guards against a slow load landing after a newer one started, or after the
  /// widget went away. The API regularly takes 10s+, so this really happens.
  int _generation = 0;

  bool _isStale(int generation) => _disposed || generation != _generation;

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Renders the cache, then refreshes behind it.
  Future<void> start() async {
    final generation = ++_generation;

    try {
      final cached = await loadCached();

      if (_isStale(generation)) {
        return;
      }

      if (cached != null) {
        _data = cached;
        _showingCached = true;
        _status = ListingStatus.ready;
        _notify();
      }
    } catch (e) {
      debugPrint("Error reading cached listing: $e");
    }

    await _runRefresh(generation);
  }

  /// An explicit refresh — pull-to-refresh, or a retry after a failed load.
  Future<void> refresh() => _runRefresh(++_generation);

  Future<void> _runRefresh(int generation) async {
    _status = _data == null ? ListingStatus.loading : ListingStatus.refreshing;
    _notify();

    try {
      final fresh = await loadFresh();

      if (_isStale(generation)) {
        return;
      }

      _data = fresh;
      _showingCached = false;
      _fatalError = null;
      _status = ListingStatus.ready;
    } catch (e) {
      if (_isStale(generation)) {
        return;
      }

      debugPrint("Error refreshing listing: $e");

      if (_data == null) {
        _fatalError = e;
        _status = ListingStatus.failed;
      } else {
        // Never blank a list because a refresh failed.
        _notice = ErrorType.cachedFallback;
        _status = ListingStatus.ready;
      }
    }

    _notify();
  }
}
