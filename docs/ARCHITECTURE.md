# Salah App — Architecture & Refactor Guide

This document describes the **current architecture**, **single sources of truth**, and **practices** used for production readiness.

---

## 1. Folder structure (feature-first)

```
lib/
├── main.dart              # Entry point, error handlers, initInjection, initLateServices
├── app.dart               # GetMaterialApp, theme, locale, routes
├── core/                  # Shared infrastructure
│   ├── constants/         # Single source: API, dimensions, enums, storage keys, assets
│   │   └── constants.dart # Export all constants (import one file)
│   ├── di/                # GetIt (sl) + GetX bindings
│   ├── error/             # AppLogger, global error handling
│   ├── feedback/          # AppFeedback, ToastService, ToastWidget (toasts + dialogs)
│   ├── localization/      # Languages, translations
│   ├── middleware/        # Route guards (e.g. onboarding)
│   ├── routes/            # AppPages, route names
│   ├── services/          # Cross-cutting: Storage, DB, Connectivity, Location, Sync
│   ├── theme/             # AppColors, AppFonts, AppTheme
│   └── widgets/           # Shared UI: AppDialog, AppLoading, EmptyState, etc.
├── features/              # Feature modules
│   ├── auth/              # Login, register, profile setup
│   ├── family/             # Family dashboard, create/join, repositories
│   ├── notifications/     # FCM, notifications screen
│   ├── onboarding/        # Welcome, features, permissions, profile setup
│   ├── prayer/             # Dashboard, qibla, missed prayers, prayer time, live context
│   ├── profile/           # Profile screen
│   ├── settings/          # Theme, locale, city, privacy, prayer adjustment
│   └── splash/             # Splash screen
└── shared/                # Shared data layer (e.g. BaseRepository)
```

**Principles:**
- **Single source of truth**: Constants in `core/constants/` (use `constants.dart` to import all). Theme in `core/theme/`. API endpoints in `api_constants.dart`.
- **Feature-first**: Each feature can have `data/` (models, repos, services), `presentation/` (screens, widgets, bindings), and `controller/` where needed.
- **Dependency injection**: GetIt (`sl`) for services and repos; GetX for route-scoped controllers (bindings).

---

## 2. User feedback (toasts & dialogs)

| Use case | API | Implementation |
|----------|-----|----------------|
| Success / error / info message | `AppFeedback.showSuccess(title, message)` / `showError` / `showSnackbar` | Overlay toasts via `ToastService` (modern, theme-aware) |
| Loading indicator | `AppFeedback.showLoading()` / `hideLoading()` | Dialog (non-dismissible) |
| Confirmation | `AppFeedback.confirm(title, message, ...)` | Dialog, returns `bool` |
| Rich dialogs (e.g. success with Lottie) | `AppDialogs.success(...)` / `AppDialogs.confirm(...)` | Custom dialog widgets |

**Rule:** Use `AppFeedback` for all simple feedback. Use `AppDialogs` only when you need a custom dialog (e.g. success animation, bottom sheet). Do not use raw `Get.snackbar` or `Get.dialog` in feature code.

---

## 3. Logging and error handling

- **AppLogger** (`core/error/app_logger.dart`): Use instead of `print`/`debugPrint`.  
  - `AppLogger.debug`, `info`, `warning`, `error`.  
  - In release you can extend to send `error` to Crashlytics.
- **FlutterError.onError** is set in `main.dart` to log via `AppLogger` and then present the error.

Use `AppLogger` in repositories and services when catching exceptions (e.g. `AppLogger.error('Sync failed', e, st)`).

---

## 4. Performance and startup

- **Critical path**: Only essential services are initialized before `runApp()` (storage, theme, localization, auth, Firestore, etc.). See `initInjection()` in `core/di/injection_container.dart`.
- **Late init**: Heavy or non-critical services (PrayerTimeService, NotificationService, FCM, Sync worker, Audio, Qada check) are initialized after the first frame via `initLateServices()` in a post-frame callback. This reduces jank and “Skipped N frames” on startup.
- **Lazy singletons**: Repositories and feature services are registered as lazy singletons so they are created only when first used.

---

## 5. State management

- **GetX** is used for reactive UI (`Obx`, `GetBuilder`) and route-scoped controllers (bindings).
- **Best practice**: Prefer small `Obx` wrappers around only the widget that depends on the observable, instead of one large `Obx` around a whole screen, to minimize rebuilds.

---

## 6. Responsive and accessibility

- **AppDimensions** (`core/constants/app_dimensions.dart`) provides breakpoints and helpers (`isMobile`, `isTablet`, `screenWidth`, etc.). Use them for responsive layouts.
- **Theme**: Text themes and colors are defined in `core/theme`. Support both light and dark; use `AppColors` for consistency.
- **RTL**: Handled in `app.dart` via `Directionality` and `LocalizationService.isRTL`.

---

## 7. What was refactored (summary)

- **Toasts**: Replaced raw Get.snackbar with overlay-based toasts (`ToastService` + `ToastWidget`). All success/error/info feedback now goes through `AppFeedback` (and optionally `AppDialogs.snackbar`, which delegates to `ToastService`).
- **Single feedback entry point**: `AppFeedback` is the single entry for toasts and simple dialogs; `AppDialogs` remains for custom dialogs and bottom sheets.
- **Logging**: Introduced `AppLogger` and wired `FlutterError.onError` in `main.dart`.
- **Constants**: Added `core/constants/constants.dart` that exports all constant files for one-import usage.
- **Error handling**: Global error handler logs via `AppLogger`; repositories and services should catch and log errors and surface user-facing messages via `AppFeedback.showError`.

---

## 8. Suggested next steps

- **Repositories**: In each repository, on catch, call `AppLogger.error` and then `AppFeedback.showError` (or return a Result type) so the UI can show a toast.
- **Forms**: Validate all inputs; show toasts for validation errors and use `AppFeedback` only (no raw snackbars).
- **Empty and error states**: Use `core/widgets/empty_state.dart` (or equivalent) for empty lists and error states with retry.
- **Pagination**: For long lists (e.g. feed, notifications), add pagination or lazy loading and cache results where applicable.
- **Assets**: Compress large images; use vector or small assets where possible to reduce app size.
