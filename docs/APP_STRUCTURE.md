# هيكل التطبيق — App Structure (Global Standard)

هذا المشروع منظم على نمط التطبيقات العالمية: طبقات واضحة، تسمية موحدة، ومسارات واحدة.

---

## Layer structure (طبقات التطبيق)

```
lib/
├── main.dart                 # Entry point, DI registration
├── core/                     # Shared: constants, theme, routes, services, i18n
├── data/                     # Data layer: models, repositories, sync
├── controller/               # Presentation logic (GetX controllers + bindings)
└── view/                     # UI: screens, widgets
```

### Core (`lib/core/`)
- **constants/** — API keys, dimensions, storage keys, asset paths
- **theme/** — Colors, fonts, app theme
- **routes/** — `AppRoutes` (route names), `AppPages` (GetPage list)
- **localization/** — `ar_translations`, `en_translations`, `Languages`
- **services/** — Singleton services (Auth, Firestore, Location, PrayerTimes, Sync, …)
- **helpers/** — Pure helpers (prayer names, date key, validators)
- **feedback/** — User feedback (snackbars, dialogs)

### Data (`lib/data/`)
- **models/** — Domain/data models (e.g. `UserModel`, `PrayerLogModel`, `FamilyModel`)
- **repositories/** — Data access & sync (`PrayerRepository`, `UserRepository`, …)
- **sync/** — Sync queue types and result DTOs

### Controller (`lib/controller/`)
- **\*.dart** — GetX controllers (one per main flow/screen)
- **bindings/** — GetX bindings per route (inject dependencies, lazyPut controllers)

### View (`lib/view/`)
- **screens/** — Full screens, grouped by feature (auth, dashboard, family, qibla, settings, …)
- **widgets/** — Reusable UI (buttons, cards, loading, empty state, …)

---

## Conventions (اتفاقيات)

| Item | Convention |
|------|------------|
| **Routes** | Use `AppRoutes.*` only; navigate with `Get.toNamed(AppRoutes.xyz)`. |
| **Strings** | User-facing text via `.tr` and keys in `ar_translations` / `en_translations`. |
| **Dependencies** | Register in `main.dart` (permanent) or in `Bindings` (lazy). Controllers get them via `Get.find<T>()` or constructor. |
| **Screens** | One main widget per file; use `GetView<Controller>` when bound. |
| **Naming** | `snake_case` for files; `PascalCase` for classes. |

---

## Flow (التدفق)

1. **Splash** → decides: onboarding, login, or dashboard.
2. **Onboarding** → then login or register.
3. **Auth** → then profile setup (if needed) or dashboard.
4. **Dashboard** — main shell: Home, Family, Qibla, Settings (tabs).
5. **Family** — create/join flows; family state from Firestore + `FamilyService`.

Backend: Firebase (Auth, Firestore). Offline: SQLite via `DatabaseHelper`; sync via `PrayerRepository` + `SyncService`.

---

## ملفات مهمة

| Purpose | File(s) |
|--------|---------|
| Dependency injection | `main.dart` (`initServices`) |
| Routes | `core/routes/app_routes.dart`, `app_pages.dart` |
| Theme | `core/theme/app_theme.dart`, `app_colors.dart`, `app_fonts.dart` |
| Localization | `core/localization/ar_translations.dart`, `en_translations.dart` |
| Sync / offline | `docs/SYNC.md`, `data/repositories/prayer_repository.dart` |

هذا الهيكل يبقى التطبيق سهل الصيانة والتوسع مثل التطبيقات العالمية.
