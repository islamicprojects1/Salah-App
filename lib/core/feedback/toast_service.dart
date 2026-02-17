import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/feedback/toast_widget.dart';

/// Central service for showing modern toast notifications.
///
/// Uses overlay-based toasts (not Get.snackbar) for full control over
/// appearance and animation. Single source of truth for all toast UI.
class ToastService {
  ToastService._();

  static OverlayEntry? _currentEntry;

  /// Dismiss any currently visible toast.
  static void dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
  }

  static void _show(
    String title, {
    String? message,
    required ToastType type,
    Duration duration = const Duration(seconds: 3),
    bool deferred = false,
  }) {
    dismiss();

    final overlay = Get.overlayContext;
    final overlayState = overlay != null ? Overlay.maybeOf(overlay) : null;

    if (overlay == null || overlayState == null) {
      if (!deferred) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _show(
            title,
            message: message,
            type: type,
            duration: duration,
            deferred: true,
          );
        });
      } else {
        debugPrint('ToastService: Overlay not ready, skipping toast.');
      }
      return;
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => ToastWidget(
        title: title,
        message: message,
        type: type,
        duration: duration,
        onTap: () {
          try {
            entry.remove();
          } catch (_) {}
          if (_currentEntry == entry) _currentEntry = null;
        },
      ),
    );
    _currentEntry = entry;
    overlayState.insert(entry);

    Timer(duration, () {
      if (_currentEntry != entry) return;
      try {
        entry.remove();
      } catch (_) {}
      if (_currentEntry == entry) _currentEntry = null;
    });
  }

  static void success(String title, [String? message]) {
    _show(title, message: message, type: ToastType.success);
  }

  static void error(String title, [String? message]) {
    _show(
      title,
      message: message,
      type: ToastType.error,
      duration: const Duration(seconds: 4),
    );
  }

  static void warning(String title, [String? message]) {
    _show(title, message: message, type: ToastType.warning);
  }

  static void info(String title, [String? message]) {
    _show(title, message: message, type: ToastType.info);
  }
}
