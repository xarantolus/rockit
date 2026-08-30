import 'package:rockit/apis/launch_library/api.dart';

/// Why a Launch Library request did not work.
///
/// Worth telling apart wherever it is shown: nobody knows the API rations
/// requests by the hour, so a limit we hit reads as the user's own connection
/// being bad unless it is named.
enum ApiIssue {
  none,

  /// The hourly budget is spent.
  rateLimited,

  /// The API could not be reached at all.
  unreachable,
}

/// Works out which it was, and when the limit clears if that is what happened.
///
/// Asks `/api-throttle/`, which is the one endpoint that still answers when
/// the rest is being refused and does not count against the budget itself.
/// Failing to read it therefore means the connection is gone; reading it and
/// finding the budget spent means the limit is what stopped us.
Future<({ApiIssue kind, Duration? retryIn})> diagnoseApiFailure() async {
  final throttle = await LaunchLibraryAPI().throttle();
  final remaining = throttle?.remaining;

  if (remaining == null || remaining > 0) {
    return (kind: ApiIssue.unreachable, retryIn: null);
  }

  return (kind: ApiIssue.rateLimited, retryIn: throttle?.untilLimitClears);
}
