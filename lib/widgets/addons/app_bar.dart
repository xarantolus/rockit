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
    final lightTheme = Theme.of(context).brightness == Brightness.light;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: lightTheme ? null : Theme.of(context).backgroundColor,
      systemNavigationBarColor:
          lightTheme ? null : Theme.of(context).backgroundColor,
      systemStatusBarContrastEnforced: true,
    ));

    return AppBar(
      backgroundColor: lightTheme ? null : Theme.of(context).backgroundColor,
      centerTitle: true,
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
