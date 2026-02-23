import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:salah/app.dart';
import 'package:salah/core/di/injection_container.dart';
import 'package:salah/core/error/app_logger.dart';
import 'package:salah/firebase_options.dart';

/// Application entry point.
///
/// Initialization order:
/// 1. Flutter bindings
/// 2. Error/logging handlers
/// 3. Firebase
/// 4. Device orientation
/// 5. Core dependencies via [initInjection]
/// 6. Render app
/// 7. Post-frame: init late services via [initLateServices]
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Flutter framework errors (widget build, layout, etc.)
  FlutterError.onError = (details) {
    AppLogger.error(
      details.exceptionAsString(),
      details.exception,
      details.stack,
    );
    FlutterError.presentError(details);
  };

  // Uncaught async / platform-channel errors not routed through FlutterError
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error('Uncaught platform error', error, stack);
    return true; // prevents the app from crashing
  };

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize intl date formatting for ar/en (required before DateFormat with locale)
  await initializeDateFormatting('ar');
  await initializeDateFormatting('en');

  // Initialize core dependencies (GetIt)
  await initInjection();

  runApp(const SalahApp());

  // Initialize non-critical services after first frame renders
  WidgetsBinding.instance.addPostFrameCallback((_) {
    initLateServices();
  });
}
