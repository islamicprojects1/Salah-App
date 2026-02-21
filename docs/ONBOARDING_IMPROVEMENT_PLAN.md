# 📋 خطة تحسين Onboarding — كاملة

## 1. الوضع الحالي والثغرات

### 1.1 Lottie — موجود / غير موجود

| الخطوة | الملف المستخدم حالياً | الحالة | البديل |
|--------|------------------------|--------|--------|
| welcome | `welcome.json` | ❌ غير موجود | `ImageAssets.mosqueAnimation` |
| features | `features.json` | ❌ غير موجود | `ImageAssets.mosqueAnimation` أو Icons |
| family | `family.json` | ❌ غير موجود | `ImageAssets.familyPrayingAnimation` |
| permissions | `location.json` | ❌ غير موجود | `Icons.location_on_rounded` |
| profileSetup | `profile.json` | ❌ غير موجود | `Icons.person_rounded` |
| complete | `Success.json` | ✅ موجود | `ImageAssets.successAnimation` |

**Lottie الموجودة:**
- `mosque.json` (ImageAssets.mosqueAnimation)
- `dadwithfatherareprayer.json` (ImageAssets.familyPrayingAnimation)
- `Success.json` (ImageAssets.successAnimation)
- `loading.json`, `Confetti.json`, `infinite_loop.json`

### 1.2 صور Onboarding — مجلد `assets/images` فارغ

| المسار في ImageAssets | الحالة |
|-----------------------|--------|
| `onboarding_welcome.png` | ❌ غير موجود |
| `onboarding_location.png` | ❌ غير موجود |
| `onboarding_community.png` | ❌ غير موجود |

**الحل:** استخدام Lottie أو Icons كبديل حتى تُضاف الصور.

---

## 2. الثوابت المستخدمة من `core/constants`

### 2.1 AppColors (lib/core/theme/app_colors.dart)

```dart
// للخلفيات
AppColors.primary
AppColors.secondary
AppColors.splashLightGradient  // خلفية فاتحة
AppColors.splashDarkGradient   // خلفية داكنة

// للـ onboarding
AppColors.feature1   // #6366F1
AppColors.feature2   // #10B981
AppColors.feature3   // #F59E0B
AppColors.onboarding1Start, onboarding1End
AppColors.onboarding2Start, onboarding2End
AppColors.onboarding3Start, onboarding3End

// عام
AppColors.textPrimary, textSecondary
AppColors.success, surface
```

### 2.2 AppDimensions (lib/core/constants/app_dimensions.dart)

```dart
// Onboarding
AppDimensions.imageOnboarding        // 280
AppDimensions.iconOnboardingPlaceholder  // 120
AppDimensions.dotSize                // 8
AppDimensions.dotWidthActive         // 24

// Padding
AppDimensions.paddingXS, paddingSM, paddingMD
AppDimensions.paddingLG, paddingXL, paddingXXL
AppDimensions.screenPaddingH(context), screenPaddingV(context)

// Radius
AppDimensions.radiusSM, radiusMD, radiusLG, radiusXL, radiusXXL

// Spacing
AppDimensions.spaceXS .. spaceHuge
AppDimensions.spaceResponsive(context)

// Animation
AppDimensions.durationFast   // 150ms
AppDimensions.durationNormal // 250ms
AppDimensions.durationSlow   // 350ms
```

### 2.3 ImageAssets (lib/core/constants/image_assets.dart)

```dart
ImageAssets.mosqueAnimation
ImageAssets.familyPrayingAnimation
ImageAssets.successAnimation
ImageAssets.loadingAnimation
```

### 2.4 StorageKeys (lib/core/constants/storage_keys.dart)

```dart
StorageKeys.onboardingCompleted
StorageKeys.isFirstTime
```

### 2.5 AppFonts (lib/core/theme/app_fonts.dart)

```dart
AppFonts.headlineLarge, headlineMedium
AppFonts.titleLarge, titleMedium
AppFonts.bodyLarge, bodyMedium, bodySmall
```

---

## 3. خطة التنفيذ (بالترتيب)

### المرحلة 1 — إصلاح onboarding_data.dart

**الهدف:** استخدام فقط الملفات الموجودة.

```
1. welcome   → ImageAssets.mosqueAnimation
2. features  → ImageAssets.mosqueAnimation (أو null + Icons)
3. family    → ImageAssets.familyPrayingAnimation
4. permissions → null (استخدام Icons بدل Lottie)
5. profileSetup → null (استخدام Icons)
6. complete  → ImageAssets.successAnimation
```

### المرحلة 2 — توحيد OnboardingPageLayout

- استخدام `AppDimensions` لكل padding/radius/spacing
- استخدام `AppColors` لكل لون
- استخدام `AppFonts` لكل نص
- إضافة `errorBuilder` لـ Lottie مع fallback أيقونة

### المرحلة 3 — تحسين الصفحات

| الصفحة | التحسين |
|--------|---------|
| WelcomePage | خلفية gradient من splashDarkGradient، زر "ابدأ" واضح |
| FeaturesPage | استخدام feature1/2/3، استخدام OnboardingCard |
| FamilyPage | استخدام familyPrayingAnimation، AppColors.secondary |
| PermissionsPage | استخدام AppDimensions للبطاقات والأيقونات |
| ProfileSetupPage | استخدام AppTextField من core بدل TextField |

### المرحلة 4 — أصول مفقودة (إنشاءها)

#### 4.1 صور PNG للـ Onboarding (اختياري)

إذا أردت إضافة صور:

- `assets/images/onboarding_welcome.png` — مسجد أو هلال
- `assets/images/onboarding_location.png` — خريطة أو موقع
- `assets/images/onboarding_community.png` — عائلة أو جماعة

**بديل فوري:** الاستمرار بـ Lottie + Icons حتى توفر الصور.

#### 4.2 Lottie إضافية (اختياري)

- `welcome.json` — رسوم ترحيبية
- `features.json` — عرض ميزات
- `location.json` — موقع/خريطة

يمكن تنزيلها من LottieFiles وتنسيقها مع الهوية البصرية.

---

## 4. هيكل الملفات بعد التحسين

```
features/onboarding/
├── controller/
│   ├── onboarding_controller.dart   # تحسين: استخدام StorageKeys
│   └── onboarding_data.dart        # إصلاح: استخدام ImageAssets
└── presentation/
    ├── screens/
    │   ├── onboarding_screen.dart  # استخدام AppDimensions للـ dots
    │   ├── welcome_page.dart
    │   ├── features_page.dart
    │   ├── permissions_page.dart
    │   └── profile_setup_page.dart
    └── widgets/
        └── onboarding_widgets.dart # استخدام Constants بالكامل
```

---

## 5. قواعد الاستخدام

```dart
// ✅ صح
padding: EdgeInsets.all(AppDimensions.paddingLG)
borderRadius: BorderRadius.circular(AppDimensions.radiusMD)
color: AppColors.primary
Lottie.asset(ImageAssets.mosqueAnimation, errorBuilder: ...)
style: AppFonts.titleLarge

// ❌ خطأ
padding: EdgeInsets.all(16)
borderRadius: BorderRadius.circular(12)
color: Color(0xFF1B5E20)
Lottie.asset('assets/animations/welcome.json')  // ملف غير موجود
style: TextStyle(fontSize: 24)
```

---

## 6. التحقق النهائي

- [ ] كل Lottie يستخدم مسارات من ImageAssets
- [ ] كل Lottie له errorBuilder
- [ ] لا استخدام لأرقام ثابتة للأبعاد
- [ ] لا استخدام لألوان hex مباشرة
- [ ] كل النصوص عبر `.tr`
- [ ] مجلد assets/images إما يحتوي الصور أو نعتمد Lottie/Icons

---

## 7. أولوية التنفيذ

1. **عاجل:** إصلاح onboarding_data (استبدال الملفات غير الموجودة)
2. **مهم:** توحيد onboarding_widgets مع Constants
3. **مهم:** تحديث كل الصفحات لاستخدام Constants
4. **لاحقاً:** إضافة صور أو Lottie جديدة حسب الحاجة
