import 'dart:io';

import 'package:flutter/material.dart';

/// Utilities for resolving image sources from arbitrary URL/path strings.
class ImageHelper {
  const ImageHelper._();

  // ============================================================
  // IMAGE PROVIDER
  // ============================================================

  /// Returns the correct [ImageProvider] for a given [url] or local path.
  ///
  /// - `http` / `https` → [NetworkImage]
  /// - `file://` URI → [FileImage]
  /// - Any other string → treated as a local file path → [FileImage]
  /// - `null`, empty, or unparseable → `null`
  static ImageProvider? fromUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    try {
      final uri = Uri.parse(url);
      if (uri.scheme == 'http' || uri.scheme == 'https') {
        return NetworkImage(url);
      }
      if (uri.scheme == 'file') {
        return FileImage(File(uri.toFilePath()));
      }
      // Bare local path (no scheme)
      return FileImage(File(url));
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // WIDGET HELPERS
  // ============================================================

  /// Builds an [Image] widget for [url] with a configurable [placeholder]
  /// and optional [errorWidget].
  ///
  /// Falls back to [placeholder] when the URL is null/empty or the image fails to load.
  static Widget buildImage({
    required String? url,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget placeholder = const SizedBox.shrink(),
    Widget? errorWidget,
  }) {
    final provider = fromUrl(url);
    if (provider == null) return placeholder;

    return Image(
      image: provider,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => errorWidget ?? placeholder,
    );
  }

  // ============================================================
  // DEPRECATED ALIAS
  // ============================================================

  @Deprecated('Use ImageHelper.fromUrl() instead.')
  static ImageProvider? getImageProvider(String? url) => fromUrl(url);
}
