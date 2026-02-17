import 'dart:io';

import 'package:flutter/material.dart';

class ImageHelper {
  static ImageProvider? getImageProvider(String? url) {
    if (url == null || url.isEmpty) return null;

    try {
      final uri = Uri.parse(url);
      if (uri.scheme == 'http' || uri.scheme == 'https') {
        return NetworkImage(url);
      } else if (uri.scheme == 'file') {
        return FileImage(File(uri.toFilePath()));
      } else {
        // Assume local path if no scheme
        return FileImage(File(url));
      }
    } catch (e) {
      // Fallback or return null if parsing fails
      return null;
    }
  }
}
