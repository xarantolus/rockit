import 'package:flutter/material.dart';
import 'package:rockit/apis/launch_library/launch_response.dart';

/// A small colour-coded badge for a launch status.
///
/// Prominent because most of the schedule is "To Be Determined", and that is
/// what tells you whether a date is worth planning around.
class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {this.compact = false, super.key});

  final LaunchStatus? status;

  /// Cards use the abbreviation (`Go`, `TBD`); the detail header has room for
  /// the full name.
  final bool compact;

  /// Deliberately muted rather than saturated: a wall of loud badges is worse
  /// than none. Only outcomes that matter — failure, in flight — get a strong
  /// colour.
  Color _background(ColorScheme scheme) {
    final s = status;
    if (s == null) return scheme.surfaceContainerHighest;

    if (s.isSuccess || s.isGo) return const Color(0xFF1B7F4B);
    if (s.isFailure) return const Color(0xFFB3261E);
    if (s.isInFlight) return const Color(0xFF9A5B00);
    if (s.isHold) return const Color(0xFF8A6D00);

    // To Be Determined / Confirmed, and anything we do not recognise.
    return const Color(0xFF5A5F66);
  }

  @override
  Widget build(BuildContext context) {
    final label = compact
        ? (status?.abbrev ?? status?.name)
        : (status?.name ?? status?.abbrev);

    if (label == null || label.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: _background(Theme.of(context).colorScheme),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
