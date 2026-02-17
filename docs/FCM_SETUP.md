# إعداد إشعارات العائلة (FCM Push)

## الحل الحالي: Legacy Server Key (مجاني — بدون Blaze)

### 1. أين تجد Legacy Server Key؟

**الطريقة الأولى — من Firebase:**
1. افتح [Firebase Console](https://console.firebase.google.com/) → مشروعك
2. **Project Settings** (أيقونة الترس) → تبويب **Cloud Messaging**
3. في قسم **Cloud Messaging API (Legacy)** تأكد أنه **Enabled**
4. ابحث عن صف **"Server key"** — انسخ المفتاح

**إن لم يظهر المفتاح — تفعيل Legacy من Google Cloud:**
1. في نفس صفحة Cloud Messaging، اضغط **النقاط الثلاث (⋮)** بجانب "Cloud Messaging API (Legacy)"
2. اختر **"Manage API in Google Cloud Console"**
3. في Google Cloud تأكد أن الـ API **مفعّل** (Enable)
4. ارجع لـ Firebase Console → Cloud Messaging وحدّث الصفحة (F5)
5. قد يظهر بعدها حقل **Server key**

⚠️ **ملاحظة:** واجهة Legacy متوقفة تدريجياً (من يوليو 2024). إن لم يظهر المفتاح، الخيار الوحيد المجاني حالياً هو الاكتفاء بالنبض داخل التطبيق حتى الترقية لـ Blaze.

### 2. إضافة المفتاح في الكود

افتح: `lib/features/notifications/data/services/fcm_service.dart`

ابحث عن:
```dart
static const String _legacyServerKey = 'YOUR_LEGACY_SERVER_KEY_HERE';
```

استبدل `YOUR_LEGACY_SERVER_KEY_HERE` بالمفتاح الذي نسخته.

### 3. التحقق

- عند إنشاء عائلة أو الانضمام إليها: يتم الاشتراك تلقائياً في topic `family_{familyId}`
- عند حدث (صلاة، تشجيع): يُرسل إشعار FCM لكل من اشترك في نفس العائلة
- تأكد أن المستخدم سمح بالإشعارات من إعدادات الجهاز

---

## تحذير أمني

وضع المفتاح في التطبيق غير آمن — يمكن استخراجه من الـ APK. للحل الآمن لاحقاً: استخدام Cloud Functions (يتطلب خطة Blaze).

---

## البديل: Cloud Functions (عند الترقية لـ Blaze)

عند رغبتك الترقية لخطة Blaze، انظر الملف `functions/index.js` واتبع:

```bash
firebase login
firebase use salah-app-2026
cd functions && npm install && cd ..
firebase deploy --only functions
```
