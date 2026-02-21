import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/feedback/toast_widget.dart';

/// Central service for showing overlay toast notifications.
///
/// Uses Flutter's [Overlay] directly for full control over appearance
/// and animation. Always prefer this over [Get.snackbar].
///
/// ```dart
/// ToastService.success('Prayer logged!');
/// ToastService.error('Sync failed', 'Check your connection and try again.');
/// ```
class ToastService {
  const ToastService._();

  static OverlayEntry? _current;
  static Timer? _timer;

  // ============================================================
  // PUBLIC API
  // ============================================================

  static void success(String title, [String? message]) =>
      _show(title, message: message, type: ToastType.success);

  static void error(String title, [String? message]) => _show(
    title,
    message: message,
    type: ToastType.error,
    duration: const Duration(seconds: 4),
  );

  static void warning(String title, [String? message]) =>
      _show(title, message: message, type: ToastType.warning);

  static void info(String title, [String? message]) =>
      _show(title, message: message, type: ToastType.info);

  /// Immediately removes any visible toast.
  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    _safeRemove(_current);
    _current = null;
  }

  // ============================================================
  // INTERNALS
  // ============================================================

  static void _show(
    String title, {
    String? message,
    required ToastType type,
    Duration duration = const Duration(seconds: 3),
    bool isRetry = false, // ✅ بدون underscore
  }) {
    dismiss();

    final overlayContext = Get.overlayContext;
    final overlayState = overlayContext != null
        ? Overlay.maybeOf(overlayContext)
        : null;

    if (overlayState == null) {
      if (!isRetry) {
        // Defer one frame and try again — overlay may not be ready yet.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _show(
            title,
            message: message,
            type: type,
            duration: duration,
            isRetry: true,
          );
        });
      }
      return;
    }

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => ToastWidget(
        title: title,
        message: message,
        type: type,
        duration: duration,
        onTap: () {
          if (_current == entry) dismiss();
        },
      ),
    );

    _current = entry;
    overlayState.insert(entry);

    _timer = Timer(duration, () {
      if (_current == entry) dismiss();
    });
  }

  static void _safeRemove(OverlayEntry? entry) {
    if (entry == null) return;
    try {
      entry.remove();
    } catch (_) {
      // Entry may already be removed if the overlay was disposed.
    }
  }
}
