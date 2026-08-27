import 'package:flutter/material.dart';

/// A collapsible block on a detail page.
///
/// The detail pages used to be a dozen sections stacked in one endless scroll,
/// which made everything equally prominent and therefore nothing prominent.
/// Collapsing them keeps every fact reachable while letting the page open on
/// what matters — and [preview] means a closed section still says what is in
/// it, so collapsing does not just hide things.
class DetailSection extends StatefulWidget {
  const DetailSection({
    required this.title,
    required this.child,
    this.preview,
    this.count,
    this.initiallyExpanded = false,
    super.key,
  });

  final String title;
  final Widget child;

  /// One line shown while collapsed, e.g. the booster serial or the pad name.
  final String? preview;

  /// Shown next to the title, for sections that are really a list.
  final int? count;

  final bool initiallyExpanded;

  @override
  State<DetailSection> createState() => _DetailSectionState();
}

class _DetailSectionState extends State<DetailSection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1),
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (widget.count != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              "${widget.count}",
                              style: TextStyle(fontSize: 15, color: muted),
                            ),
                          ],
                        ],
                      ),
                      if (!_expanded && (widget.preview ?? "").isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.preview!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13.5, color: muted),
                        ),
                      ],
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(Icons.expand_more, color: muted),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: widget.child,
          ),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 180),
          sizeCurve: Curves.easeOutCubic,
        ),
      ],
    );
  }
}

/// A compact fact, e.g. the rocket or the target orbit. Used in a wrapping row
/// under the hero so the essentials are visible without opening anything.
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
