import 'package:flutter/material.dart';

/// Bottom padding that keeps a scroll view's last item clear of the system
/// navigation bar.
///
/// The app is edge-to-edge, so content draws behind the gesture pill and
/// 3-button navigation. Padding rather than clipping is deliberate: content
/// still scrolls under the (translucent) bar, which is how edge-to-edge is
/// meant to look, but everything can be scrolled out from behind it. This is
/// the `clipToPadding=false` pattern Android documents for `RecyclerView`.
///
/// Returns zero when something else already consumed the inset — a [Scaffold]
/// with a `bottomNavigationBar` removes it from the body's [MediaQuery], so the
/// listings inside the home page correctly get nothing.
EdgeInsets bottomSystemBarPadding(BuildContext context) {
  return EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom);
}
