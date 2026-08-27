import 'package:flutter/material.dart';

/// One topic on a detail page.
///
/// These used to be collapsible, which made every section equally hidden and
/// turned the page into a filing cabinet. Everything is visible now; the card
/// edge is what gives a long scroll structure, using the same rounded-and-
/// bordered language as the listings.
class DetailCard extends StatelessWidget {
  const DetailCard({
    required this.title,
    required this.child,
    this.trailing,
    this.padded = true,
    super.key,
  });

  final String title;
  final Widget child;

  /// Shown at the right of the label row, e.g. the rocket's name.
  final String? trailing;

  /// Set false when the child paints its own edge-to-edge content, such as a
  /// full-width map or a nested list of cards.
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.55);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.fromLTRB(10, 5, 10, 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
                    color: muted,
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      trailing!,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: muted,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: padded
                ? const EdgeInsets.fromLTRB(14, 0, 14, 14)
                : const EdgeInsets.only(bottom: 10),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// A bare section label, for content that is already a list of cards — putting
/// those inside a [DetailCard] would nest a card in a card.
class SectionLabel extends StatelessWidget {
  const SectionLabel({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(
      context,
    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.55);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 2),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
              color: muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// A label/value pair, used for the specification and info lists.
///
/// Replaces a bordered `Table`, which drew a grid around every fact and made
/// the page look like a spreadsheet.
class DetailRow extends StatelessWidget {
  const DetailRow({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(label, style: TextStyle(fontSize: 13.5, color: muted)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// A compact fact, e.g. the rocket or the target orbit. Used in a wrapping row
/// under the hero so the essentials are visible immediately.
class InfoChip extends StatelessWidget {
  const InfoChip({required this.label, this.icon, super.key});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = theme.textTheme.bodyMedium?.color?.withValues(
      alpha: 0.85,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: foreground),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
