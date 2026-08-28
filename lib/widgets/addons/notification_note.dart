import 'package:flutter/material.dart';
import 'package:rockit/background/handler.dart';
import 'package:rockit/l10n/app_localizations.dart';

/// The explanation under a subscription checkbox, plus a way back to the exact
/// alarm setting when it is off.
///
/// Requesting `SCHEDULE_EXACT_ALARM` shows no dialog — it opens Settings with
/// the toggle off — so it is asked once and offered here afterwards, next to
/// the reminders it affects.
class NotificationNote extends StatefulWidget {
  const NotificationNote({required this.description, super.key});

  /// Wording differs between a launch and an event, so the caller supplies it.
  final String description;

  @override
  State<NotificationNote> createState() => _NotificationNoteState();
}

class _NotificationNoteState extends State<NotificationNote> {
  /// Null until the first check comes back, so nothing flashes on screen.
  bool? _exactAllowed;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final allowed = await BackgroundHandler().exactAlarmsAllowed();

    if (mounted) {
      setState(() => _exactAllowed = allowed);
    }
  }

  Future<void> _openSettings() async {
    await BackgroundHandler().requestExactAlarms();

    // The user comes back from a system screen, so ask again rather than
    // assuming which way they went.
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.description),
          if (_exactAllowed == false) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: _openSettings,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.remindersMayBeLate,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
