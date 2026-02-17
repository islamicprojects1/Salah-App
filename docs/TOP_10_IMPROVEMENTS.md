# أفضل 10 تحسينات للتطبيق

تحسينات مقترحة بناءً على تحليل الكود وتجربة الاستخدام — ليست أخطاء حقيقية بل **عمل مؤقت (workarounds)** أو **تجربة تحتاج تجسيم** أو **تنظيم**.

---

## 1. تغيير الثيم يسبب إحساس أن التطبيق "يضرب" أو يرمش

**المشكلة:** في `ThemeService._applyTheme()` يتم استدعاء `Get.forceAppUpdate()` بعد `Get.changeThemeMode()`. الـ forceAppUpdate يعيد بناء التطبيق بالكامل فجأة فيُحس المستخدم بوميض أو "ضربة".

**الحل:**
- إزالة `Get.forceAppUpdate()` والاعتماد فقط على `Get.changeThemeMode(themeMode)` — GetX يحدّث الثيم دون الحاجة لإعادة بناء كامل.
- إن بقي جزء من الواجهة لا يتحدّث (مثلاً ألوان من `AppColors` التي تعتمد على `Get.isDarkMode`)، استخدم `Obx` في الجذر فقط حول الجزء الذي يحتاج إعادة بناء، أو حدّث الثيم عبر `Theme.of(context)` بدل الاعتماد على Get.isDarkMode في أماكن حرجة.

**الملف:** `lib/features/settings/data/services/theme_service.dart` — السطر ~88.

---

## 2. اللغة والاتجاه لا يتحدّثان فوراً في كل الشاشة

**المشكلة:** في `app.dart` الـ `locale` و `textDirection` (في الـ builder) يُقرآن مرة واحدة عند البداية من `LocalizationService`. عند تغيير اللغة يُستدعى `Get.updateLocale()` — لكن الـ `builder` قد لا يُستدعى مرة ثانية في بعض الإصدارات، فيبقى الاتجاه أو النص القديم في شاشات مفتوحة.

**الحل:**
- جعل الجذر تفاعلياً: لفّ `GetMaterialApp` (أو محتوى الـ builder) داخل `Obx` يعتمد على `localizationService.currentLocale` و `currentLanguage` حتى يُعاد بناء الشجرة عند تغيير اللغة.
- أو التأكد من استدعاء `Get.updateLocale()` ثم إغلاق أي شاشات ثانوية وإعادة فتحها إن لزم، أو استخدام `Get.forceAppUpdate()` **مرة واحدة** عند تغيير اللغة فقط (وليس عند تغيير الثيم) إن كان السلوك الحالي لا يحدّث الواجهة.

**الملف:** `lib/app.dart` — الـ builder وربط الـ locale.

---

## 3. زر "شجّعه" بدون مؤشر تحميل

**المشكلة:** عند اختيار رسالة تشجيع من الـ Popup ثم استدعاء `pokeMember()`، العملية غير متزامنة (استدعاء Firestore) ولا يظهر أي مؤشر تحميل. المستخدم قد يضغط مرة ثانية أو يظن أن شيئاً لم يحدث.

**الحل:**
- إضافة حالة `isSendingEncouragement` أو `sendingToUserId` في الـ Controller.
- عرض `CircularProgressIndicator` صغير على الزر أو تعطيل الـ Popup/زر "شجّعه" حتى ينتهي الطلب، ثم إظهار Toast النجاح أو الخطأ كما هو حالياً.

**الملفات:** `lib/features/family/controller/family_controller.dart`، `lib/features/family/presentation/screens/family_dashboard_screen.dart` (قسم _buildMemberActions وزر التشجيع).

---

## 4. إشعارات العائلة والتشجيع بدون تجسيم تفاعلي

**المشكلة:** إرسال التشجيع يكتب في Firestore (notifications + pulse) لكن الطرف الآخر لا يستلم إشعاراً push (FCM) — المذكور في الخطة أنه "يتطلب FCM". كذلك لا توجد رسالة واضحة للمُشجَّع داخل التطبيق (مثلاً شارة "لديك تشجيع جديد") إلا إن فتح شاشة الإشعارات.

**الحل:**
- تجسيم تجريبي: عند فتح شاشة "الإشعارات" أو العائلة، عرض قائمة "تشجيعات وردتك" من مجموعة `notifications` في Firestore مع تمييز غير المقروء.
- لاحقاً: ربط FCM بإشعار "شجّعك فلان" حتى يصل تنبيه حقيقي للمُشجَّع.

**الملفات:** `lib/features/notifications/`، `lib/features/family/data/services/family_service.dart` (sendEncouragement + قراءة notifications).

---

## 5. عدد كبير من `catch (_)` صامتة

**المشكلة:** أكثر من 25 موضعاً في المشروع يستخدمون `catch (_)` أو `catch (e) {}` بدون تسجيل أو إظهار أي شيء للمستخدم. الأخطاء تختفي ويصعب تتبع الأعطال.

**الحل:**
- في الطبقات الدنيا (Repository / Service): استبدال الصمت بـ `AppLogger.warning` أو `AppLogger.error` مع رسالة سياق (مثل "PrayerRepository.syncItem failed").
- في الـ Controllers/UI: إما إعادة رمي الاستثناء بعد التسجيل، أو إظهار Toast عام للمستخدم (مثل "حدث خطأ، جرّب لاحقاً") في الأماكن الحرجة (تسجيل صلاة، انضمام عائلة، إلخ).

**أمثلة ملفات:** `dashboard_controller.dart`, `notification_service.dart`, `prayer_repository.dart`, `family_service.dart`, `qada_detection_service.dart`.

---

## 6. ملفات ضخمة صعبة الصيانة

**المشكلة:**  
- `family_dashboard_screen.dart` ~1155 سطراً.  
- `dashboard_controller.dart` ~700 سطراً.  
- `dashboard_screen.dart` ~640+ سطراً.  
- `settings_screen.dart` كبير جداً.

**الحل:**
- فصل ويدجتات من الشاشات إلى ملفات منفصلة، مثلاً:  
  - `family_pulse_section.dart`, `family_members_section.dart`, `family_header_card.dart` من صفحة العائلة.  
  - `dashboard_progress_card.dart`, `dashboard_quick_prayers.dart` من الـ Dashboard.  
- استخراج منطق من الـ Controller إلى UseCase أو Service (مثلاً "جدولة الإشعارات" في خدمة مخصّصة) حتى يقل حجم الـ Controller عن ~400 سطر.

**المرجع:** `docs/PLAN_DRAWER_AND_UI.md` و `docs/EXECUTION_PLAN.md` (البند 5.2).

---

## 7. خلط استخدام `Get.find` و `sl` (GetIt)

**المشكلة:** المشروع يستخدم كل من GetX (`Get.find`) و GetIt (`sl`). أحياناً نفس النوع يُستدعى بـ `Get.find` في مكان وـ `sl` في مكان آخر، مما يسبب التباساً واحتمال استدعاء قبل التسجيل (مثلاً في الـ Drawer قبل فتح الشاشة التي تسجّل الـ Controller).

**الحل:**
- توحيد القاعدة: الـ **Controllers** المرتبطة بمسارات (صفحة واحدة) → GetX و Bindings. الخدمات والمستودعات → GetIt فقط (`sl`).
- عدم استدعاء `Get.find<SomeController>()` من ويدجت يعيش خارج الشاشة المرتبطة بذلك الـ Controller (مثلاً من الـ Drawer) إلا بعد التأكد من أن الشاشة مفتوحة أو استخدام `Get.isRegistered` مع fallback.

**الملفات:** الـ Drawer، أي ويدجت عام يستخدم كلا النظامين.

---

## 8. عدم وجود تأكيد عند تسجيل الخروج

**المشكلة:** في الـ Drawer (وربما أماكن أخرى) زر "تسجيل الخروج" ينفّذ الخروج مباشرة. إن كان المستخدم ضغط بالخطأ يفقد الجلسة دون تأكيد.

**الحل:**
- عرض حوار تأكيد قبل الخروج: "هل تريد تسجيل الخروج؟" مع [إلغاء] و [تسجيل الخروج]. تنفيذ الخروج فقط عند اختيار التأكيد.

**الملف:** `lib/features/prayer/presentation/widgets/drawer.dart` — _buildLogoutButton؛ أو نقله إلى `SettingsController.logout()` مع عرض الحوار من الـ Controller.

---

## 9. رسائل عربية مكتوبة مباشرة في الكود

**المشكلة:** في أماكن مثل `FamilyController` و `SettingsController` تظهر نصوص مثل `'خطأ'` و `'تنبيه'` مكتوبة مباشرة بدل استخدام مفاتيح الترجمة (`'error'.tr`, `'alert'.tr`). في واجهة إنجليزية يبقى النص عربياً.

**الحل:**
- استبدال كل النصوص الثابتة بمفاتيح من ملفات الترجمة واستخدام `.tr` أو `.trParams()`.
- مراجعة: `family_controller.dart` (خطأ، تنبيه)، أي `showError`/`showSnackbar` بسلاسل ثابتة.

**الملفات:** `lib/features/family/controller/family_controller.dart`, `lib/features/settings/controller/settings_controller.dart`, وغيرها.

---

## 10. تجسيم تجربة الإشعارات (أذان / تذكير)

**المشكلة:**  
- عند الضغط على "صليت" من الإشعار ينتقل المستخدم للـ Dashboard وقد لا يرى فوراً أن الصلاة سُجّلت (لا تأكيد بصري على البطاقة أو الدائرة إلا بعد التحديث).  
- عند اختيار "لاحقاً" (snooze) لا يُعرض تأكيد واضح أن التذكير سيأتي بعد X دقائق.

**الحل:**
- بعد معالجة action "صليت" وإضافة السجل: إظهار Toast واضح (موجود جزئياً) مع التأكد من تحديث الـ Controller/الشاشة فوراً (مثلاً إعادة جلب اليوم أو تحديث الـ stream).
- عند اختيار "لاحقاً": إظهار Toast قصير: "سيصلك تذكير بعد X دقائق" مع الاعتماد على نفس الثابت (مثلاً 5/10/15) المستخدم في الجدولة.

**الملفات:** `lib/features/prayer/data/services/notification_service.dart`, `lib/features/prayer/data/services/smart_notification_service.dart`, وربما الـ Controller الذي يحدّث واجهة الصلوات.

---

## ملخص أولويات التنفيذ

| # | التحسين | الجهد التقريبي | الأثر |
|---|---------|-----------------|------|
| 1 | إزالة/استبدال forceAppUpdate عند تغيير الثيم | منخفض | تجربة ثيم أنعم |
| 2 | ربط اللغة والاتجاه بإعادة بناء تفاعلية | منخفض–متوسط | تغيير لغة صحيح في كل الشاشة |
| 3 | مؤشر تحميل لزر "شجّعه" | منخفض | وضوح تفاعل المستخدم |
| 8 | تأكيد قبل تسجيل الخروج | منخفض | تجنب خروج بالخطأ |
| 9 | استبدال النصوص الثابتة بمفاتيح ترجمة | منخفض | دعم اللغة الإنجليزية |
| 5 | تقليل catch (_) الصامتة (تسجيل + رسالة مستخدم حيث يلزم) | متوسط | تتبع أخطاء أفضل |
| 10 | Toast/تأكيد عند "صليت" و "لاحقاً" | منخفض | تجسيم إشعارات |
| 4 | قائمة تشجيعات وردتك + لاحقاً FCM | متوسط–عالي | تجسيم العائلة والإشعارات |
| 7 | توحيد Get.find vs sl | متوسط | وضوح وصيانة |
| 6 | تقسيم الملفات الضخمة | متوسط | صيانة وتنظيم |

---

**مراجع:** [EXECUTION_PLAN.md](EXECUTION_PLAN.md) — [PLAN_DRAWER_AND_UI.md](PLAN_DRAWER_AND_UI.md) — [ARCHITECTURE.md](ARCHITECTURE.md)
