import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum error_type {
  // cachedFallback means that the returned value was found by falling back to a cached response
  cachedFallback
}

extension ErrorType on error_type {
  String text(BuildContext context) {
    switch (this) {
      case error_type.cachedFallback:
        return AppLocalizations.of(context)!.showingCachedFallback;
    }
  }

  void showSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        text(context),
      ),
    ));
  }
}

class ErrorDetails<T> {
  ErrorDetails(this.data, [this.error]);

  error_type? error;
  T data;

  ErrorDetails<K> bubble<K>(K newData) {
    return ErrorDetails(newData, error);
  }

  void maybeShowSnack(BuildContext context) {
    error?.showSnack(context);
  }
}
