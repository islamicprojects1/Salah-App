# خطة الميزة الأساسية: الداشبورد وتجربة الصلاة

> بعد إنجاز ريفاكتور Constants و Auth و Onboarding — هذه هي الميزة التالية لتغطيتها بشكل كامل.

**الميزة:** الداشبورد (الشاشة الرئيسية) + تجربة الصلاة الأساسية  
**الحالة:** موجودة — نُحسّنها ونوحّد استخدام Constants والخدمات  
**الهدف:** تجربة داشبورد احترافية، بدون قيم ثابتة، مع استغلال كامل للخدمات

---

## 1. نطاق الميزة

### ما يشمله هذا الرفاكتور

| المكون | الملفات | الخدمات المستخدمة |
|--------|---------|-------------------|
| **Dashboard Screen** | `dashboard_screen.dart` | DashboardController |
| **Dashboard Content** | `dashboard_home_content.dart` | LiveContextService, PrayerTimeService, QadaDetectionService |
| **App Bar** | `dashboard_app_bar.dart` | LocationService, currentCity |
| **Smart Prayer Circle** | `smart_prayer_circle.dart` | LiveContextService, PrayerRepository |
| **Daily Review Card** | `daily_review_card.dart` | LiveContextService, todayLogs |
| **Progress Widgets** | `dashboard_progress_widgets.dart` | todayLogs, todayPrayers |
| **Qada Button & Bottom Sheet** | `qada_review_bottom_sheet.dart`, `_QadaReviewButton` | QadaDetectionService, PrayerRepository |
| **Location Hint** | `LocationHintBanner` | LocationService.isUsingDefaultLocation |
| **Connection Status** | `connection_status_indicator.dart` | ConnectivityService |
| **Drawer** | `drawer.dart`, `drawer_parts.dart` | Auth, Storage, Routes |
| **Missed Prayers Screen** | `missed_prayers_screen.dart` | MissedPrayersController, QadaDetectionService |

### الخدمات المرتبطة (يجب استخدامها بشكل صحيح)

- `LiveContextService` — الصلاة الحالية، العد التنازلي، ملخص اليوم
- `PrayerRepository` — تسجيل صلاة، todayLogs
- `PrayerTimeService` — مواقيت اليوم
- `QadaDetectionService` — صلوات فائتة، allPendingQada
- `LocationService` — المدينة، isUsingDefaultLocation
- `NotificationService` — جدولة إشعارات
- `ConnectivityService` — حالة الاتصال
- `StorageService` — إعدادات

---

## 2. قائمة التحقق — Constants

### 2.1 استبدال كل القيم الثابتة

| النوع | استخدم بدلاً من | مثال خاطئ | مثال صحيح |
|-------|-----------------|-----------|-----------|
| **Padding/Spacing** | `AppDimensions.padding*` | `padding: 12` | `AppDimensions.paddingMD` |
| **Radius** | `AppDimensions.radius*` | `BorderRadius.circular(20)` | `AppDimensions.radiusRound` |
| **Icon Size** | `AppDimensions.icon*` | `size: 18` | `AppDimensions.iconMD` |
| **Colors** | `AppColors.*` | `Color(0xFF...)` | `AppColors.primary` |
| **Fonts** | `AppFonts.*` | `TextStyle(fontSize: 16)` | `AppFonts.bodyLarge` |
| **Lottie/Images** | `ImageAssets.*` | `'assets/animations/loading.json'` | `ImageAssets.loadingAnimation` |

### 2.2 الملفات المستهدفة (مراجعة يدوية)

```
lib/features/prayer/
├── presentation/
│   ├── screens/
│   │   ├── dashboard_screen.dart      ✅ بسيط
│   │   └── missed_prayers_screen.dart ⚠️ تحقق Lottie paths
│   └── widgets/
│       ├── dashboard_home_content.dart    ⚠️ 12, 6, 20, 4, 16
│       ├── dashboard_app_bar.dart         ⚠️ 3, 18
│       ├── dashboard_progress_widgets.dart
│       ├── smart_prayer_circle.dart
│       ├── daily_review_card.dart
│       ├── qada_review_bottom_sheet.dart
│       ├── connection_status_indicator.dart
│       ├── drawer.dart
│       └── drawer_parts.dart
```

---

## 3. مراحل التنفيذ

### المرحلة 1 — توحيد Constants في الداشبورد (أولوية عالية)

| # | المهمة | الملف | التفاصيل |
|---|--------|-------|----------|
| 1 | استبدال padding/spacing الثابتة | `dashboard_home_content.dart` | `12` → `paddingMD`, `6` → `paddingSM`, `20` → `radiusRound`, `4` → `paddingXS`, `8` → `paddingSM` |
| 2 | استبدال icon sizes | `dashboard_home_content.dart`, `dashboard_app_bar.dart` | `18` → `iconMD`, `16` → `iconSM` |
| 3 | استبدال SizedBox الثابتة | كل الودجتس | `SizedBox(width: 3)` → `SizedBox(width: AppDimensions.paddingXXS)` |
| 4 | Colors.transparent | — | `AppColors.transparent` |
| 5 | استخدام ImageAssets للـ Lottie | `missed_prayers_screen.dart`, `qada_review_bottom_sheet` | `ImageAssets.loadingAnimation`, `ImageAssets.successAnimation` |

### المرحلة 2 — الودجتس الفرعية

| # | المهمة | الملف |
|---|--------|-------|
| 6 | `smart_prayer_circle.dart` | مراجعة كل dimensions و colors |
| 7 | `daily_review_card.dart` | مراجعة padding, radius, fonts |
| 8 | `dashboard_progress_widgets.dart` | مراجعة buildTodayProgress, buildQuickPrayerIcons |
| 9 | `qada_review_bottom_sheet.dart` | Constants + ImageAssets |
| 10 | `connection_status_indicator.dart` | مراجعة |
| 11 | `drawer.dart` + `drawer_parts.dart` | Constants، وربط Routes بـ AppRoutes |

### المرحلة 3 — Missed Prayers Screen

| # | المهمة | الملف |
|---|--------|-------|
| 12 | توحيد Constants | `missed_prayers_screen.dart` |
| 13 | استخدام ImageAssets | Lottie من constants |
| 14 | `missed_prayer_card.dart` | مراجعة dimensions |
| 15 | ترجمة كل النصوص | `.tr` للنصوص الثابتة إن وُجدت |

### المرحلة 4 — التحقق من الخدمات

| # | المهمة | التأكد من |
|---|--------|-----------|
| 16 | DashboardController | يستدعي LiveContext, Qada, Location, Notification بشكل صحيح |
| 17 | Qada flow | زر التعويض يظهر عند وجود unlogged، ويفتح البوتوم شيت |
| 18 | Location hint | يظهر عند isUsingDefaultLocation، الزر يفتح selectCity |
| 19 | Connection status | يُعرض عندما offline |
| 20 | Prayer logging | SmartPrayerCircle يسجّل عبر PrayerRepository، Toast عند النجاح |

---

## 4. قائمة فحص نهائية

قبل إغلاق الميزة، تحقق:

- [ ] لا يوجد `padding: 12` أو أرقام ثابتة — كلها من AppDimensions
- [ ] لا يوجد `Color(0x...)` — كلها AppColors
- [ ] لا يوجد `fontSize: 16` — كلها AppFonts
- [ ] كل مسارات Lottie من ImageAssets
- [ ] كل النصوص عبر `.tr`
- [ ] ConnectionStatusIndicator يستخدم ConnectivityService
- [ ] LocationHintBanner يظهر فقط عند استخدام موقع افتراضي
- [ ] زر Qada يظهر عند وجود صلوات فائتة
- [ ] Drawer يستخدم AppRoutes للتنقل

---

## 5. تقدير الزمن

| المرحلة | تقدير |
|---------|-------|
| المرحلة 1 | 1–2 ساعات |
| المرحلة 2 | 2–3 ساعات |
| المرحلة 3 | 1–2 ساعات |
| المرحلة 4 | 1 ساعة (تحقق واختبار) |
| **الإجمالي** | **~6 ساعات** |

---

## 6. الملف التالي بعد الداشبورد

بعد إكمال هذه الخطة:

1. **Settings** — توحيد Constants في شاشة الإعدادات
2. **Stats** — مراجعة stats_screen
3. **Profile** — مراجعة profile_screen

أو البدء في **ميزة جديدة** (مثل العائلة) حسب الأولوية.
