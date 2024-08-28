import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomAppBar {
  static AppBar create(
    BuildContext context, {
    String? title,
    TextStyle? titleStyle,
    List<Widget>? actions,
    Widget? icon,
  }) {
    var barColor = Theme.of(context).colorScheme.primary;

    return AppBar(
      backgroundColor: barColor,
      iconTheme: IconTheme.of(context).copyWith(color: Colors.white),
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: barColor,
        systemNavigationBarColor: barColor,
      ),
      title: title == null
          ? null
          : Text(
              title,
              style: titleStyle?.copyWith(color: Colors.white) ?? const TextStyle(color: Colors.white),
            ),
      leading: icon == null
          ? null
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Tooltip(
                message: title ?? "",
                child: icon,
              ),
            ),
      actions: actions,
    );
  }
}
