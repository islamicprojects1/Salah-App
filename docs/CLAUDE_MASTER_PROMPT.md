# CLAUDE_MASTER_PROMPT.md
> وثيقة مرجعية شاملة لمساعد الذكاء الاصطناعي — اقرأها أولاً في كل جلسة عمل.
> آخر تحديث: فبراير 2026

---

## 1. فهم التطبيق وهدفه

### الاسم والهوية
- **الاسم المستهدف**: Qurb (قُرب) — ربط المسلمين حول الصلاة
- **الاسم الحالي في المتجر**: صلاة (Salah)
- **المستودع**: `c:\development\Salah-App`
- **الفرع الرئيسي**: `main` | **الفرع الحالي**: `feature/many`

### رؤية التطبيق
تطبيق Flutter إسلامي يُمكّن المسلمين من:
1. **تتبع الصلوات** — تسجيل الصلوات الخمس يومياً مع جودة التوقيت
2. **المحاسبة العائلية** — ربط أفراد الأسرة لمتابعة المسيرة الصلاتية بشكل جماعي
3. **الاسترداد** — تتبع صلوات القضاء والتشجيع على أدائها
4. **الإشعارات الذكية** — أذان، تذكير قبل الصلاة، تشجيع عائلي

### المستخدم المستهدف
مسلم عربي يريد أن يصلي في وقتها وأن يرى عائلته تصلي معه. التطبيق لا يُدين، بل يُشجع ويُرافق.

---

## 2. البنية التقنية الكاملة

### Stack التقني
| الطبقة | التقنية |
|--------|---------|
| UI | Flutter + Material 3 |
| State Management | GetX (Rx, Controller, Service, Binding) |
| Dependency Injection | GetIt (service locator) |
| Cloud Database | Firebase Firestore |
| Authentication | Firebase Auth (Email + Google) |
| Push Notifications | Firebase Messaging (FCM) |
| Local Database | SQLite (sqflite) |
| Local Storage | GetStorage (key-value) |
| Prayer Times API | Aladhan API (HTTP) |
| Location | Geolocator + Nominatim (reverse geocoding) |
| Images | Cloudinary (CDN) |
| Notifications | flutter_local_notifications |
| Compass | flutter_compass (Qibla) |
| Animations | Lottie |
| Audio | audioplayers (Adhan) |

### بنية المجلدات

```
lib/
├── main.dart                    # Entry point: Firebase init, DI, orientation
├── app.dart                     # GetMaterialApp root, theme/locale reactive
├── core/
│   ├── constants/
│   │   ├── api_constants.dart   # Firestore paths, channel IDs, timeouts
│   │   ├── aladhan_constants.dart # Country→MethodID mapping (40+ countries)
│   │   ├── enums.dart           # 30+ enums (PrayerName, PrayerTimingQuality, ...)
│   │   ├── storage_keys.dart    # 40+ typed keys for GetStorage
│   │   ├── app_dimensions.dart  # Spacing, breakpoints, border radius
│   │   └── image_assets.dart    # Asset paths centralized
│   ├── di/
│   │   └── injection_container.dart  # GetIt registration (190+ lines)
│   ├── error/
│   │   └── app_logger.dart      # 4-level logger (debug/info/warning/error)
│   ├── feedback/
│   │   ├── app_feedback.dart    # Haptics + toasts + dialogs
│   │   ├── toast_service.dart   # Overlay-based toasts
│   │   ├── toast_widget.dart    # Animated toast UI
│   │   └── sync_status.dart     # SyncState observable
│   ├── helpers/
│   │   ├── date_time_helper.dart     # Gregorian formatting, cache keys
│   │   ├── hijri_date_helper.dart    # Hijri conversion, Ramadan detection
│   │   ├── prayer_names.dart         # Single source: PrayerName↔Display
│   │   ├── prayer_timing_helper.dart # Quality→Color/Icon/Label mapping
│   │   ├── input_validators.dart     # (sanitisedValue, error?) records
│   │   └── image_helper.dart         # Provider resolution, build widget
│   ├── localization/
│   │   ├── languages.dart        # GetX Translations registry
│   │   ├── ar_translations.dart  # Arabic strings map
│   │   └── en_translations.dart  # English strings map
│   ├── middleware/
│   │   └── onboarding_middleware.dart # Route guard for onboarding
│   ├── routes/
│   │   ├── app_routes.dart       # String constants for routes
│   │   └── app_pages.dart        # GetPage definitions with bindings
│   ├── services/
│   │   ├── storage_service.dart       # GetStorage wrapper
│   │   ├── database_helper.dart       # SQLite init, CRUD, sync queue
│   │   ├── connectivity_service.dart  # Network status (reactive)
│   │   ├── location_service.dart      # GPS + city lookup
│   │   └── cloudinary_service.dart    # Image upload/optimize
│   ├── theme/
│   │   ├── app_colors.dart       # Color palette (Islamic green + gold)
│   │   ├── app_fonts.dart        # Tajawal (AR) + Poppins (EN) typography
│   │   └── app_theme.dart        # Light/dark ThemeData
│   └── widgets/
│       ├── app_button.dart       # Primary/outlined/text/destructive
│       ├── app_text_field.dart   # Input field with validation
│       ├── app_dialog.dart       # Dialog wrapper
│       ├── app_dialogs.dart      # Loading/confirmation dialogs
│       ├── app_loading.dart      # Progress indicator
│       ├── connection_status_indicator.dart
│       └── empty_state.dart
│
├── features/
│   ├── auth/                    # Email + Google sign-in
│   ├── prayer/                  # Core: times, logging, streaks, Qibla
│   ├── family/                  # Groups: create, join, pulse, member cards
│   ├── onboarding/              # Welcome → Features → Permissions → Profile
│   ├── settings/                # Theme, language, notifications, calc method
│   ├── shell/                   # Main shell with bottom nav tabs
│   ├── profile/                 # User profile + photo
│   ├── stats/                   # Heatmap, streaks, completion %
│   └── splash/                  # Loading screen
│
└── shared/
    └── data/
        ├── models/              # AchievementModel, AdminModels
        └── repositories/
            └── base_repository.dart
```

### تدفق التطبيق
```
Splash → [check onboarding]
    ├── لم يُكمل → Onboarding (Welcome→Features→Permissions→ProfileSetup)
    │                    ↓
    └── أكمل → [check auth]
                   ├── غير مسجل → Login/Register
                   └── مسجل → MainShell (Dashboard | Family tabs)
```

---

## 3. قواعد العمل الصارمة

> **هذه القواعد غير قابلة للكسر في هذا المشروع. أي كود يخالفها يجب تصحيحه.**

### Q1 — التغذية الراجعة للمستخدم: استخدم `AppFeedback` فقط
```dart
// ✅ صح
AppFeedback.showSuccess('prayer_logged'.tr);
AppFeedback.showError('network_error'.tr);

// ❌ خطأ
Get.snackbar('title', 'message');
ScaffoldMessenger.of(context).showSnackBar(...);
print('error occurred');
```

### Q2 — التسجيل: استخدم `AppLogger` فقط
```dart
// ✅ صح
AppLogger.info('DashboardController: prayer logged');
AppLogger.error('PrayerRepository: sync failed', error, stackTrace);

// ❌ خطأ
print('something');
debugPrint('debug info');
```

### Q3 — الترجمة: جميع النصوص الظاهرة للمستخدم عبر `.tr`
```dart
// ✅ صح
Text('prayer_fajr'.tr)
AppFeedback.showSuccess('streak_updated'.tr)

// ❌ خطأ
Text('الفجر')
Text('Fajr Prayer')
```

### Q4 — الـ DI: الفصل بين `GetIt.I<T>()` و `Get.find<T>()`
- **GetxService** (يعيش طوال التطبيق): سجّله في `GetIt` واستخدم `GetIt.I<T>()`
- **GetxController** (مرتبط بـ route): سجّله في `Binding` واستخدم `Get.find<T>()`
```dart
// ✅ صح — service
final auth = GetIt.I<AuthService>();

// ✅ صح — controller
final ctrl = Get.find<DashboardController>();
```

### Q5 — UI Constants: استخدم `AppColors`, `AppFonts`, `AppDimensions`
```dart
// ✅ صح
Container(
  color: AppColors.primary,
  padding: EdgeInsets.all(AppDimensions.md),
  child: Text('label', style: AppFonts.bodyMedium),
)

// ❌ خطأ
Container(color: Color(0xFF1B5E20), padding: EdgeInsets.all(16))
```

### Q6 — أسماء الصلوات: استخدم `PrayerName` enum فقط
```dart
// ✅ صح
final name = PrayerName.fajr;
PrayerNamesHelper.getArabicName(name);

// ❌ خطأ
final name = 'Fajr';
final name = 'fajr';
```

### Q7 — Scope of Obx: ضيّق نطاق Obx قدر الإمكان
```dart
// ✅ صح — only rebuilds the Text
Obx(() => Text(controller.currentStreak.value.toString()))

// ❌ خطأ — rebuilds entire screen
Obx(() => Scaffold(body: Column(children: [...])))
```

### Q8 — Dispose: ألغِ الاشتراكات في onClose
```dart
// ✅ يجب تنفيذه في كل controller
@override
void onClose() {
  _timer?.cancel();
  _subscription?.cancel();
  super.onClose();
}
```

---

## 4. المشاكل المكتشفة — مرتبة بالأولوية

### 🔴 P0 — حرج / يؤثر على البيانات والأمان

| # | المشكلة | الملف | التأثير |
|---|---------|-------|---------|
| 1 | **تايبو `oderId`** بدلاً من `userId` في `PrayerLogModel` | `prayer_log_model.dart` | كل سجلات الصلاة مرتبطة بـ field مكسور |
| 2 | **Stream subscription leaks** في DashboardController و FamilyController | `dashboard_controller.dart` | تسرب ذاكرة، crashes بعد فترة |
| 3 | **FCM غير مفعّل فعلياً** — `subscribeToFamily()` لا يُستدعى أبداً، Server Key مفقود | `family_controller.dart`, `fcm_service.dart` | الإشعارات العائلية لا تعمل |
| 4 | **Family feature محذوفة** — لا يوجد `FamilyService` فعلياً | `features/family/` | الشاشة الرئيسية الثانية للتطبيق مكسورة |
| 5 | **Google Sign-In يفشل** — SHA-1 غير مضاف في Firebase Console | `google-services.json` | Google Sign-in لا يعمل في release |

### 🟠 P1 — عالي / يؤثر على تجربة المستخدم

| # | المشكلة | الملف | التأثير |
|---|---------|-------|---------|
| 6 | **فحص الاتصال غير دقيق** — يفحص WiFi وليس الإنترنت الفعلي | `connectivity_service.dart` | يعتقد أن هناك اتصال بينما لا يوجد |
| 7 | **`PrayerQuality` enum قديم** لا يزال مستخدماً رغم التعليم بـ @Deprecated | متعدد | تناقض في تمثيل جودة الصلاة |
| 8 | **رسائل الخطأ في Auth مكتوبة بشكل مباشر** وليس عبر مفاتيح ترجمة | `auth_error_messages.dart` | لا تتغير مع تغيير اللغة |
| 9 | **prayer offsets مخزنة بـ String key** بدلاً من `PrayerName` enum | `user_model.dart`, `settings_controller.dart` | احتمال خطأ إملائي يكسر الإعداد |
| 10 | **معالجة حدود اليوم في الصلاة التالية** — مشكلة عند منتصف الليل (بعد العشاء ماذا يعرض؟) | `live_context_service.dart`, `dashboard_controller.dart` | التطبيق يعرض بيانات خاطئة ليلاً |
| 11 | **Onboarding يحتوي صفحة Family** (صفحة 3) لم تعد في الـ spec | `onboarding_controller.dart` | تجربة تهيئة غير مكتملة |
| 12 | **AppLogger لا يُرسل للـ Crashlytics** في release | `app_logger.dart` | لا رؤية على الأخطاء في الإنتاج |

### 🟡 P2 — متوسط / يؤثر على قابلية الصيانة

| # | المشكلة | الملف | التأثير |
|---|---------|-------|---------|
| 13 | **DI container ضخم** (190+ سطر) بدون code generation | `injection_container.dart` | صعب القراءة والصيانة |
| 14 | **أسماء routes مكررة** (`createFamily` = `createGroup`, `joinFamily` = `joinGroup`) | `app_routes.dart` | ارتباك في التنقل |
| 15 | **تناقض camelCase/snake_case** في Firestore fields | models متعددة | صعوبة في التتبع |
| 16 | **رسائل خطأ عامة** للمستخدم لا تحدد سبب الفشل | متعدد | تجربة مستخدم ضعيفة |
| 17 | **الـ README ملف Flutter boilerplate** وليس توثيقاً للمشروع | `README.md` | يُشوّش المطورين الجدد |
| 18 | **Admin succession** غير محدد — ماذا لو غادر admin المجموعة؟ | family models | مجموعات عالقة بدون admin |
| 19 | **invite code لا ينتهي** — يمكن إساءة الاستخدام | `group_model.dart` | أمان المجموعات |
| 20 | **Shadow member migration** — مسار التحويل من عضو وهمي لحقيقي غير موجود | family feature | الفكرة موثقة لكن غير منفذة |

### 🔵 P3 — منخفض / تحسينات

| # | المشكلة | الملف | التأثير |
|---|---------|-------|---------|
| 21 | **Mecca hardcoded** كـ fallback في LocationService | `location_service.dart` | ليس مثالياً للمستخدمين البعيدين |
| 22 | **لا يوجد unit tests** | `test/` | لا حماية من regression |
| 23 | **Toast retry logic** هش — يؤجل إطاراً واحداً | `toast_service.dart` | قد يفشل في screens معقدة |
| 24 | **صلوات الفجر لليوم التالي** — قد تُحسب خاطئة في ربط streak | `firestore_service.dart` | streak يبدو مكسوراً |
| 25 | **لا code generation** (freezed, json_serializable) — serialization يدوي | كل models | احتمال أخطاء يدوية |

---

## 5. المعايير والقواعد المعمارية

### Clean Architecture (بترتيب الطبقات)
```
Presentation (Screen/Widget/Controller)
    ↓ يستدعي
Data (Repository/Service)
    ↓ يستدعي
Core (Helpers/Constants/DI)
```
**القاعدة**: لا يستدعي Core أي Feature. لا يستدعي Data طبقة Presentation.

### نمط Repository (Offline-First)
```dart
Future<bool> addPrayerLog(PrayerLogModel log) async {
  // 1. حفظ محلياً فوراً (optimistic update)
  await _db.insertPrayerLog(log);

  // 2. محاولة Sync للـ Firestore
  if (_connectivity.isConnected) {
    try {
      await _firestore.addPrayerLog(log);
      return true; // synced
    } catch (e) {
      await _queueForSync(log); // queue for later
      return false;
    }
  } else {
    await _queueForSync(log);
    return false;
  }
}
```

### نمط Controller (GetX)
```dart
class FeatureController extends GetxController {
  // ✅ الـ services تُحقن من GetIt
  final _service = GetIt.I<FeatureService>();

  // ✅ كل state مرصود
  final isLoading = false.obs;
  final data = Rxn<DataModel>();

  @override
  void onInit() {
    super.onInit();
    _loadData();
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
```

### نمط Binding
```dart
class FeatureBinding extends Bindings {
  @override
  void dependencies() {
    // Controller فقط — Services في GetIt
    Get.lazyPut(() => FeatureController());
  }
}
```

### تسجيل الـ DI (injection_container.dart)
```dart
// GetxService (يعيش طوال التطبيق)
sl.registerLazySingleton<MyService>(() => MyService(
  dep: sl<AnotherService>(),
));

// لا تسجل Controllers هنا — في Binding فقط
```

---

## 6. نماذج البيانات الأساسية

### UserModel (أهم model)
```
id, name, birthDate, gender, email, photoUrl, language
currentStreak, longestStreak, totalPrayers, lastPrayerAt
familyId, groupIds[], role, isParent
notificationsEnabled, [fajr/dhuhr/asr/maghrib/isha]NotifEnabled
reminderEnabled, familyNotificationsEnabled
calculationMethod (enum), madhab (shafi/hanafi)
latitude, longitude, cityName (nullable)
userPrivacySettings
prayerOffsets: Map<String, int>  ← مشكلة: يجب أن يكون Map<PrayerName, int>
```

### PrayerLogModel
```
id, oderId (← تايبو! يجب userId), prayer (PrayerName enum)
prayedAt, adhanTime, quality (@Deprecated), timingQuality
addedByLeaderId, note
```

### GroupModel
```
groupId, name, type (family/guided/friends)
inviteCode, createdAt, createdBy, adminId
lastAdminActivity, blockedUserIds[], memberIds[], memberCount
```

---

## 7. خريطة الخدمات

| الخدمة | الحالة | المسؤولية |
|--------|--------|-----------|
| `AuthService` | ✅ مكتمل | Firebase Auth wrapper |
| `FirestoreService` | ✅ مكتمل | Firestore CRUD |
| `StorageService` | ✅ مكتمل | GetStorage wrapper |
| `DatabaseHelper` | ✅ مكتمل | SQLite: prayer logs, sync queue |
| `ConnectivityService` | ⚠️ جزئي | فحص شبكة (ليس إنترنت فعلي) |
| `LocationService` | ✅ مكتمل | GPS + reverse geocoding |
| `PrayerTimeService` | ✅ مكتمل | Aladhan API + cache + offsets |
| `AladhanApiService` | ✅ مكتمل | HTTP client للـ Aladhan API |
| `LiveContextService` | ✅ مكتمل | Current prayer + countdown |
| `NotificationService` | ✅ مكتمل | Local notifications |
| `NotificationScheduler` | ✅ مكتمل | Schedule adhan + reminders |
| `SmartNotificationService` | ✅ مكتمل | Smart reminder logic |
| `PrayerLogger` | ✅ مكتمل | Log prayer + quality calculation |
| `QadaDetectionService` | ✅ مكتمل | Detect missed prayers |
| `SyncService` | ✅ مكتمل | Sync queue management |
| `ThemeService` | ✅ مكتمل | Light/dark theme |
| `LocalizationService` | ✅ مكتمل | AR/EN switching |
| `CloudinaryService` | ✅ مكتمل | Image upload |
| `FamilyService` | ❌ **مفقود** | Group CRUD + pulse events |
| `FcmService` | ⚠️ جزئي | FCM — Server key مفقود |

---

## 8. الـ Routes الكاملة

```dart
/splash              → SplashScreen (fade)
/onboarding          → OnboardingScreen (4 صفحات)
/login               → LoginScreen
/register            → RegisterScreen
/profile-setup       → ProfileSetupScreen
/dashboard           → MainShellScreen (middleware: OnboardingMiddleware)
  ├── tab 0: DashboardHomeContent (prayer times + logging)
  └── tab 1: FamilyScreen (groups + pulse)
/family/create       → CreateGroupScreen
/family/join         → JoinGroupScreen
/settings            → SettingsScreen
/settings/select-city → SelectCityScreen
/settings/prayer-adjustment → PrayerAdjustmentScreen
/settings/privacy    → PrivacySettingsScreen
/profile             → ProfileScreen
/missed-prayers      → MissedPrayersScreen
/stats               → StatsScreen
/qibla               → QiblaScreen
```

---

## 9. خطة العمل

### المرحلة 1: إصلاحات حرجة (P0) — أولوية مطلقة

**1.1 — إصلاح تايبو `oderId`**
```
الملفات: prayer_log_model.dart, database_helper.dart, prayer_repository.dart, firestore_service.dart
الخطوات:
  1. أضف getter userId يرجع oderId (backward compat)
  2. في SQLite: أضف migration لإضافة عمود userId
  3. في fromFirestore: اقرأ userId مع fallback لـ oderId
  4. في toFirestore: اكتب userId (وليس oderId)
  5. أبقِ oderId في الـ write للتوافقية مؤقتاً
```

**1.2 — إصلاح Stream Leaks**
```
الملفات: dashboard_controller.dart, family_controller.dart
الإصلاح:
  StreamSubscription? _prayerSub;
  _prayerSub = stream.listen(handler);

  @override
  void onClose() {
    _prayerSub?.cancel();
    super.onClose();
  }
```

**1.3 — تفعيل FCM**
```
الملفات: fcm_service.dart, family_controller.dart
الخطوات:
  1. الحصول على Server Key من Firebase Console
  2. تفعيل subscribeToFamily() عند الانضمام لمجموعة
  3. التحقق من Cloud Function (functions/index.js)
```

**1.4 — إصلاح Google Sign-In**
```
الخطوات:
  1. تشغيل get_sha1.bat (موجود في المشروع) للحصول على SHA-1
  2. إضافة SHA-1 في Firebase Console → Project Settings → Android App
  3. تحميل google-services.json الجديد
```

---

### المرحلة 2: استقرار (P1)

**2.1 — فحص إنترنت حقيقي**
```dart
// في connectivity_service.dart
Future<bool> hasRealInternetAccess() async {
  try {
    final result = await http.get(
      Uri.parse('https://www.google.com'),
    ).timeout(Duration(seconds: 5));
    return result.statusCode == 200;
  } catch (_) {
    return false;
  }
}
```

**2.2 — ترحيل PrayerQuality → PrayerTimingQuality**
```
البحث عن: PrayerQuality (ليس @Deprecated class نفسه)
التغيير: استخدم PrayerTimingQuality في كل مكان
الملفات: prayer_log_model.dart, prayer_logger.dart, missed_prayers UI
```

**2.3 — إصلاح معالجة منتصف الليل**
```
المشكلة: بعد صلاة العشاء، التطبيق لا يعرض صلاة الفجر للغد بشكل صحيح
الإصلاح في: live_context_service.dart
  - إذا انتهت كل صلوات اليوم، احضر فجر الغد وأعرضه كالصلاة التالية
```

**2.4 — تصحيح Onboarding**
```
المشكلة: الـ controller يحتوي صفحة Family (page 3) لم تعد في الـ spec
الإصلاح في: onboarding_controller.dart
  - حذف صفحة Family من التدفق
  - تعديل pageCount من 5 إلى 4
```

**2.5 — ربط AppLogger بـ Crashlytics**
```dart
// في app_logger.dart - الـ TODO الموجود
static void _onRelease(String level, String message, Object? error) {
  FirebaseCrashlytics.instance.recordError(
    error ?? message,
    null,
    reason: '[$level] $message',
  );
}
```

---

### المرحلة 3: بناء Family Feature

**3.1 — إنشاء FamilyService**
```
المسؤوليات:
  - CRUD للمجموعات (createGroup, joinGroup, leaveGroup)
  - إدارة الأعضاء (addMember, removeMember, promoteMember)
  - Pulse events (addPulseEvent, subscribeToPulse)
  - Family summary (aggregated prayer stats)
```

**3.2 — ربط FCM بالمجموعة**
```
عند createGroup: subscribeToTopic('family_${groupId}')
عند joinGroup: subscribeToTopic('family_${groupId}')
عند leaveGroup: unsubscribeFromTopic('family_${groupId}')
```

**3.3 — Family Screen الكاملة**
```
المكونات:
  ├── Header: اسم المجموعة + عدد الأعضاء
  ├── Summary Card: X/Y صلّوا اليوم (privacy-first)
  ├── Pulse Feed: آخر الأحداث (logged prayer, encouragement)
  ├── Member List: كل عضو + streak + حالة اليوم
  └── Actions: دعوة عضو، شارك رابط، إعدادات المجموعة
```

**3.4 — Admin Succession**
```dart
// عند مغادرة admin
if (leavingUser.id == group.adminId) {
  final nextAdmin = members
    .where((m) => m.userId != leavingUser.id)
    .sortedBy((m) => m.joinedAt)
    .firstOrNull;
  if (nextAdmin != null) {
    await updateGroupAdmin(groupId, nextAdmin.userId);
  } else {
    await deleteGroup(groupId); // آخر عضو يغادر
  }
}
```

---

### المرحلة 4: جودة وصيانة (P2/P3)

**4.1 — تنظيف Route Names**
```
// في app_routes.dart — حذف المكررات
// createFamily == createGroup → احتفظ بـ createGroup فقط
// joinFamily == joinGroup → احتفظ بـ joinGroup فقط
```

**4.2 — إضافة Unit Tests**
```
الأولويات:
  - test/helpers/prayer_timing_helper_test.dart
  - test/helpers/date_time_helper_test.dart
  - test/helpers/input_validators_test.dart
  - test/repositories/prayer_repository_test.dart (mocked)
```

**4.3 — تحسين رسائل الخطأ**
```dart
// تصنيف الأخطاء بدلاً من رسالة عامة
if (e is SocketException) return 'no_internet'.tr;
if (e is TimeoutException) return 'request_timeout'.tr;
if (e is FirebaseException) return 'server_error'.tr;
return 'unexpected_error'.tr;
```

---

## 10. مرجع سريع للملفات المهمة

| عند الحاجة لـ | الملف |
|--------------|-------|
| إضافة route جديد | `core/routes/app_routes.dart` + `app_pages.dart` |
| إضافة string للترجمة | `core/localization/ar_translations.dart` + `en_translations.dart` |
| إضافة service جديد | `core/di/injection_container.dart` |
| إضافة storage key | `core/constants/storage_keys.dart` |
| إضافة Firestore collection | `core/constants/api_constants.dart` |
| عرض toast/error | `AppFeedback.show*()` |
| تسجيل خطأ | `AppLogger.error()` |
| حساب وقت الصلاة | `features/prayer/data/services/prayer_time_service.dart` |
| تسجيل صلاة | `features/prayer/data/services/prayer_logger.dart` |
| قراءة/كتابة Firestore | `features/prayer/data/services/firestore_service.dart` |
| قراءة/كتابة SQLite | `core/services/database_helper.dart` |
| إعدادات المستخدم | `features/auth/data/models/user_model.dart` |

---

## 11. هيكل Firestore

```
users/{userId}
  prayer_logs/{logId}
  notifications/{notifId}
  achievements/{achievementId}

groups/{groupId}
  members (subcollection)

families/{familyId}
  pulse/{pulseId}  ← تُطلق Cloud Function → FCM

achievements/{achievementId}  (read-only reference)
analytics/{analyticsId}
reactions/{reactionId}
```

---

## 12. ملاحظات للجلسات القادمة

1. **ابدأ دائماً** بقراءة هذا الملف قبل أي تعديل
2. **تحقق من docs/** إذا كان هناك مستند خاص بالميزة (`SYNC.md`, `FAMILY_GROUPS_SPEC.md`, إلخ)
3. **لا تكسر الـ offline-first pattern** — دائماً احفظ محلياً أولاً
4. **المستخدم يتحدث العربية** — كل رسائل UI يجب أن تكون عبر `.tr`
5. **الفرع `feature/many`** هو الفرع الحالي للتطوير
6. **التطبيق في beta** — نسخة `1.0.0+1`

---

*هذا الملف يُحدَّث بعد كل جلسة عمل مهمة.*