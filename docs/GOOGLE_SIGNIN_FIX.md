# إصلاح خطأ Google Sign-In (DEVELOPER_ERROR)

## المشكلة
عند الدخول بحساب Google يظهر خطأ أو التطبيق يتوقف. في اللوج: `DEVELOPER_ERROR` أو `ApiException: 10`.

## السبب
بصمة SHA-1 للـ keystore غير مضافة في Firebase Console. Google Sign-In يحتاجها للتحقق من التطبيق.

## الحل

### 1. جلب بصمة SHA-1 (للتطوير / Debug)

من المجلد الرئيسي للمشروع:

**Windows (PowerShell):**
```powershell
cd android
./gradlew signingReport
```

أو مباشرة:
```powershell
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

ابحث عن السطر `SHA1:` وانسخ القيمة (مثل `36:D5:B6:1D:17:3D:62:FD:...`).

### 2. إضافة SHA-1 في Firebase Console

1. افتح [Firebase Console](https://console.firebase.google.com)
2. اختر مشروع **Salah App**
3. **Project Settings** (الإعدادات) → **Your apps**
4. اختر التطبيق Android (`com.example.salah`)
5. تحت **SHA certificate fingerprints** → **Add fingerprint**
6. الصق بصمة SHA-1 التي نسختها
7. اضغط **Save**

### 3. (اختياري) إضافة SHA-256
نفّذ نفس الأمر `keytool -list -v ...` وانسخ قيمة **SHA256:** وأضفها أيضاً في Firebase.

### 4. تحميل google-services.json من جديد
1. من Firebase Console → Project Settings → Your apps
2. اضغط على **google-services.json** لتحميله
3. استبدل الملف في `android/app/google-services.json`

### 5. إعادة بناء التطبيق
```powershell
flutter clean
flutter pub get
flutter run
```

---

## للـ Release Build
استخدم keystore الإصدار (Release) وليس debug:
```powershell
keytool -list -v -keystore "path/to/your/release.keystore" -alias your_alias
```

ثم أضف بصمة SHA-1 الخاصة بالـ release في Firebase أيضاً.
