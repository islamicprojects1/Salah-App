# Salah App – Project Audit & Future Roadmap

**Role:** Senior Tech Consultant & Product Manager (harsh, professional critic)  
**Date:** February 2026  
**Scope:** Full codebase, folder structure, logic, UI, security, innovation.

---

## 1. Technical Debt & Code Smells

### DRY violations
- **Prayer name ↔ enum mapping** is duplicated in multiple places: `DashboardController._mapNameToPrayerName`, `PrayerTimeService.getTodayPrayers()` (hardcoded Arabic names), `prayer_card.dart` (switch for display names), `missed_prayer_card.dart`, `prayer_log_model._parsePrayerName`, `firestore_service` (string `'الشروق'`). There is no single source of truth (e.g. `PrayerNameExtension.displayName` or a shared `PrayerNames` helper).
- **Date key formatting** (`'${year}-${month}-${day}'`) is repeated in `DatabaseHelper` (cachePrayerTimes, getCachedPrayerTimes, cleanOldPrayerTimesCache) and could be a shared `DateTimeHelper.toDateKey()`.
- **“Is this prayer logged?” logic** is duplicated: same `any((l) => l.prayer.name == ... || (name == 'الشروق' && l.prayer == PrayerName.sunrise))` in `DashboardController.logPrayer`, `_buildActionSection`, and `_buildPrayerTimesList`. Should live in one place (e.g. repository or controller helper).
- **Snackbar / feedback**: Some screens still use `Get.snackbar` directly (e.g. `FamilyController.pokeMember`, `CreateFamilyScreen` flow) instead of `AppFeedback`, so messaging is inconsistent.

### Hard to maintain / brittle
- **PrayerTimeService** calculates only “today”; there is no multi-day caching or use of `DatabaseHelper.cachePrayerTimes` / `getCachedPrayerTimes`. Tomorrow’s Fajr (e.g. for “next prayer” after Isha) is not handled; `getNextPrayer` returns `null` and the dashboard comment admits “day wrap in next iteration”.
- **FamilyController** calls `_familyService.getMemberTodayLogs(userId).listen(...)` and `getMemberData(userId).listen(...)` in a loop for each member but **never stores or cancels these `StreamSubscription`s**. When the user leaves the family screen or the controller is disposed, subscriptions keep running → **memory leak** and possible updates after dispose.
- **DashboardController** has two uncancelled streams: `_prayerRepo.getTodayPrayerLogs(userId).listen(...)` and `_userRepo.getUserNotificationsStream(userId).listen(...)`. Neither is cancelled in `onClose()` → **memory leak** when the controller is disposed (e.g. logout).
- **Countdown circle** (`countdown_circle.dart`): Uses recursive `Future.delayed` instead of `Timer`. There is no `dispose`/`cancel` of the delayed chain, so if the widget is disposed quickly, callbacks can still run (mounted check helps but the chain keeps scheduling).
- **Two sync/connectivity layers**: `OfflineSyncService` still exists and is no longer used after the refactor; `SyncService` + `PrayerRepository` own sync. Dead code and confusion for future maintainers.
- **Typo in model**: `PrayerLogModel.oderId` is used consistently but is clearly a typo for `orderId` or “ownerId”; Firestore and DB use it, so renaming needs a small migration or alias.

### Controllers / disposal
- **DashboardController**: `onClose` cancels `_timer` but not the two stream subscriptions → leak.
- **FamilyController**: Disposes text controllers but does not cancel the N×2 Firestore listeners from `_loadSingleMemberData` → leak.
- **QiblaController**: Correctly cancels `_compassSubscription` in `onClose`.
- **AuthService**: `authStateChanges().listen(...)` is never cancelled. Service is permanent so not disposed, but if the app ever disposes it, that’s a leak.
- **ConnectivityService / SyncService**: Connectivity subscription is cancelled in `onClose`; SyncService does not hold a subscription (worker only).

---

## 2. Logic & Feature Gaps (Prayer-Tracking Specific)

### Missing critical logic
- **Qaza (make-up prayers)**: No concept of “missed” prayers that need to be made up later. Missed-prayers screen allows marking as “prayed” or “missed” but there is no Qaza queue, no ordering (e.g. Fajr before Dhuhr), and no UI to “complete a Qaza” and have it reflected in streak or history in a standard way.
- **Next prayer after Isha**: Logic does not wrap to next day’s Fajr. After last prayer of the day, countdown and “next prayer” break or show nothing. Requires at least tomorrow’s Fajr (and ideally a small cache of next-day times).
- **Prayer times caching**: `DatabaseHelper` has `cached_prayer_times` and `cachePrayerTimes` / `getCachedPrayerTimes` / `cleanOldPrayerTimesCache`, but **PrayerTimeService never uses them**. Every time the app opens or location changes, it recalculates; no offline cache, no “monthly fetch” strategy, and no reduction of battery/CPU for repeated calculations.
- **Daylight saving / timezone**: Adhan uses device local time; there is no explicit timezone or DST handling. For users who travel or in regions with DST, “today” and “tomorrow” boundaries could be wrong without using a proper timezone (e.g. `DateTime` in local vs UTC and consistent “start of day” in user’s location).
- **Leap years / date boundaries**: No explicit handling; reliance on `DateTime` is mostly fine, but “start of day” is done with `DateTime(year, month, day)` in several places without timezone, so edge cases (e.g. UTC vs local midnight) can cause off-by-one-day for logs or streaks.
- **Streak calculation**: In Firestore, streak is “5/5 prayers = 1 day” and iterates backwards; there is no handling of “today not finished yet” (e.g. don’t break streak until day is over). Specification says “If today isn’t finished, don’t break the streak yet” but the implementation is a simple loop; today’s partial completion could be clarified.

### Offline-sync robustness
- **Slow internet**: No timeout or retry-with-backoff per request; only queue-level backoff. A single slow Firestore write can block the whole sync loop.
- **App kill during sync**: Sync removes an item from the queue only after a successful Firestore write. If the app is killed after the write but before `removeFromSyncQueue`, the same item can be synced again on next run → **duplicate prayer log** in Firestore. No idempotency key or “sync token” to prevent duplicates.
- **Conflict resolution**: If the same user logs a prayer on two devices offline, both can sync and create two documents for the “same” prayer. No last-write-wins or merge strategy.
- **Order of sync**: Queue is processed in insert order; there is no prioritization (e.g. prayer logs before user profile updates) or dependency handling.

---

## 3. UI/UX Critic

### Jank and unnecessary rebuilds
- **Dashboard home content**: A single large `Obx` wraps the whole home body (loading, header, timeline, action, list). The countdown text updates every second (`timeUntilNextPrayer`), so **the entire subtree rebuilds every second** (header, timeline, list, buttons). That’s unnecessary work and can cause jank on low-end devices.
- **Fix**: Isolate the ticking part in a small `Obx` that only depends on `timeUntilNextPrayer` (and maybe next prayer name). Keep the rest of the dashboard outside that Obx or in separate Obx with narrower dependencies.
- **List views**: `_buildPrayerTimesList` uses `Obx` with a `ListView.builder`; that’s reasonable, but if `todayPrayers` or `todayLogs` are large and change often, consider `ListView.builder` with stable keys and avoid rebuilding the whole list for a single log change if possible.
- **Settings**: Full `Obx` around the whole list for theme/language is acceptable (changes rare); no major issue.

### General UI quality
- Many hardcoded Arabic strings in UI (e.g. “إنشاء حساب”, “إنشاء عائلة”) instead of `'key'.tr`; `rules.txt` and spec ask for all strings in values (AR/EN). Inconsistency and harder localization.
- No clear loading/skeleton states for family members or prayer timeline; empty states exist but transitions can feel abrupt.
- Accessibility: No `Semantics` or `TalkBack`/VoiceOver hints on key actions (e.g. “Log prayer”, “Qibla direction”).

### Three premium UI features to aim for
1. **Micro-animations and haptics**: Subtle success animation + light haptic when logging a prayer; small motion when streak increments or when “facing Qibla” is achieved. Makes the app feel responsive and premium.
2. **Adaptive theming and “golden hour”**: Use time-of-day (e.g. around Fajr/Maghrib) to slightly shift accent or background (warm at Maghrib, cool at Fajr). Optional “focus mode” during prayer time: dimmed UI, minimal distractions.
3. **Unified bottom sheet / overlay for “I prayed”**: Instead of only a button, a quick bottom sheet with optional “Qaza” toggle, timing quality selector, and a satisfying confirmation (e.g. short Lottie + sound). Reuse the same component from notification quick-actions for consistency.

---

## 4. Innovation & AI Suggestions (Killer Features)

1. **Smart “when to pray” personalization (AI/patterns)**  
   Use existing (or new) pattern data: time of day and day-of-week when the user usually prays. Suggest: “You usually pray Dhuhr around 13:15; you have a meeting until 13:00. Pray in the next 15 minutes?” or “Your Fajr is often 10–15 min after adhan; adhan in 20 min.” Integrate with calendar (optional) for “pray before/after this event.” No major competitor does this in a family-focused app.

2. **Family “prayer mood” and gentle nudge (AI/patterns)**  
   Aggregate family prayer times (e.g. “Dad and two kids prayed; one hasn’t”) and send one smart nudge to the remaining member (e.g. “Your family just finished Maghrib. Join them when you can.”). Optionally show a minimal “family pulse” (e.g. 4/5 prayed) without exposing exact times. Combines family accountability with privacy and encourages consistency.

---

## 5. Security & Validation

### Input validation
- **Auth**: Email validated with `GetUtils.isEmail`; password length ≥ 6. No strength check, no sanitization of display name (e.g. XSS if ever rendered in web). Firebase Auth handles injection for email/password.
- **Family**: Create family uses `familyNameController.text.trim().isEmpty`; no max length or character whitelist. Invite code is “6 chars” but not validated for type (e.g. alphanumeric). A very long name or special characters could cause odd UI or, in theory, issues in Firestore.
- **Prayer log**: Log is built server-side from trusted enums and dates; duplicate check is in app only. If someone tampers with the client, they could send invalid `prayer` or dates; Firestore rules are the last line of defense.
- **Profile**: Name and birth date are not sanitized; long strings could bloat DB or cause layout issues.

### Firebase rules
- **No `firestore.rules` (or equivalent) in the repo.** If the project uses default or console-only rules, assume the worst: any authenticated user might be able to read/write outside their document if rules are misconfigured. **Critical:** Add versioned, restrictive Firestore (and Storage) rules to the repo and deploy them (e.g. users can read/write only their own `users/{userId}` and their groups’ data, with clear conditions for `prayer_logs`, `notifications`, etc.).

### Where a user can “break” the app or data
- **Empty or huge display name** → UI overflow or empty headers.
- **Invalid or future birth date** → Streak or age-based logic could behave oddly.
- **Repeated rapid “log prayer”** → Duplicate check is in-memory (todayLogs); with slow network, double-tap could queue two logs and both sync → duplicate entries.
- **Changing device time** → Streak and “today” depend on device date/time; user could game the system or break “today” boundaries.
- **Offline + many logs + full queue** → No cap on queue size; extremely heavy offline use could cause large queues and long sync times or timeouts.

---

# Top 10 Critical Improvements (Ranked High → Low)

1. **Firebase / Firestore security rules (High)**  
   Add and maintain `firestore.rules` (and Storage rules) in the repo. Ensure users can only read/write their own user document, their prayer logs, and group data they belong to. Deploy and test. Without this, data is at risk.

2. **Fix stream subscription leaks (High)**  
   In **DashboardController**: store `StreamSubscription`s for `getTodayPrayerLogs` and `getUserNotificationsStream`, and cancel them in `onClose`. In **FamilyController**: store and cancel all subscriptions created in `_loadSingleMemberData` (e.g. a `List<StreamSubscription>` or a `CancelToken`). Prevents memory growth and use-after-dispose.

3. **Next prayer and day boundary (High)**  
   Implement “next prayer” across midnight: load or compute tomorrow’s Fajr (reuse Adhan with `DateComponents` for tomorrow). Use a single place (e.g. PrayerTimeService or a small cache) so the dashboard and notifications always have a valid next prayer and countdown.

4. **Use prayer times cache and reduce recalculations (High)**  
   Have PrayerTimeService (or a dedicated repository) use `DatabaseHelper.cachePrayerTimes` and `getCachedPrayerTimes` for a “fetch monthly/weekly + fallback to cache” strategy. On init, try cache first; refresh in background if online and cache miss or stale. Ensures offline support and better battery life.

5. **Sync idempotency and crash safety (High)**  
   Make sync safe when the app is killed mid-run: e.g. assign a client-generated UUID to each queue item and use it (or a composite key) in Firestore so duplicate sync runs do not create duplicate documents. Optionally mark documents as “synced from queue” and skip or merge duplicates. Add a simple timeout per sync item to avoid blocking the queue on slow networks.

6. **Single source of truth for prayer names (Medium)**  
   Introduce a central mapping (e.g. `PrayerNames.displayName(PrayerName)` and `PrayerNames.fromDisplayName(String)`) and use it everywhere (dashboard, cards, repo, Firestore serialization). Remove duplicated switches and string literals. Eases i18n and maintenance.

7. **Narrow Obx scope on dashboard (Medium)**  
   Replace the one big `Obx` for home content with: (a) one small `Obx` that only rebuilds the countdown (and next prayer name), and (b) other `Obx` or non-reactive widgets for the rest. Stops full-screen rebuilds every second and reduces jank.

8. **Qaza (make-up) prayer model and UI (Medium)**  
   Add a clear model for “missed” prayers that need to be made up (Qaza): store them, show a simple queue or list, and allow “completed Qaza” to update history/streak in a defined way. Even a minimal version (list + mark done) would fill a critical religious requirement.

9. **Validation and sanitization (Medium)**  
   Validate and cap all user inputs: display name and family name (max length, trim, optional character set); invite code format; birth date range. Use the same validation in UI and in repository/service before writing to Firestore. Reduces bad data and edge-case bugs.

10. **Remove dead code and clarify sync layer (Low)**  
    Delete or fully deprecate `OfflineSyncService` and any references. Document that sync is owned by `PrayerRepository` + `SyncService`. Fix or document the `oderId` typo (alias in model or a one-time migration). Improves clarity and prevents wrong usage.

---

**Next step:** When you want to start refactoring, say which item(s) from the Top 10 you want to tackle first (e.g. “Start with 1 and 2”), and we can proceed step by step.
