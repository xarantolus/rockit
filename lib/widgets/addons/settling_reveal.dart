import 'dart:async';

import 'package:flutter/material.dart';

/// Scrolls to a target that is still moving.
///
/// A detail page opened from an update notification has to land on its
/// updates card, but the offset of that card is not known at the moment the
/// page first lays out: the hero photo, the rocket image and the launch site
/// map all arrive over the network afterwards, and every one of them pushes
/// the card further down. Scrolling once after the first frame therefore aims
/// at where the card *was* and stops short — the further down the page the
/// target is, the more content there is above it to grow, so it consistently
/// looks like it gave up halfway.
///
/// So the scroll is repeated while the page is still growing, and stops on
/// the first of:
///
/// - the content height holding still across a couple of checks, meaning
///   everything above the target has finished arriving,
/// - [timeout], so a page whose images never load does not retry forever,
/// - **the user scrolling themselves**, which matters most: correcting the
///   position under someone who has taken over reads as the page fighting
///   them, which is worse than landing short.
class SettlingReveal {
  SettlingReveal({
    required this.controller,
    required this.targetKey,
    this.alignment = 0.05,
    this.timeout = const Duration(seconds: 4),
  });

  final ScrollController controller;
  final GlobalKey targetKey;

  /// Where in the viewport to put the target, as [Scrollable.ensureVisible].
  final double alignment;

  final Duration timeout;

  /// How often to look at whether the page has grown. Short enough that a
  /// correction follows an image closely, long enough not to spend a frame
  /// budget on it.
  static const _checkInterval = Duration(milliseconds: 150);

  /// How many consecutive unchanged heights count as settled.
  static const _stableChecks = 3;

  Timer? _ticker;
  Timer? _deadline;
  double? _lastExtent;
  int _stable = 0;
  bool _stopped = false;

  /// Scrolls to the target now, then keeps it in view as the page grows.
  void start() {
    if (_stopped) {
      return;
    }

    _revealNow(animated: true);

    _deadline = Timer(timeout, stop);
    _ticker = Timer.periodic(_checkInterval, (_) => _check());
  }

  /// Called when the user starts scrolling of their own accord.
  void handOverToUser() => stop();

  void stop() {
    _stopped = true;
    _ticker?.cancel();
    _deadline?.cancel();
    _ticker = null;
    _deadline = null;
  }

  void dispose() => stop();

  void _check() {
    if (!controller.hasClients) {
      return;
    }

    final extent = controller.position.maxScrollExtent;

    if (_lastExtent != null && (extent - _lastExtent!).abs() < 0.5) {
      // Nothing above the target has grown since the last look. A few of
      // these in a row and the page can be called settled.
      if (++_stable >= _stableChecks) {
        stop();
      }

      return;
    }

    _lastExtent = extent;
    _stable = 0;

    // The page grew, so the target has moved: follow it. Not animated — an
    // animation per correction would visibly stutter, and the first call
    // already did the travelling.
    _revealNow(animated: false);
  }

  void _revealNow({required bool animated}) {
    final context = targetKey.currentContext;
    if (context == null) {
      return;
    }

    Scrollable.ensureVisible(
      context,
      duration: animated ? const Duration(milliseconds: 400) : Duration.zero,
      curve: Curves.easeOutCubic,
      alignment: alignment,
    );
  }
}
