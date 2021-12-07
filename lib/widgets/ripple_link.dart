import 'package:flutter/material.dart';
import 'package:rockit/mixins/link_copy.dart';
import 'package:rockit/mixins/url_launcher.dart';

class RippleLinkWidget extends StatefulWidget {
  const RippleLinkWidget(this.mainText,
      {Key? key, this.bottomRight, this.bottomLeft, this.url})
      : super(key: key);

  final String mainText;
  final String? bottomLeft;
  final String? bottomRight;
  final String? url;

  @override
  _RippleLinkWidgetState createState() => _RippleLinkWidgetState();
}

class _RippleLinkWidgetState extends State<RippleLinkWidget>
    with UrlLauncher, LinkCopier {
  @override
  Widget build(BuildContext context) {
    return Material(
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
          title: Text(
            widget.mainText,
          ),
          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // We need an empty widget here, because if we don't add this, the date text will be on the left
              if (widget.bottomLeft == null)
                const SizedBox.shrink()
              else
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(widget.bottomLeft!),
                ),
              if (widget.bottomRight != null)
                Align(
                    alignment: Alignment.centerRight,
                    child: Text(widget.bottomRight!)),
            ],
          ),
          visualDensity: VisualDensity.comfortable,
        ),
      ),
    );
  }
}
