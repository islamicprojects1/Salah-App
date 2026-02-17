import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
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

  // Centralized error logging (debug + optional Crashlytics in release)
  FlutterError.onError = (details) {
    AppLogger.error(
      details.exceptionAsString(),
      details.exception,
      details.stack,
    );
    FlutterError.presentError(details);
  };

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize core dependencies (GetIt)
  await initInjection();

  runApp(const SalahApp());

  // Initialize non-critical services after first frame renders
  WidgetsBinding.instance.addPostFrameCallback((_) {
    initLateServices();
  });
}
