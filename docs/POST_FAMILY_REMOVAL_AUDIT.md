# تقرير مراجعة شاملة بعد حذف فولدر العائلة

> تاريخ: 16 شباط 2025

## 1. الوضع الحالي — ما تم حذفه

- **فولدر العائلة (family)** — محذوف بالكامل  
- **فولدر الإشعارات (notifications)** — غير موجود (أو لم يُنقل للمشروع الجديد)

---

## 2. استيرادات مكسورة — التطبيق لن يبني بدون إصلاحها

### 2.1 `injection_container.dart`

| الاستيراد | الحالة |
|----------|--------|
| `FcmService` من `features/notifications` | المجلد غير موجود |
| `FamilyService` من `features/family` | المجلد محذوف |
| `FamilyRepository` من `features/family` | المجلد محذوف |
| `AchievementRepository` من `features/family` | المجلد محذوف |

**الإجراء المطلوب:**
- إزالة تسجيل `FcmService`, `FamilyService`, `FamilyRepository`, `AchievementRepository`
- إزالة `sl<FcmService>().init()` من `initLateServices()`

### 2.2 `auth_service.dart`

- يستورد `FcmService` من `features/notifications` — غير موجود
- يستخدم `FcmService` في `_updateFcmToken()` لحفظ توكن FCM للمستخدم

**الإجراء المطلوب:**
- إزالة استيراد `FcmService`
- تعديل `_updateFcmToken()` ليعمل بدون FCM مؤقتاً (تخطي أو stub)

### 2.3 `dashboard_controller.dart`

- يستورد `FamilyService`
- يستدعي `sl<FamilyService>()` في `_addPulseIfFamily()` (حوالي السطر 330)

**الإجراء المطلوب:**
- إزالة استيراد `FamilyService`
- إزالة أو تعطيل `_addPulseIfFamily()` أو استبداله بـ `// no-op` مؤقتاً

### 2.4 `dashboard_screen.dart`

- يستورد `FamilyDashboardScreen` من `features/family`
- يعرض `FamilyDashboardScreen` كتاب ثانٍ في `IndexedStack`
- يحتوي على bottom nav بـ "home" و "family"

**الإجراء المطلوب:**
- إزالة استيراد `FamilyDashboardScreen`
- إزالة تبويب العائلة: اعرض فقط `DashboardHomeContent`
- إزالة الـ bottom navigation أو تعديله ليكون صفحة واحدة (أو استبدال تبويب العائلة بشيء آخر لاحقاً)

### 2.5 `dashboard_binding.dart`

- يستورد `FamilyController` من `features/family`
- يسجّل `FamilyController` عبر `Get.lazyPut`

**الإجراء المطلوب:**
- إزالة استيراد `FamilyController`
- إزالة `Get.lazyPut<FamilyController>(...)`

---

## 3. الأصول (Assets)

### 3.1 ما هو موجود فعلياً

| المجلد | الملفات الموجودة |
|--------|------------------|
| **animations** | Confetti.json, dadwithfatherareprayer.json, infinite_loop.json, loading.json, mosque.json, Success.json |
| **images** | empty_community.png, empty_prayers.png, kaaba.png, maghrib_prayer_bg.png, onboarding_location.png, prayer_done_celebration.png, qibla_compass.png, user_avatar_default.png |
| **icons** | salah_app_logo.png + أيقونات SVG |
| **sounds** | asrsoon.mp3, eshaasoon.mp3, fagrsoon.mp3, maghribsoon.mp3, Takbir 1.mp3, zohrsoon.mp3 |

### 3.2 ما يُشار إليه في الكود لكنه غير موجود

| المسار | المرجع |
|--------|--------|
| `assets/icons/app_icon.png` | ImageAssets.appIcon |
| `assets/images/fajr_prayer_bg.png` | ImageAssets.fajrBg |
| `assets/images/dhuhr_prayer_bg.png` | ImageAssets.dhuhrBg |
| `assets/images/asr_prayer_bg.png` | ImageAssets.asrBg |
| `assets/images/isha_prayer_bg.png` | ImageAssets.ishaBg |
| `assets/images/mosque_silhouette.png` | ImageAssets.mosqueSilhouette |
| `assets/images/onboarding_welcome.png` | ImageAssets.onboardingWelcome |
| `assets/images/onboarding_community.png` | ImageAssets.onboardingCommunity |
| `assets/animations/welcome.json` | onboarding_data.dart (خطوة welcome) |
| `assets/animations/features.json` | onboarding_data.dart (خطوة features) |
| `assets/animations/family.json` | onboarding_data.dart (خطوة family) |
| `assets/animations/location.json` | onboarding_data.dart (خطوة permissions) |
| `assets/animations/profile.json` | onboarding_data.dart (خطوة profileSetup) |
| `assets/animations/success.json` | onboarding_data, missed_prayers, stats — الملف الفعلي: `Success.json` (حرف كبير) |

### 3.3 مسارات الصوت — خطأ شائع

`SoundAssets` يرجع مسارات مثل `sounds/Takbir 1.mp3`.

في Flutter، مفتاح الـ asset يجب أن يكون المسار الكامل، أي:
- الصحيح: `assets/sounds/Takbir 1.mp3`

**الإجراء المطلوب:**
- تعديل `SoundAssets` لاستخدام البادئة `assets/sounds/` في كل المسارات.

### 3.4 ما يجب إضافته أو إصلاحه

1. **للتشغيل الفوري:**
   - إصلاح مسارات الصوت في `SoundAssets` (إضافة `assets/`)
   - إصلاح `success.json` → `Success.json` في الكود (أو إعادة تسمية الملف)
   - استخدام `salah_app_logo.png` كـ appIcon إذا لم يكن لديك `app_icon.png`

2. **للـ Onboarding:**
   - إما إضافة ملفات Lottie: welcome, features, family, location, profile, success  
   - أو تغيير الكود لاستخدام `mosque.json` / `dadwithfatherareprayer.json` كبديل لكل الخطوات.

3. **للصورة العامة (اختياري):**
   - إضافة صور صلوات: fajr, dhuhr, asr, isha (لديك maghrib فقط)  
   - إضافة mosque_silhouette إن استخدمتها الواجهات.

---

## 4. مجلد Core — ما هو ضروري ومفيد

| الملف/المجلد | الضرورة | ملاحظات |
|--------------|---------|---------|
| `constants/` | ضروري | image_assets, storage_keys, api_constants, enums, app_dimensions |
| `services/` | ضروري | storage, database, location, connectivity, sync, audio, cloudinary, shake, permission |
| `helpers/` | ضروري | prayer_names, prayer_timing_helper, hijri_date_helper, date_time_helper, image_helper, input_validators |
| `theme/` | ضروري | app_theme, app_colors, app_fonts |
| `localization/` | ضروري | ar_translations, en_translations |
| `routes/` | ضروري | app_routes, app_pages |
| `feedback/` | ضروري | app_feedback, toast_service, toast_widget, sync_status |
| `error/` | ضروري | app_logger |
| `widgets/` | ضروري | app_button, app_text_field, app_loading, empty_state, connection_status |
| `di/` | ضروري | injection_container |

كل ما في `core` مفيد في البناء الجديد ما عدا الإشارات لميزات محذوفة (Family, FCM) والتي تُصلح بإزالتها من DI والاستيرادات.

---

## 5. مجلد Shared — ما هو ضروري

| الملف | الضرورة | ملاحظات |
|------|---------|---------|
| `base_repository.dart` | ضروري | يُستخدم من PrayerRepository و UserRepository |
| `achievement_model.dart` | اختياري | كان مرتبطاً بـ AchievementRepository (محذوف) — احتفظ به إذا تخطط لإنجازات لاحقاً |
| `admin_models.dart` | اختياري | غير مستخدم حالياً — احتفظ به إذا تخطط لوحة إدارة |

---

## 6. الخدمات الأساسية المطلوبة

| الخدمة | الموقع | الحالة |
|--------|--------|--------|
| StorageService | core | يعمل |
| DatabaseHelper | core | يعمل |
| ConnectivityService | core | يعمل |
| LocationService | core | يعمل |
| AuthService | features/auth | يعمل (بعد إزالة FCM) |
| FirestoreService | features/prayer | يعمل |
| PrayerTimeService | features/prayer | يعمل |
| PrayerRepository | features/prayer | يعمل |
| UserRepository | features/auth | يعمل |
| NotificationService | features/prayer | يعمل (إشعارات محلية) |
| SyncService | core | يعمل |
| AudioService | core | يعمل (بعد إصلاح مسارات الصوت) |
| FcmService | features/notifications | محذوف — يُعاد إنشاؤه لاحقاً عند الحاجة للإشعارات عبر Firebase |
| FamilyService | features/family | محذوف — ستعيد بناؤه مع صفحة العائلة |

---

## 7. Models الضرورية

| الموديل | الموقع | الحالة |
|---------|--------|--------|
| UserModel | features/auth | يعمل |
| PrayerLogModel | features/prayer | يعمل |
| PrayerTimeModel | features/prayer | يعمل |
| LiveContextModels | features/prayer | يعمل |

---

## 8. خطوات الإصلاح المختصرة (للبدء السريع)

1. **injection_container.dart**
   - احذف استيراد وتسجيل: FcmService, FamilyService, FamilyRepository, AchievementRepository
   - احذف `sl<FcmService>().init()` من `initLateServices()`

2. **auth_service.dart**
   - احذف استيراد FcmService
   - اجعل `_updateFcmToken()` ينتهي مباشرة (مثلاً `return;` في البداية) أو أضف شرطًا يتحقق من وجود الخدمة قبل الاستخدام

3. **dashboard_controller.dart**
   - احذف استيراد FamilyService
   - احذف أو علّق `_addPulseIfFamily()` واستدعاءاتها

4. **dashboard_screen.dart**
   - احذف استيراد FamilyDashboardScreen
   - اعرض فقط `DashboardHomeContent` بدون تبويب عائلة
   - احذف الـ bottom navigation أو أبقه بدون تبويب عائلة

5. **dashboard_binding.dart**
   - احذف استيراد وتسجيل FamilyController

6. **audio_service.dart (SoundAssets)**
   - غيّر كل المسارات من `sounds/...` إلى `assets/sounds/...`

7. **onboarding_data.dart**
   - استخدم ملفات Lottie موجودة (مثل mosque.json) كبديل للناقصة، أو أضف الملفات الناقصة

8. **image_assets.dart و qibla_screen**
   - تأكد أن المسارات تطابق الملفات الموجودة (success.json vs Success.json، app_icon vs salah_app_logo إن لزم)

---

## 9. ملخص

- معظم ما في **core** و **shared** مفيد ويُبنى عليه في إعادة الهيكلة.
- الإصلاحات المطلوبة للحصول على build نظيف:
  - إزالة كل الإشارات إلى Family و Notifications/FCM من DI والـ screens والـ controller.
  - إصلاح مسارات الصوت والـ assets لتطابق الملفات الفعلية.

بعد تنفيذ هذه الخطوات ستتمكن من تشغيل التطبيق وبدء إعادة بناء صفحة العائلة والـ notifications من الصفر على أساس نظيف.
