# 🎯 CURSOR PROMPT — Auth & Onboarding Feature (Complete Rewrite)

## 📋 CONTEXT — READ FIRST

هذا تطبيق **قُرب** — تطبيق تتبّع الصلاة العائلي (Flutter + GetX).  
الهدف: إعادة كتابة `features/auth` و `features/onboarding` بالكامل بأفضل جودة ممكنة.

---

## 📑 TABLE OF CONTENTS

1. [Assets & Reality Check](#-important--assets--reality-check)
2. [Reference Files](#-reference-files--use-always)
3. [Design Direction](#-design-direction)
4. [Architecture & Structure](#-structure)
5. [Screen Specifications](#-screens-spec)
6. [Controller Spec](#-controller-spec)
7. [Translations](#-translations)
8. [Assets Mapping](#-assets--use-existing-only)
9. [Styling Rules](#-styling-rules)
10. [Routes & Flow](#-routes)
11. [Implementation Order](#-start-order)

---

## ⚠️ IMPORTANT — Assets & Reality Check

- **`assets/images`** is currently **empty** — no PNG images exist. All `$_images/*.png` paths point to non-existent files.
- **Use fallbacks:** For any image (logo, kaaba, etc.) wrap in `Image.asset(..., errorBuilder: ...)` and show `Icon(Icons.mosque)` or similar.
- **Lottie assets that exist:** `mosque.json`, `Success.json`, `dadwithfatherareprayer.json`, `loading.json`, `Confetti.json`, `infinite_loop.json`.
- **ImageAssets** uses `appLogo` (`assets/icons/salah_app_logo.png`), `appIcon` — verify these PNGs exist in `assets/icons/`. If not, use `errorBuilder` or `mosqueAnimation`.
- **Dialog files:** Use `lib/core/widgets/app_dialogs.dart` — verify which exports what (there is also `app_dialog.dart`).
- **Routes:** `AppRoutes.splash` = `/splash` (not `/`). Keep existing route names.

---

## 📁 REFERENCE FILES — USE ALWAYS

| الملف | الاستخدام |
|-------|-----------|
| `lib/core/theme/app_colors.dart` | كل الألوان — لا تكتب hex مباشرة |
| `lib/core/theme/app_fonts.dart` | كل الـ TextStyles — لا تكتب TextStyle يدوي |
| `lib/core/theme/app_theme.dart` | الثيم العام |
| `lib/core/constants/app_dimensions.dart` | كل الـ padding/radius/sizes |
| `lib/core/constants/storage_keys.dart` | مفاتيح التخزين |
| `lib/core/constants/image_assets.dart` | مسارات الـ assets |
| `lib/core/constants/enums.dart` | كل الـ enums |
| `lib/core/widgets/app_button.dart` | الأزرار |
| `lib/core/widgets/app_text_field.dart` | حقول الإدخال |
| `lib/core/widgets/app_loading.dart` | التحميل |
| `lib/core/widgets/app_dialogs.dart` | الـ dialogs (verify export) |
| `lib/core/feedback/toast_service.dart` | الـ toasts |
| `lib/core/localization/ar_translations.dart` | المفاتيح العربية |
| `lib/core/localization/en_translations.dart` | المفاتيح الإنجليزية |

---

## 🎨 DESIGN DIRECTION

### الهوية البصرية
- **اللون الرئيسي:** `AppColors.primary` (#1B5E20 — أخضر إسلامي)
- **الذهب:** `AppColors.secondary` (#D4AF37)
- **الخلفية:** gradient من `AppColors.splashLightGradient` في الـ onboarding
- **الأيقونة:** هلال + نجمة أو مسجد (Lottie: `ImageAssets.mosqueAnimation`)

### المزاج البصري العام
- **Luxury Islamic Minimal** — هادئ، فخم، عميق
- خلفيات داكنة مع تفاصيل ذهبية في الـ onboarding
- بطاقات بيضاء ناصعة مع ظلال خفيفة في الـ auth screens
- الخط العربي **Tajawal** والإنجليزي **Poppins** (موجودان في `AppFonts`)
- حركات سلسة وخفيفة (AnimatedOpacity, SlideTransition)

---

## 📁 STRUCTURE

```
features/
├── auth/
│   ├── controller/
│   │   └── auth_controller.dart
│   ├── data/
│   │   ├── helpers/
│   │   │   ├── auth_error_messages.dart
│   │   │   └── auth_validation.dart
│   │   ├── models/
│   │   │   ├── user_model.dart
│   │   │   └── user_privacy_settings.dart
│   │   ├── repositories/
│   │   │   └── user_repository.dart
│   │   └── services/
│   │       └── auth_service.dart
│   └── presentation/
│       ├── bindings/
│       │   └── auth_binding.dart
│       ├── screens/
│       │   ├── login_screen.dart
│       │   ├── register_screen.dart
│       │   └── profile_setup_screen.dart
│       └── widgets/
│           └── login_widgets.dart
│
└── onboarding/
    ├── controller/
    │   ├── onboarding_controller.dart
    │   └── onboarding_data.dart
    └── presentation/
        ├── bindings/
        │   └── onboarding_binding.dart
        ├── screens/
        │   ├── onboarding_screen.dart      ← Shell
        │   ├── welcome_page.dart
        │   ├── features_page.dart
        │   ├── permissions_page.dart
        │   └── profile_setup_page.dart
        └── widgets/
            └── onboarding_widgets.dart
```

---

## 📱 SCREENS SPEC

### 1. Onboarding Flow (4 خطوات) — NO Family step

#### الخطوة 1 — Welcome Page
```
خلفية: gradient من AppColors.splashDarkGradient
مركز: Lottie → ImageAssets.mosqueAnimation أو ImageAssets.familyPrayingAnimation
عنوان: 'onboarding_welcome_title'.tr
وصف:  'onboarding_welcome_desc'.tr
زر:   AppButton.fullWidth → 'get_started'.tr
زر ثانوي: TextButton → 'skip'.tr (في الخطوة الأولى فقط)
```

#### الخطوة 2 — Features Page
```
خلفية: فاتحة (AppColors.lightBackground)
3 بطاقات تعرض الميزات (استخدم Icons — لا Lottie مفقود):
  - Icons.schedule + "مواقيت الصلاة الدقيقة"
  - Icons.family_restroom + "تابع عائلتك"
  - Icons.explore + "اتجاه القبلة"
كل بطاقة: Container مستدير، لون خفيف من AppColors.primary
```

#### الخطوة 3 — Permissions Page
```
أيقونة: Icons.location_on_rounded (كبيرة، AppColors.primary)
عنوان: 'permissions_title'.tr
وصف: 'permissions_location_desc'.tr
زر رئيسي: "منح الإذن" → Location + Notification
ملاحظة: 'permissions_why'.tr
```

#### الخطوة 4 — Profile Setup Page (داخل Onboarding)
```
= نفس profile_setup لكن بتخطيط Onboarding
حقول: الاسم فقط (الصورة اختيارية)
زر: "ابدأ رحلتك" → يكمل الـ onboarding
```

---

### 2. Login Screen

```
تخطيط:
  - Header: خلفية AppColors.primary + شعار
             Image.asset(ImageAssets.appLogo, errorBuilder: → Icon(Icons.mosque))
             ارتفاع ~30% من الشاشة
  - Body:   بطاقة بيضاء بـ borderRadius 32px تعلو على الـ header

المحتوى:
  - عنوان: 'login_title'.tr (AppFonts.headlineMedium)
  - EmailTextField
  - PasswordTextField
  - TextButton "نسيت كلمة المرور؟" (يمين)
  - AppButton.fullWidth → 'login'.tr
  - Divider + "أو"
  - زر Google (outlined)
  - "ليس لديك حساب؟ سجّل الآن" → Register
```

---

### 3. Register Screen

```
نفس تخطيط Login:
  - حقول: الاسم + الإيميل + كلمة المرور + تأكيد كلمة المرور
  - زر: 'register'.tr
  - رابط العودة للـ Login
```

---

### 4. Profile Setup Screen

```
- صورة البروفايل (دائرة، اختيارية)
- NameTextField
- (اختياري) DatePicker, Gender selector
- AppButton.fullWidth → 'save_profile'.tr
```

---

## ⚙️ CONTROLLER SPEC

### auth_controller.dart
```dart
final emailController = TextEditingController();
final passwordController = TextEditingController();
final nameController = TextEditingController();
final confirmPasswordController = TextEditingController();
final formKey = GlobalKey<FormState>();
final isLoading = false.obs;
final isGoogleLoading = false.obs;

Future<void> login();
Future<void> register();
Future<void> loginWithGoogle();
Future<void> logout();
Future<void> setupProfile();
void navigateToRegister();
void navigateToLogin();
void navigateToForgotPassword(); // stub
```

### onboarding_controller.dart
```dart
final currentPage = 0.obs;
final pageController = PageController();
// 4 steps only: welcome, features, permissions, profile_setup

void nextPage();
void previousPage();
void skipOnboarding();  // avoid duplicate name 'skip'
void complete();
bool get isLastPage;
bool get isFirstPage;
```

---

## 🌐 TRANSLATIONS — Add These Keys

### ar_translations.dart
```dart
'onboarding_welcome_title': 'أهلاً بك في قُرب',
'onboarding_welcome_desc': 'تتبّع صلاتك وتواصل مع عائلتك في رحلة روحية مشتركة',
'get_started': 'ابدأ الآن',
'skip': 'تخطّي',
'next': 'التالي',
'back': 'رجوع',
'features_title': 'كل ما تحتاجه',
'features_prayer_times': 'مواقيت الصلاة',
'features_prayer_times_desc': 'دقيقة حسب موقعك',
'features_family': 'العائلة',
'features_family_desc': 'تابع صلوات من تحب',
'features_qibla': 'القبلة',
'features_qibla_desc': 'اتجاه دقيق في أي مكان',
'permissions_title': 'نحتاج إذنك',
'permissions_location_desc': 'لحساب مواقيت الصلاة الدقيقة حسب موقعك',
'permissions_why': 'لن نشارك موقعك مع أحد',
'grant_permission': 'منح الإذن',
'setup_profile_title': 'أخبرنا عنك',
'start_journey': 'ابدأ رحلتك',
'login_title': 'مرحباً بعودتك',
'login_subtitle': 'سجّل دخولك للمتابعة',
'register_title': 'انضم إلى قُرب',
'register_subtitle': 'أنشئ حسابك الآن',
'email_label': 'البريد الإلكتروني',
'password_label': 'كلمة المرور',
'confirm_password_label': 'تأكيد كلمة المرور',
'name_label': 'الاسم',
'forgot_password': 'نسيت كلمة المرور؟',
'login': 'دخول',
'register': 'إنشاء حساب',
'or': 'أو',
'login_with_google': 'الدخول بحساب Google',
'no_account': 'ليس لديك حساب؟',
'have_account': 'لديك حساب؟',
'sign_up_now': 'سجّل الآن',
'sign_in_now': 'سجّل دخولك',
'save_profile': 'حفظ وإكمال',
'profile_setup_title': 'أخبرنا عنك',
'profile_photo': 'صورة البروفايل',
'change_photo': 'تغيير الصورة',
'enter_email': 'أدخل بريدك الإلكتروني',
'invalid_email': 'البريد الإلكتروني غير صالح',
'enter_password': 'أدخل كلمة المرور',
'password_min_length': 'كلمة المرور 6 أحرف على الأقل',
'passwords_dont_match': 'كلمتا المرور غير متطابقتين',
'enter_name': 'أدخل اسمك',
'name_min_length': 'الاسم أحرفان على الأقل',
```

### en_translations.dart
```dart
'onboarding_welcome_title': 'Welcome to Qurb',
'onboarding_welcome_desc': 'Track your prayers and connect with your family on a shared spiritual journey',
'get_started': 'Get Started',
'skip': 'Skip',
'next': 'Next',
'back': 'Back',
'features_title': 'Everything You Need',
'features_prayer_times': 'Prayer Times',
'features_prayer_times_desc': 'Accurate for your location',
'features_family': 'Family',
'features_family_desc': 'Follow your loved ones',
'features_qibla': 'Qibla',
'features_qibla_desc': 'Accurate direction anywhere',
'permissions_title': 'We Need Your Permission',
'permissions_location_desc': 'To calculate accurate prayer times based on your location',
'permissions_why': 'We never share your location',
'grant_permission': 'Grant Permission',
'setup_profile_title': 'Tell Us About You',
'start_journey': 'Start Your Journey',
'login_title': 'Welcome Back',
'login_subtitle': 'Sign in to continue',
'register_title': 'Join Qurb',
'register_subtitle': 'Create your account',
'email_label': 'Email',
'password_label': 'Password',
'confirm_password_label': 'Confirm Password',
'name_label': 'Name',
'forgot_password': 'Forgot Password?',
'login': 'Sign In',
'register': 'Create Account',
'or': 'or',
'login_with_google': 'Continue with Google',
'no_account': "Don't have an account?",
'have_account': 'Already have an account?',
'sign_up_now': 'Sign Up',
'sign_in_now': 'Sign In',
'save_profile': 'Save & Continue',
'profile_setup_title': 'Tell Us About You',
'profile_photo': 'Profile Photo',
'change_photo': 'Change Photo',
'enter_email': 'Enter your email',
'invalid_email': 'Invalid email address',
'enter_password': 'Enter your password',
'password_min_length': 'Password must be at least 6 characters',
'passwords_dont_match': 'Passwords do not match',
'enter_name': 'Enter your name',
'name_min_length': 'Name must be at least 2 characters',
```

---

## 🖼️ ASSETS — Use Existing Only

### ImageAssets (lib/core/constants/image_assets.dart)
```dart
// App branding — use with errorBuilder
ImageAssets.appLogo    // assets/icons/salah_app_logo.png
ImageAssets.appIcon    // assets/icons/app_icon.png

// Lottie — EXIST and work
ImageAssets.mosqueAnimation         // assets/animations/mosque.json
ImageAssets.familyPrayingAnimation  // assets/animations/dadwithfatherareprayer.json
ImageAssets.successAnimation        // assets/animations/Success.json  (S capital)
ImageAssets.loadingAnimation        // assets/animations/loading.json
ImageAssets.confettiAnimation       // assets/animations/Confetti.json

// Images in assets/images — FOLDER IS EMPTY; paths exist in ImageAssets but files don't
// Always use errorBuilder for: defaultAvatar, onboardingWelcome, etc.
```

### Onboarding Lottie Mapping
- **welcome** → `ImageAssets.mosqueAnimation` or `ImageAssets.familyPrayingAnimation`
- **features** → use `Icons` (no animation)
- **permissions** → use `Icons.location_on_rounded`
- **profile** → use `Icons.person`
- **complete** → `ImageAssets.successAnimation`

---

## 🎨 STYLING RULES

```dart
// ✅ صح
AppColors.primary
AppFonts.headlineLarge.withColor(AppColors.white)
AppDimensions.paddingLG
AppDimensions.radiusMD

// ❌ غلط  
Color(0xFF1B5E20)
TextStyle(fontSize: 24)
EdgeInsets.all(16)
BorderRadius.circular(12)
```

---

## 🔑 ROUTES

```dart
AppRoutes.splash       // '/splash'
AppRoutes.onboarding   // '/onboarding'
AppRoutes.login        // '/login'
AppRoutes.register     // '/register'
AppRoutes.profileSetup // '/profile-setup'
AppRoutes.dashboard    // '/dashboard'

// Logic: !onboardingCompleted → /onboarding
//        !loggedIn → /login
//        else → /dashboard
```

---

## 📐 RESPONSIVE

```dart
MediaQuery.of(context).size.height
MediaQuery.of(context).size.width
MediaQuery.of(context).padding.top
AppDimensions.screenPadding(context)
```

---

## ✅ CHECKLIST

- [ ] كل النصوص تستخدم `.tr`
- [ ] كل الألوان من `AppColors`
- [ ] كل الـ TextStyles من `AppFonts`
- [ ] كل الأبعاد من `AppDimensions`
- [ ] كل المسارات من `ImageAssets` + `errorBuilder` للصور
- [ ] كل مفاتيح التخزين من `StorageKeys`
- [ ] Controllers تستخدم `sl<ServiceName>()`
- [ ] Bindings تسجّل الـ controllers
- [ ] `dispose` للـ TextEditingControllers في `onClose()`
- [ ] `formKey` للتحقق
- [ ] `isLoading` يوقف الأزرار
- [ ] رسائل الخطأ عبر `ToastService.error()`
- [ ] Onboarding لا يظهر بعد الإكمال
- [ ] RTL يعمل صح

---

## 🚀 START ORDER

1. `ar_translations.dart` + `en_translations.dart`
2. `image_assets.dart` (add missing paths if needed, keep errorBuilder in mind)
3. `onboarding_data.dart` — 4 steps, use existing Lottie
4. `onboarding_controller.dart` + `onboarding_binding.dart`
5. Onboarding pages (welcome → features → permissions → profile_setup)
6. `onboarding_screen.dart` (Shell)
7. `auth_controller.dart` + `auth_binding.dart`
8. `login_screen.dart`
9. `register_screen.dart`
10. `profile_setup_screen.dart`

**بعد كل ملف: تأكد أنه يبني بدون أخطاء قبل الانتقال للتالي.**

---

## 🔄 ERROR HANDLING FLOW

```
Controller (login/register) 
  → calls AuthService 
  → on failure: AuthService.errorMessage (from AuthErrorMessages.fromCode)
  → Controller: ToastService.error(controller.errorMessage) + errorMessage.obs للعرض في الـ UI
  → Never show raw Firebase exceptions to user
```

---

## 📝 VALIDATION FLOW

- **Form level:** `formKey.currentState?.validate()` قبل أي عملية
- **AuthValidation:** يستخدم مفاتيح الترجمة (`'enter_email'.tr`) — يتطلب Get.tr
- **AuthErrorMessages:** يرجّع رسائل مترجمة عبر `AuthErrorMessages.fromCode(e.code)` (يستخدم .tr داخلياً)
- **Password:** حد أدنى 6 أحرف (توافق مع Firebase)

---

## 📦 WIDGET QUICK REFERENCE

| الوظيفة | الـ Widget | الاستيراد |
|---------|------------|-----------|
| زر رئيسي | `AppButton.fullWidth(text: 'login'.tr, onPressed: ..., isLoading: ...)` | `app_button.dart` |
| زر outlined | `AppButton(text: '...', type: AppButtonType.outlined)` | `app_button.dart` |
| حقل إيميل | `EmailTextField(controller: c.emailController)` | `app_text_field.dart` |
| حقل كلمة مرور | `PasswordTextField(controller: c.passwordController)` | `app_text_field.dart` |
| حقل اسم | `NameTextField(controller: c.nameController)` | `app_text_field.dart` |
| رسالة نجاح | `ToastService.success('...')` | `toast_service.dart` |
| رسالة خطأ | `ToastService.error('...', '...')` | `toast_service.dart` |
| صورة مع fallback | `Image.asset(path, errorBuilder: (_, __, ___) => Icon(Icons.mosque))` | - |
