import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// The longest edge worth keeping on disk.
///
/// Only downloads over [reencodeAbove] are re-encoded at all, and in this app
/// those are exclusively news press photos — sites publish the originals, one
/// NASA article photo measuring 8256x5504 and 16.6 MB — which are only ever
/// drawn in a 96 dp row, about 288 physical pixels. So this leaves better than
/// three times the headroom they need.
///
/// It is deliberately far below `decodeBucketFor`'s 2048 px ceiling, which is
/// the point beyond which *nothing* in the app can draw a pixel. Choosing 2048
/// instead costs about 3.5x the bytes for the same rows: measured over one run
/// of the news feed, 72 MB against 39 MB. The pathological case — an oversized
/// image drawn full width — is a 5% upscale on a 1080 px phone, and no Launch
/// Library image comes close to the threshold anyway.
const maxStoredEdge = 1024;

/// Below this, leave the download alone.
///
/// Re-encoding a small image is pure loss — the engine can only write PNG, and
/// PNG of a photograph is usually larger than the JPEG it came from. That is
/// the trap `maxWidthDiskCache` falls into: it keeps the original *and* a PNG
/// copy, which measured 73.9 MB to 81.0 MB over one run of the news feed. So
/// only genuinely oversized downloads are touched, and even then the result is
/// kept only if it is smaller.
const reencodeAbove = 2 * 1024 * 1024;

/// Stores a bounded copy of an oversized image instead of the original.
class BoundedImageFileService extends FileService {
  BoundedImageFileService([FileService? inner])
    : _inner = inner ?? HttpFileService();

  final FileService _inner;

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    final response = await _inner.get(url, headers: headers);

    // The common case never buffers: it stays a stream straight to disk.
    final length = response.contentLength;
    if (length != null && length <= reencodeAbove) {
      return response;
    }

    final original = await _collect(response.content);
    if (original.length <= reencodeAbove) {
      return _BytesResponse(response, original, response.fileExtension);
    }

    final shrunk = await shrinkToBound(original);

    // Only if it actually saved something — see [reencodeAbove].
    if (shrunk == null || shrunk.length >= original.length) {
      return _BytesResponse(response, original, response.fileExtension);
    }

    debugPrint(
      "Stored $url as ${shrunk.length ~/ 1024} KB "
      "instead of ${original.length ~/ 1024} KB",
    );

    return _BytesResponse(response, shrunk, '.png');
  }

  static Future<Uint8List> _collect(Stream<List<int>> content) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in content) {
      builder.add(chunk);
    }

    return builder.takeBytes();
  }
}

/// Re-encodes [bytes] so its longest edge is at most [maxStoredEdge], or
/// returns null when it is already small enough or cannot be read.
///
/// Deliberately goes through [ui.ImageDescriptor] rather than decoding first:
/// the descriptor reports the size without decoding, so a 45-megapixel photo
/// never becomes 180 MB of RGBA just to find out it is too big.
Future<Uint8List?> shrinkToBound(Uint8List bytes) async {
  ui.ImmutableBuffer? buffer;
  ui.ImageDescriptor? descriptor;
  ui.Image? image;

  try {
    buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    descriptor = await ui.ImageDescriptor.encoded(buffer);

    final longest = descriptor.width > descriptor.height
        ? descriptor.width
        : descriptor.height;
    if (longest <= maxStoredEdge) {
      return null;
    }

    final scale = maxStoredEdge / longest;
    final codec = await descriptor.instantiateCodec(
      targetWidth: (descriptor.width * scale).round(),
      targetHeight: (descriptor.height * scale).round(),
    );

    final frame = await codec.getNextFrame();
    image = frame.image;

    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    codec.dispose();

    return png?.buffer.asUint8List();
  } catch (e) {
    debugPrint("Could not shrink an image before storing it: $e");
    return null;
  } finally {
    image?.dispose();
    descriptor?.dispose();
    buffer?.dispose();
  }
}

/// A response whose body is already in memory.
class _BytesResponse implements FileServiceResponse {
  _BytesResponse(this._original, this._bytes, this._extension);

  final FileServiceResponse _original;
  final Uint8List _bytes;
  final String _extension;

  @override
  Stream<List<int>> get content => Stream.value(_bytes);

  @override
  int? get contentLength => _bytes.length;

  @override
  int get statusCode => _original.statusCode;

  @override
  DateTime get validTill => _original.validTill;

  @override
  String? get eTag => _original.eTag;

  @override
  String get fileExtension => _extension;
}
