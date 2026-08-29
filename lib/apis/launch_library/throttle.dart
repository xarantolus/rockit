import 'package:json_annotation/json_annotation.dart';

part 'throttle.g.dart';

/// What `/2.3.0/api-throttle/` reports about our budget.
///
/// The budget is keyed by public IP (`ident` is the address), so every device
/// behind one connection shares it — which is the usual reason the API starts
/// refusing mid-session.
@JsonSerializable(fieldRename: FieldRename.snake, createToJson: false)
class ApiThrottle {
  const ApiThrottle({
    this.yourRequestLimit,
    this.limitFrequencySecs,
    this.currentUse,
    this.nextUseSecs,
    this.ident,
  });

  final int? yourRequestLimit;
  final int? limitFrequencySecs;
  final int? currentUse;

  /// Seconds until a slot frees up, once the budget is spent.
  final int? nextUseSecs;

  final String? ident;

  /// How many requests may still be spent without going past half the budget.
  ///
  /// Half, so that opening the app right after a background job still has room
  /// to load what the user actually asked for.
  int get requestsUntilHalfSpent {
    final limit = yourRequestLimit;
    if (limit == null || limit <= 0) {
      return 0;
    }

    return (limit ~/ 2) - (currentUse ?? 0);
  }

  factory ApiThrottle.fromJson(Map<String, dynamic> json) =>
      _$ApiThrottleFromJson(json);
}
