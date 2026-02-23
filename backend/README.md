# Backend — Salah App (Express)

هذا المجلد يحتوي **كل المنطق الخادم** البديل لـ Firebase Cloud Functions لتطبيق صلاة.

## العلاقة مع الدراسة

- **الدراسة الكاملة:** `docs/FAMILY_FEATURE_STUDY.md` — الرؤية، السيناريوهات، تجربة المستخدم، والإشعارات بين المستخدمين.
- **برومت تحسين الدراسة:** `docs/CLAUDE_PROMPT_FAMILY_STUDY_IMPROVE.md` — لاستخدام Claude لتحسين الدراسة وتغطية كل السيناريوهات والـ UX والربط مع هذا الـ backend.

## ماذا يُنفَّذ هنا

| البديل عن Cloud Functions | الوصف |
|---------------------------|--------|
| إشعار "يصلّي الآن" | عند تحديث `prayingNow` في Firestore → إرسال FCM إلى Topic `family_{groupId}` |
| إشعار "أكمل صلاة" | عند تحديث `todayPrayers` (إضافة صلاة) → FCM للعائلة |
| إشعار "انضم للانتظار" | عند تحديث `waitingFor` → FCM للعائلة |
| إشعار "دعاء / تشجيع" | عند إنشاء وثيقة في `encouragements` أو ما يعادلها → FCM للمستهدف |
| إشعار "عضو جديد انضم" | عند انضمام عضو → إشعار للمدير |
| (أي منطق خادم آخر) | حسب الدراسة — يُضاف هنا ويُوثَّق في الدراسة |

## التقنيات

- **Node.js + Express**
- **Firebase Admin SDK** — Firestore (قراءة/مراقبة) + FCM (إرسال إشعارات)
- لا حاجة لخطة Blaze — إرسال FCM من هذا السيرفر لا يتطلب Cloud Functions

## الإعداد والتشغيل

1. **نسخ ملف البيئة**
   ```bash
   cd backend
   npm install
   copy .env.example .env
   ```
   (على Linux/Mac: `cp .env.example .env`)

2. **ملف Service Account من Firebase**
   - افتح [Firebase Console](https://console.firebase.google.com) → مشروعك → ⚙️ Project Settings → Service accounts
   - اضغط **Generate new private key** وحمّل الملف JSON
   - ضع الملف داخل مجلد `backend/` باسم مثل `serviceAccountKey.json` (لا ترفعه إلى Git)

3. **تعديل .env**
   ```
   PORT=3000
   GOOGLE_APPLICATION_CREDENTIALS=./serviceAccountKey.json
   ```

4. **تشغيل السيرفر**
   ```bash
   npm start
   ```
   عند النجاح ستظهر: `[Firebase] ✓ Admin SDK initialized.`

## هيكل المجلد (مقترح)

```
backend/
  README.md          هذا الملف
  package.json
  index.js           نقطة الدخول، Express + مراقبة Firestore + إرسال FCM
  .env.example       متغيرات البيئة (مسار service account، إلخ)
  lib/               (اختياري) دوال مساعدة للإشعارات و Firestore
```

## الاستضافة

يمكن نشر هذا السيرفر على: Railway، Render، أو أي VPS. التطبيق (Flutter) يبقى يكتب في Firestore مباشرة؛ هذا السيرفر يستمع للتغييرات ويرسل الإشعارات.
