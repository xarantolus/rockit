import 'package:flutter/material.dart';
import 'package:rockit/l10n/app_localizations.dart';

/// Why a response is not entirely what was asked for, even though it succeeded.
enum ErrorType {
  /// The value came from falling back to a cached response.
  cachedFallback,

  /// Not all of the data could be loaded.
  incompleteData;

  String text(BuildContext context) {
    switch (this) {
      case ErrorType.cachedFallback:
        return AppLocalizations.of(context)!.showingCachedFallback;
      case ErrorType.incompleteData:
        return AppLocalizations.of(context)!.showingIncompleteData;
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

  ErrorType? error;
  T data;

  ErrorDetails<K> bubble<K>(K newData) {
    return ErrorDetails(newData, error);
  }

  void maybeShowSnack(BuildContext context) {
    error?.showSnack(context);
  }
}
