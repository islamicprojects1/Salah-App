# برومت شامل لتطبيق Salah (صلاة) — Claude CLI

انسخ المحتوى بالكامل وألصقه في Claude CLI لتحليل وإصلاح التطبيق بالكامل.

---

## البداية

أنا أعمل على تطبيق **Salah** (صلاة) — تطبيق Flutter لتذكير الصلاة ومواقيتها والعائلة. أريد منك:

1. **قراءة هيكل المشروع والوثائق** في مجلد `docs/` وخاصة `ARCHITECTURE.md`, `EXECUTION_PLAN.md`
2. **تحليل الكود الحالي** واكتشاف الثغرات، الأخطاء، والتجربة السيئة
3. **إصلاح المشاكل** حسب الأولوية التالية
4. **احترام المعايير** الموضحة أدناه

---

## هيكل المشروع

```
lib/
├── main.dart              # Entry point, initInjection
├── app.dart               # GetMaterialApp, theme, routes
├── core/                  # Shared infrastructure
│   ├── constants/         # API, dimensions, enums, storage_keys
│   ├── di/                # GetIt (sl) + GetX bindings (injection_container.dart)
│   ├── error/             # AppLogger
│   ├── feedback/          # AppFeedback, ToastService
│   ├── localization/      # ar_translations, en_translations, languages
│   ├── middleware/        # Route guards (onboarding)
│   ├── routes/            # AppPages, AppRoutes
│   ├── services/          # StorageService, LocationService, SyncService, etc.
│   ├── theme/             # AppColors, AppFonts, AppTheme
│   └── widgets/           # AppButton, AppLoading, EmptyState
├── features/
│   ├── auth/              # Login, Register, ProfileSetup, AuthController
│   ├── family/            # Family dashboard, create/join, FamilyController
│   ├── onboarding/        # Welcome, Features, Permissions, ProfileSetup
│   ├── prayer/            # Dashboard, Qibla, MissedPrayers, PrayerTimeService
│   ├── profile/           # ProfileController
│   ├── settings/          # SettingsController, SelectedCityController
│   └── splash/            # SplashScreen
```

---

## التقنيات المستخدمة

- **Flutter** (SDK ^3.10.7)
- **GetX** — state management, routing, bindings
- **GetIt** — dependency injection (`sl<T>()`)
- **Firebase** — Auth, Firestore, FCM
- **Geolocator** — الموقع
- **permission_handler** — أذونات النظام
- **flutter_local_notifications** — إشعارات محلية
- **ترجمة ثنائية اللغة** — عربي (افتراضي) وإنجليزي عبر `'key'.tr`

---

## قواعد يجب اتباعها

1. **AppFeedback** — استخدم `AppFeedback.showSuccess`, `showError`, `showSnackbar` لجميع رسائل المستخدم. لا تستخدم `Get.snackbar` أو `Get.dialog` مباشرة.
2. **AppLogger** — استخدم `AppLogger.error`, `AppLogger.warning` في catch داخل الخدمات والمستودعات.
3. **الترجمة** — أضف أي نص جديد في `ar_translations.dart` و `en_translations.dart`.
4. **GetIt** — الخدمات والمستودعات تُستدعى عبر `sl<T>()` وليس `Get.find<T>()` إلا للـ Controllers (GetX bindings).
5. **Obx** — استخدم `Obx` فقط حول الـ widget الذي يعتمد على observable لتقليل إعادة البناء.
6. **RTL** — التطبيق يدعم العربية والإنجليزية. استخدم `Directionality(textDirection: TextDirection.ltr)` للعناصر ذات اتجاه ثابت (مثل أزرار العلامات التجارية).

---

## مشاكل معروفة ويجب إصلاحها (حسب الأولوية)

### 1. المصادقة (Auth)
- **Google Sign-In**: إذا ظهر `DEVELOPER_ERROR`، السبب عادة عدم إضافة SHA-1 في Firebase Console (راجع `docs/GOOGLE_SIGNIN_FIX.md`).
- **زر Google Sign-In**: كان يظهر "(" بدل الشعار والنص — تم إصلاحه بـ `Directionality(textDirection: TextDirection.ltr)`.
- **عرض الأخطاء**: تأكد أن رسائل الخطأ تظهر للمستخدم عبر `AppFeedback.showError` عند فشل تسجيل الدخول (بريد أو Google).

### 2. الموقع والأذونات (Location & Permissions)
- **Onboarding**: طلب الموقع والإشعارات معاً — البطاقات قابلة للنقر، والزر الرئيسي يطلب كليهما بالتسلسل. فحص الحالة يستخدم `Geolocator.checkPermission()` و `Permission.notification.status`.
- **عدم إعادة الطلب**: إذا رفض المستخدم الموقع في Onboarding، لا تُطلب مرة ثانية تلقائياً (`locationSkippedInOnboarding` في Storage).
- **زر "استخدم موقع الجهاز"**: في شاشة اختيار المدينة — تأكد أنه يعمل ويُظهر feedback واضح عند النجاح/الفشل.

### 3. Dashboard و SliverFillRemaining
- **LayoutBuilder داخل SliverFillRemaining** يسبب crash: `LayoutBuilder does not support returning intrinsic dimensions`. استُبدل بـ `SliverToBoxAdapter` + `SizedBox` بارتفاع ثابت.
- تأكد أن `SmartPrayerCircle` يعمل بدون أخطاء layout.

### 4. الخروج (Logout)
- عند تسجيل الخروج، إلغاء Firestore streams (notifications, prayer_logs, family) قبل `signOut` لتجنب `permission-denied` بعد الخروج.

### 5. العائلة (Family)
- **GetX improper use**: لا تقرأ `controller.isAdmin` داخل `itemBuilder` — اقرأها داخل `build` قبل إرجاع الـ widget.
- ربط تسجيل الصلاة مع `FamilyController.onPrayerLogged()` عند الحاجة.

### 6. الإشعارات
- جدولة الإشعارات من مصدر واحد (DashboardController أو NotificationScheduler) مع احترام إعداد كل صلاة.
- عند رفض صلاحية الإشعارات، عرض رسالة مرة واحدة مع زر لفتح إعدادات التطبيق.

### 7. التخزين والمزامنة
- عند حفظ صلاة بدون إنترنت: عرض "تم الحفظ. سيتم المزامنة عند عودة الاتصال." (`saved_will_sync_later`).
- عند فشل المزامنة: تسجيل الخطأ + Toast `sync_failed_retry`.
- مؤشر الاتصال (ConnectionStatusIndicator) في Dashboard.

---

## أولوية التنفيذ

1. **حرجة (Critical)**: Auth (تسجيل الدخول والخروج)، Dashboard crash، أذونات Onboarding
2. **مهمة (High)**: الموقع، اختيار المدينة، الإشعارات
3. **متوسطة (Medium)**: العائلة، المزامنة، رسائل المستخدم
4. **منخفضة (Low)**: تحسينات UI، ويدجت الشاشة الرئيسية (غير مُنفَّذ بعد)

---

## ملفات وثائق مهمة

- `docs/ARCHITECTURE.md` — البنية والمعايير
- `docs/EXECUTION_PLAN.md` — خطة التنفيذ والحالة
- `docs/GOOGLE_SIGNIN_FIX.md` — إصلاح Google Sign-In
- `docs/ONBOARDING_PERMISSIONS_STUDY.md` — منطق أذونات Onboarding
- `docs/RELEASE_CHECKLIST_BETA.md` — قائمة التحقق قبل الإصدار

---

## المطلوب منك

1. **ابدأ بتحليل المشروع**: اقرأ `docs/ARCHITECTURE.md` و `main.dart` و `app.dart` و `injection_container.dart`.
2. **حدد المشاكل**: راجع الكود في `features/` واكتشف bugs، edge cases، وتجربة مستخدم سيئة.
3. **أصلح حسب الأولوية**: ابدأ بالمشاكل الحرجة (Auth، Dashboard crash، Onboarding).
4. **ثبّت التغييرات**: تأكد أن التطبيق يعمل بعد كل تعديل عبر `flutter analyze` واختبار يدوي إن أمكن.
5. **وثّق التغييرات**: أضف تعليقات موجزة أو وثائق عند إصلاح مشكلة معقدة.

---

## ملاحظات إضافية

- التطبيق مكتوب بالعربية والإنجليزية. معظم التعليقات والوثائق عربية.
- دعم RTL: اللغة العربية تعرض من اليمين لليسار.
- الخطوط: Tajawal (عربي)، Poppins (إنجليزي).
- الثيم: فاتح/داكن/نظام (AppColors, AppTheme).
