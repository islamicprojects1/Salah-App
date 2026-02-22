# خطة متكاملة: NotificationService + التحقق من الخدمات

> خطة شاملة تجمع: الإشعارات المحلية (NotificationService) والمرحلة 4 من PLAN_DASHBOARD_AND_PRAYER.

---

## الجزء 0 — تجربة المستخدم مع الإشعارات المحلية (UX Spec)

### 0.1 الإطار الزمني لكل صلاة

```
[قبل 15 دقيقة]     [وقت الصلاة]     [+30 دقيقة]     [+60 دقيقة]
      ↓                  ↓                 ↓                ↓
  تنبيه مسبق          الأذان          تذكير أول       تذكير أخير
```

| التوقيت | المحتوى | الأزرار |
|---------|---------|---------|
| **قبل 15 دقيقة** | صوتية خفيفة: "اقتربت صلاة الفجر، تبقّى 15 دقيقة" | بدون أزرار — تنبيه فقط |
| **عند دخول الوقت** | أذان كامل أو تكبير (حسب الإعداد) | زر واحد: "صليت ✓" |
| **بعد 30 دقيقة** (إن لم يُسجّل) | تذكير: "حان وقت الصلاة، لا تؤخّر" | "صليت ✓" — "بعد شوي" |
| **بعد 60 دقيقة** (بعد ضغط "بعد شوي") | تذكير أخير قبل ضيق الوقت | "صليت ✓" — "سأقضيها" |

### 0.2 قواعد "بعد شوي"

- **لا يتكرر أكثر من مرتين** — بعدها يتحول الزر إلى "سأقضيها" تلقائياً
- لا إزعاج مفرط للمستخدم

### 0.3 الفجر — معاملة خاصة

- التنبيه المسبق أهم في الفجر
- قابل للضبط: 20 دقيقة بدل 15 (إعداد اختياري)

### 0.4 عتبات جودة الصلاة (حسب نسبة نافذة الوقت)

تعتمد الجودة على نسبة الوقت المنقضي من الأذان إلى دخول الصلاة التالية:

| النسبة من النافذة | المعنى | التصنيف (PrayerTimingQuality) |
|-------------------|--------|-------------------------------|
| **0–20%** | أول الوقت | veryEarly / early |
| **20–60%** | في الوقت | onTime |
| **60–90%** | آخرها | late |
| **90–100%** | آخر الدقائق | veryLate |
| **بعد النافذة** | تركها | missed |

*(مثال: الظهر والعصر — أول ساعة ≈ أول الوقت، بعدها ≈ في الوقت، آخر نصف ساعة ≈ آخرها)*

### 0.5 سلوك الإلغاء عند التسجيل

| متى سجّل | ماذا يحدث للإشعارات |
|----------|----------------------|
| **أول الوقت** (خلال ~10 دقائق) | تُلغى كل إشعارات هذه الصلاة فوراً |
| **في الوقت** (بعد 10 دقائق — قبل الضيق) | تُلغى عند الضغط "صليت" |
| **متأخر** (قُبيل دخول التالية) | تُلغى + Toast تشجيعي خفيف |
| **قضاء** (بعد خروج الوقت) | زر "سأقضيها" يحفظها كـ pending في قائمة القضاء |

### 0.6 ملاحظات حرجة

1. **الإشعار يجب أن يختفي فوراً عند تسجيل الصلاة** — أي تأخير يكسر الثقة
2. **زر "صليت" يجب أن يسجّل الصلاة فعلاً** — هذا غير قابل للتفاوض، التحقق إلزامي
3. **الصوتيات:** اقتربت صلاة الفجر، تكبير (الله أكبر)، تذكير — كلها موجودة

---

## الجزء 1 — NotificationService (الإشعارات المحلية)

### 1.1 نظرة عامة

| العنصر | الوصف | الاعتماد |
|--------|--------|----------|
| **النوع** | إشعارات محلية مجدولة على الجهاز | `flutter_local_notifications` |
| **ليس** | إشعارات push من سيرفر خارجي | — |
| **المصدر** | `lib/features/prayer/data/services/notification_service.dart` | — |

---

### 1.2 الوظائف المطلوبة

| # | الوظيفة | الحالة الحالية | الملف / الدالة |
|---|---------|----------------|-----------------|
| 1 | جدولة إشعار عند دخول وقت كل صلاة | ✅ منفّذ | `scheduleNotificationWithActions` عبر `rescheduleAllForToday` |
| 2 | جدولة تذكير بعد 30 دقيقة إن لم تُسجّل الصلاة | ✅ منفّذ | `scheduleNotificationWithActions` مع `ApiConstants.prayerReminderDelayMinutes` |
| 3 | أزرار الإجراء: "صليت" و"لاحقاً" | ✅ منفّذ | `_onNotificationTapped` → `_handlePrayedAction`، `_handleSnoozeAction` |
| 4 | قنوات Android: صوت، اهتزاز، صامت | ✅ منفّذ | `_createNotificationChannels` → `prayer_adhan`, `prayer_vibrate`, `prayer_silent` |
| 5 | استخدام `flutter_local_notifications` | ✅ منفّذ | `FlutterLocalNotificationsPlugin` |

---

### 1.3 مكوّنات NotificationService المفصّلة

#### أ) جدولة الإشعار (عند وقت الصلاة)

- **الدالة:** `rescheduleAllForToday()`
- **متى تُستدعى:**
  - بعد `PrayerTimeService.calculatePrayerTimes()` (موقع/مدينة جديدة)
  - بعد `PrayerTimeService.onLocationChanged()`
  - عند `SyncService` — استعادة الاتصال
  - عند `DashboardController` — منتصف الليل (midnight rollover)
- **المنطق:**
  1. إلغاء كل الإشعارات الحالية
  2. جلب مواقيت اليوم من `PrayerTimeService.getTodayPrayers()`
  3. استبعاد الصلوات المُسجّلة (via `QadaDetectionService.todayUnlogged`)
  4. لكل صلاة لم تمر: جدولة أذان + تذكير 30 دقيقة
  5. احترام: `adhan_notifications_enabled`، `reminder_notification`، تفعيل كل صلاة (فجر/ظهر/عصر/مغرب/عشاء)

#### ب) التذكير بعد 30 دقيقة

- **الثابت:** `ApiConstants.prayerReminderDelayMinutes = 30`
- **الجداول:** تُجدول مع `id = baseId + 100` لكل صلاة
- **الشكل:** نفس الأزرار (صليت / لاحقاً)

#### ج) أزرار الإجراء

| الزر | actionId | السلوك |
|------|----------|--------|
| صليت | `prayed` أو `confirmPrayed` | تسجيل الصلاة عبر `PrayerRepository.addPrayerLog`، إلغاء أذان+تذكير، Toast |
| لاحقاً | `snooze` | جدولة تذكير جديد (تصعيد: 5 → 10 → 15 دقيقة) عبر `QadaDetectionService.incrementSnoozeAndGetDelay` |
| صليت الآن | `willPrayNow` | الانتقال للداشبورد فقط |

#### د) القنوات (Android)

| القناة | channelId | الاستخدام |
|--------|-----------|-----------|
| أذان (صوت) | `prayer_adhan` | صوت أذان كامل |
| تكبير (صوت قصير) | `prayer_takbeer` | تكبير قصير عند وقت الصلاة |
| اهتزاز | `prayer_vibrate` | `enableVibration: true`, `playSound: false` |
| صامت | `prayer_silent` | بدون صوت ولا اهتزاز |
| تذكير | `reminder_notifications` | تذكير 30 دقيقة |
| approaching | `prayer_approach_*` | قبل الصلاة بـ X دقيقة |

---

### 1.4 الإعدادات (StorageKeys)

| المفتاح | الوصف | الافتراضي |
|---------|--------|-----------|
| `notifications_enabled` | تفعيل الإشعارات كلياً | true |
| `adhan_notifications_enabled` | إشعارات الأذان | true |
| `reminder_notification` | تذكير 30 دقيقة | true |
| `notification_sound_mode` | adhan / vibrate / silent | adhan |
| `fajr_notification`, … | تفعيل كل صلاة | true |
| `approaching_alert_enabled` | تنبيه قبل الصلاة | false |
| `approaching_alert_minutes` | دقائق قبل الصلاة | 15 |

---

### 1.5 قائمة تحقق NotificationService

| # | البند | التحقق |
|---|-------|--------|
| 1 | مواقيت الصلاة من `PrayerTimeService` (Aladhan API) | ✅ بعد الهجرة |
| 2 | إلغاء الإشعار عند تسجيل الصلاة (من التطبيق أو الزر) | ✅ `cancelPrayerReminder` |
| 3 | تذكير 30 دقيقة يُجدول ويُلغى مع الأذان | ✅ |
| 4 | قنوات Android تُنشأ عند init | ✅ `_createNotificationChannels` |
| 5 | وضع الصوت (adhan/vibrate/silent) يُطبق على القناة | ✅ `_getPrayerChannelId(soundMode)` |
| 6 | صلاحيات النظام: طلب مرة واحدة + رسالة عند الرفض | حسب EXECUTION_PLAN |
| 7 | المستخدم غير مسجّل: حفظ pending في Storage | ✅ `_savePendingPrayerLog` |
| 8 | LiveContextService.onPrayerLogged عند تسجيل من الإشعار | ✅ |
| 9 | **زر "صليت" يسجّل الصلاة فعلياً** (غير قابل للتفاوض) | مراجعة `_handlePrayedAction` |

---

### 1.6 SmartNotificationService مقابل NotificationService

| الخدمة | الدور |
|--------|------|
| **NotificationService** | جدولة وإلغاء إشعارات مجدولة، معالجة الإجراءات، قنوات |
| **SmartNotificationService** | عرض إشعار فوري (مثلاً "حان وقت X") مع أزرار — يُستخدم عند الحاجة لإشعار فوري وليس مجدول |

**ملاحظة:** الجدولة الفعلية تتم في `NotificationService.rescheduleAllForToday`. إن كان `SmartNotificationService` يُستدعى من مكان آخر للجدولة، يجب توحيد المصدر في `NotificationService` فقط.

---

### 1.6 مهام تنفيذ تجربة الإشعارات (حسب الجزء 0)

| # | المهمة | الملف / الملاحظة |
|---|--------|------------------|
| 1 | تحديث عتبات الجودة إلى 20/60/90% | `PrayerTimeRange.calculateQuality` |
| 2 | الأذان: زر واحد فقط "صليت" (بدون "بعد شوي") | `NotificationService` |
| 3 | تذكير +30: زرّان "صليت" و "بعد شوي" | موجود |
| 4 | تصعيد "بعد شوي": مرة ثانية → +60 دقيقة، بعدها "سأقضيها" | `QadaDetectionService.incrementSnoozeAndGetDelay` |
| 5 | تذكير +60: زرّان "صليت" و "سأقضيها" | إضافة زر جديد |
| 6 | زر "سأقضيها" يحفظ في قائمة القضاء | ربط بـ Qada flow |
| 7 | الفجر: تنبيه مسبق 20 دقيقة (قابل للضبط) | إعداد `approaching_fajr_minutes` |
| 8 | **التحقق الإلزامي:** زر "صليت" يسجّل فعلياً في DB و Firestore | اختبار تكاملي |

---

## الجزء 2 — المرحلة 4: التحقق من الخدمات

### 2.1 نظرة عامة

التحقق من أن `DashboardController` والودجتس تستخدم الخدمات بشكل صحيح، وأن كل العناصر المرئية تعمل كما هو متوقع.

---

### 2.2 التحقق من DashboardController

| # | البند | التحقق | الملف |
|---|-------|--------|-------|
| 1 | استخدام LiveContextService للصلاة الحالية والعد التنازلي | `todayLogs`، `prayerContext` → `currentPrayer`, `nextPrayer`, `timeUntilNextPrayer` | `dashboard_controller.dart` |
| 2 | استخدام QadaDetectionService للصلوات الفائتة | `unloggedPrayers`، `openQadaReview()`، `_maybeShowQadaHint()` | `dashboard_controller.dart` |
| 3 | استخدام LocationService للموقع والمدينة | `currentCity`، `isUsingDefaultLocation`، `openSelectCity()` | `dashboard_controller.dart` |
| 4 | استخدام NotificationService للجدولة | `_loadPrayerTimes()` → `rescheduleAllForToday` عند تغيير المواقيت | `dashboard_controller.dart` |
| 5 | استخدام PrayerTimeService للمواقيت | `todayPrayers`، `_loadPrayerTimes()` | `dashboard_controller.dart` |
| 6 | استخدام PrayerRepository لتسجيل الصلاة | `logPrayer()` → `_prayerRepo.addPrayerLog()` | `dashboard_controller.dart` |
| 7 | معالجة pending prayer من الإشعار عند resume | `_processPendingPrayerLogFromNotification()` في `didChangeAppLifecycleState` | `dashboard_controller.dart` |

---

### 2.3 التحقق من زر التعويض (Qada)

| # | البند | التحقق | الملف |
|---|-------|--------|-------|
| 1 | الزر يظهر عند وجود صلوات فائتة | `_QadaReviewButton` يستخدم `controller.unloggedPrayers` | `dashboard_home_content.dart` |
| 2 | الضغط يفتح QadaReviewBottomSheet | `controller.openQadaReview()` | `dashboard_controller.dart` |
| 3 | إن لم توجد صلوات فائتة: رسالة بدل فتح الشيت | `AppFeedback.showSnackbar('qada_hint_title', 'qada_none')` | `dashboard_controller.dart` |
| 4 | تذكير قضاء مرة واحدة يومياً | `_maybeShowQadaHint()` + Storage `qada_hint_shown_*` | `dashboard_controller.dart` |

---

### 2.4 التحقق من Location Hint

| # | البند | التحقق | الملف |
|---|-------|--------|-------|
| 1 | الـ Banner يظهر فقط عند استخدام موقع افتراضي | `controller.isUsingDefaultLocation` | `dashboard_home_content.dart` |
| 2 | الضغط يفتح شاشة اختيار المدينة | `controller.openSelectCity()` → `AppRoutes.selectCity` | `dashboard_controller.dart` |
| 3 | `isUsingDefaultLocation` من `LocationService` | `_locationService.isUsingDefaultLocation.value` | `dashboard_controller.dart` |

---

### 2.5 التحقق من Connection Status

| # | البند | التحقق | الملف |
|---|-------|--------|-------|
| 1 | المؤشر يقرأ من ConnectivityService | `SyncService.isOnlineObs` ← `ConnectivityService.isConnected` | `connection_status_indicator.dart`, `sync_service.dart` |
| 2 | يظهر عند عدم الاتصال أو وجود عناصر معلّقة | `if (isOnline && pending == 0) return SizedBox.shrink()` | `connection_status_indicator.dart` |
| 3 | الضغط يفتح bottom sheet تفاصيل المزامنة | `_showDetails(context, sync)` | `connection_status_indicator.dart` |
| 4 | زر "مزامنة الآن" عند اتصال + عناصر معلّقة | `PrayerRepository.syncAllPending()` | `connection_status_indicator.dart` |

---

### 2.6 التحقق من تسجيل الصلاة (SmartPrayerCircle + Toast)

| # | البند | التحقق | الملف |
|---|-------|--------|-------|
| 1 | SmartPrayerCircle يستدعي controller.logPrayer | `onTap: () => controller.logPrayer(currentPrayer)` | `smart_prayer_circle.dart` |
| 2 | logPrayer يستخدم PrayerRepository | `_prayerRepo.addPrayerLog()` | `dashboard_controller.dart` |
| 3 | Toast عند النجاح (متصل) | `AppFeedback.showSuccess('done', 'prayer_logged_toast')` | `dashboard_controller.dart` |
| 4 | Toast عند النجاح (أوفلاين) | `AppFeedback.showSuccess('done', 'saved_will_sync_later')` | `dashboard_controller.dart` |
| 5 | إلغاء إشعار الأذان/التذكير بعد التسجيل | `NotificationService.cancelPrayerReminder()` | `dashboard_controller.dart` (عبر _scheduleNotifications بعد تحديث todayLogs) |
| 6 | LiveContextService.onPrayerLogged يُستدعى | داخل `logPrayer` | `dashboard_controller.dart` |

---

## الجزء 3 — خطة التنفيذ والتحقق

### 3.1 مراحل العمل

| المرحلة | الوصف | المهام | تقدير |
|---------|--------|--------|-------|
| **أ** | التحقق من NotificationService | مراجعة الكود، اختبار يدوي: جدولة، إلغاء، أزرار، قنوات | 1 ساعة |
| **ب** | التحقق من SmartNotificationService vs NotificationService | تأكيد عدم تداخل، مصدر واحد للجدولة | 30 دقيقة |
| **ج** | التحقق من DashboardController | مراجعة استخدام كل الخدمات حسب الجداول أعلاه | 1 ساعة |
| **د** | التحقق من الودجتس | Qada button، Location hint، Connection status، SmartPrayerCircle | 1 ساعة |
| **هـ** | اختبار تكاملي | سيناريوهات: تسجيل من التطبيق، من الإشعار، أوفلاين، تغيير مدينة، منتصف الليل | 1.5 ساعة |

---

### 3.2 قائمة فحص نهائية

قبل إغلاق الخطة، تحقق:

- [ ] NotificationService: جدولة أذان + تذكير 30 دقيقة حسب مواقيت Aladhan
- [ ] أزرار "صليت" و"لاحقاً" تعمل وتُلغي الإشعارات
- [ ] قنوات Android: صوت، اهتزاز، صامت تعمل حسب الإعداد
- [ ] DashboardController يستخدم LiveContext، Qada، Location، Notification، PrayerTime، PrayerRepository
- [ ] زر Qada يظهر عند وجود صلوات فائتة ويفتح BottomSheet
- [ ] Location hint يظهر فقط عند `isUsingDefaultLocation`
- [ ] ConnectionStatusIndicator يظهر عند عدم اتصال أو عناصر معلّقة
- [ ] SmartPrayerCircle يسجّل عبر PrayerRepository مع Toast صحيح

---

## الجزء 4 — المراجع

| المستند | الاستخدام |
|---------|-----------|
| [PLAN_DASHBOARD_AND_PRAYER.md](PLAN_DASHBOARD_AND_PRAYER.md) | المراحل 1–4 للداشبورد |
| [MASTER_SPEC_NOTIFICATIONS_AND_ENGAGEMENT.md](MASTER_SPEC_NOTIFICATIONS_AND_ENGAGEMENT.md) | مواصفة الإشعارات والتواصل |
| [EXECUTION_PLAN.md](EXECUTION_PLAN.md) | تفاصيل الإشعارات والصلاحيات |
| [ARCHITECTURE.md](ARCHITECTURE.md) | بنية الخدمات والتطبيق |
