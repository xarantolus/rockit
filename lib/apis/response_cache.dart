/// Where a fetched response body is kept so the next read costs nothing.
///
/// Only the web has an implementation here. Everywhere else `APIClient` uses
/// `flutter_cache_manager`, which stores files on disk — but on the web that
/// package falls back to a `NonStoringObjectProvider` and an in-memory file
/// system, so its cache reads always miss and nothing survives a reload. That
/// mattered more than it sounds: the Launch Library allows fifteen requests an
/// hour *per IP*, and sends no `Cache-Control`, so the browser will not reuse
/// its responses either. Every page load spent from that budget and every
/// listing started on a spinner.
library;

export 'response_cache_stub.dart'
    if (dart.library.js_interop) 'response_cache_web.dart';
