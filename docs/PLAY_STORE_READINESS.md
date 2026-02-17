# Play Store v1 — Remaining Gaps Summary

This document summarizes remaining items for a production-ready Play Store v1 release. Most are outside code; the codebase is stabilized per the qurb-live-context-architecture plan.

## Completed in this iteration

- **Data layer**: `cached_family` table created in `_onCreate`, indexed; `clearAllData()` now clears `cached_family` on logout.
- **Live Context Engine**: `LiveContextService` initialized in `initLateServices()`, exposes `prayerContext` and `todaySummary`; Dashboard/Home UI consumes these observables; `onPrayerLogged()` refreshes today’s logs and countdown.
- **Onboarding**: Islamic-compliant illustrations in place (`onboarding_welcome.png`, `onboarding_community.png`); `ImageAssets` and `OnboardingScreen` unchanged.

## Remaining gaps (non-code / config)

1. **Privacy policy**
   - Add a privacy policy URL (e.g. hosted page) and link it from in-app settings and from the Play Store listing.

2. **App name and package**
   - Confirm app name and package ID for store listing and any third-party (e.g. Firebase, Google Sign-In) console configuration.

3. **Signing**
   - Configure app signing (Play App Signing or upload key) and ensure release builds use the correct keystore.

4. **Store listing**
   - Prepare store listing assets: short/long description, screenshots, feature graphic, and ensure content complies with store policies.

5. **Optional**
   - Run `flutter analyze` and address any remaining warnings in modified or critical paths.
   - Consider adding `path_provider` (or the appropriate package) to `pubspec.yaml` if `settings_controller` (or others) depend on it, to resolve `depend_on_referenced_packages` lint.

None of these block the current architecture or Live Context implementation; they are checklist items for the actual store submission.
