import 'package:flutter/material.dart';
import 'package:rockit/mixins/link_copy.dart';
import 'package:rockit/mixins/url_launcher.dart';

class RippleLinkWidget extends StatefulWidget {
  const RippleLinkWidget(
    this.mainText, {
    super.key,
    this.bottomRight,
    this.bottomLeft,
    this.url,
  });

  final String mainText;
  final String? bottomLeft;
  final String? bottomRight;
  final String? url;

  @override
  State<RippleLinkWidget> createState() => _RippleLinkWidgetState();
}

class _RippleLinkWidgetState extends State<RippleLinkWidget>
    with UrlLauncher, LinkCopier {
  @override
  Widget build(BuildContext context) {
    return Material(
      // Transparent, not the default: a bare Material is MaterialType.canvas,
      // which paints ThemeData.canvasColor — the *page* background. Inside a
      // DetailCard that drew a slab of the wrong colour behind every update.
      color: Colors.transparent,
      // This adds the ripple effect when holding the item
      child: InkWell(
        onTap: () async {
          setState(() {});

          if (widget.url != null) {
            await openCustomTab(context, widget.url!);
          }
        },
        onLongPress: () => copyLink(context, widget.url),
        child: ListTile(
          title: Text(widget.mainText),
          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // We need an empty widget here, because if we don't add this, the date text will be on the left
              if (widget.bottomLeft == null)
                const SizedBox.shrink()
              else
                // Expanded, so a long source name ("NASASpaceflight Forum") next
                // to a full timestamp is the half that gives (the date has a
                // bounded width and is the more useful of the two).
                Expanded(
                  child: Text(
                    widget.bottomLeft!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (widget.bottomRight != null) ...[
                const SizedBox(width: 8),
                Text(widget.bottomRight!, maxLines: 1),
              ],
            ],
          ),
          visualDensity: VisualDensity.comfortable,
        ),
      ),
    );
  }
}
