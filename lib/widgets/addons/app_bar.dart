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
    final theme = Theme.of(context);

    var barColor = theme.brightness == Brightness.light
        ? theme.primaryColor
        : theme.backgroundColor;

    return AppBar(
      backgroundColor: barColor,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: barColor,
        systemNavigationBarColor: barColor,
      ),
      title: title == null
          ? null
          : Text(
              title,
              style: titleStyle,
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
