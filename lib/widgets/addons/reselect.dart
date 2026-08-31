import 'package:flutter/material.dart';

/// Tapping the destination you are already on.
///
/// The bottom bar cannot reach the list itself — it is a sibling of the
/// `TabBarView`, not an ancestor — so it announces the reselection here and
/// whichever list is on that tab answers.
class ReselectionNotifier extends ChangeNotifier {
  int? _index;

  /// The destination most recently tapped while already showing.
  int? get index => _index;

  void reselect(int index) {
    _index = index;
    notifyListeners();
  }
}

/// A plain [InheritedWidget] and not an [InheritedNotifier]: the listings
/// subscribe to the notifier themselves and scroll in response, so the rebuild
/// an InheritedNotifier does on every notify would be three whole listings
/// rebuilt to produce exactly the same tree.
class Reselections extends InheritedWidget {
  const Reselections({required this.notifier, required super.child, super.key});

  final ReselectionNotifier notifier;

  static ReselectionNotifier? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Reselections>()?.notifier;

  @override
  bool updateShouldNotify(Reselections oldWidget) =>
      notifier != oldWidget.notifier;
}

/// Scrolls [controller] back to the top when destination [index] is tapped
/// while it is already showing.
///
/// The index is passed in rather than read from the `TabController`, because
/// a `TabBarView` builds its neighbours: every page would see the same current
/// index and they would all scroll, throwing away the position on the tabs you
/// are not looking at.
class ScrollToTopOnReselect extends StatefulWidget {
  const ScrollToTopOnReselect({
    required this.index,
    required this.controller,
    required this.child,
    super.key,
  });

  final int index;
  final ScrollController controller;
  final Widget child;

  @override
  State<ScrollToTopOnReselect> createState() => _ScrollToTopOnReselectState();
}

class _ScrollToTopOnReselectState extends State<ScrollToTopOnReselect> {
  ReselectionNotifier? _notifier;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final found = Reselections.of(context);
    if (found == _notifier) {
      return;
    }

    _notifier?.removeListener(_onReselected);
    _notifier = found?..addListener(_onReselected);
  }

  @override
  void dispose() {
    _notifier?.removeListener(_onReselected);
    super.dispose();
  }

  void _onReselected() {
    if (_notifier?.index != widget.index || !widget.controller.hasClients) {
      return;
    }

    // Already there: an animation to where you are is a flicker.
    if (widget.controller.offset <= 0) {
      return;
    }

    // A long feed is thousands of pixels down, and animating the whole way
    // would both take an age and build every row in between. jumpTo for the
    // bulk of it, then animate the last screen so it still reads as travel
    // rather than a cut.
    final runway = MediaQuery.of(context).size.height;
    if (widget.controller.offset > runway) {
      widget.controller.jumpTo(runway);
    }

    widget.controller.animateTo(
      0,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
