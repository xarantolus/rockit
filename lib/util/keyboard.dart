import 'dart:async';

import 'package:flutter/services.dart';

/// Brings the soft keyboard back up for the field that already has focus.
///
/// [FocusNode.requestFocus] does nothing when the node is already the primary
/// focus, and dismissing the keyboard — the back gesture, or a swipe down —
/// does not take focus away. So clearing a search field left the caret in it
/// and no keyboard: from the framework's point of view nothing had changed.
/// Asking the platform directly is the way back, and it works because the
/// input connection is still attached.
void showKeyboard() {
  unawaited(SystemChannels.textInput.invokeMethod<void>('TextInput.show'));
}
