import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:get/get.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CLOUDINARY SERVICE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// ✅ ضروري — يتعامل مع رفع الصور وتحويل روابطها.
//
// يُستخدَم في:
//   • صورة البروفايل   → uploadProfileImage()
//   • صورة مجموعة العائلة → uploadGroupImage()
//
// لماذا Cloudinary وليس Firebase Storage؟
//   Cloudinary يوفّر تحويل الصور on-the-fly عبر الرابط فقط (crop/resize/quality)
//   بدون أي كود إضافي، مما يقلل استهلاك البيانات على الجوال.
//
// الإعداد المطلوب:
//   1. أنشئ Upload Preset بنوع "Unsigned" في Cloudinary Dashboard
//   2. ضع اسم الـ Cloud واسم الـ Preset في الثوابت أدناه
//   ⚠️  لا تضع API Secret في الكود — cloudinary_public تعمل بدونه
//
// الاستخدام:
//   final url = await CloudinaryService.to.uploadProfileImage(file, userId);
//   final thumb = CloudinaryService.to.getThumbnailUrl(url, size: 100);
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class CloudinaryService extends GetxService {
  // اختصار للوصول السريع
  static CloudinaryService get to => Get.find();

  // ══════════════════════════════════════════════════════════════
  // CONFIGURATION — غيّرها حسب حسابك
  // ══════════════════════════════════════════════════════════════

  static const String _cloudName = 'dbialkq5t';
  static const String _uploadPreset = 'salah_app';

  /// المجلد الجذر في Cloudinary — كل الصور ترفع تحته
  static const String _rootFolder = 'qurb_app';

  // ══════════════════════════════════════════════════════════════
  // OBSERVABLE STATE
  // ══════════════════════════════════════════════════════════════

  /// هل يجري رفع صورة الآن (لإظهار progress indicator في الـ UI)
  final isUploading = false.obs;

  /// تقدم الرفع من 0.0 إلى 1.0
  final uploadProgress = 0.0.obs;

  /// آخر رسالة خطأ (فارغة إذا لا يوجد خطأ)
  final errorMessage = ''.obs;

  // ══════════════════════════════════════════════════════════════
  // PRIVATE
  // ══════════════════════════════════════════════════════════════

  late final CloudinaryPublic _cloudinary;
  bool _isInitialized = false;

  // ══════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ══════════════════════════════════════════════════════════════

  Future<CloudinaryService> init() async {
    if (_isInitialized) return this;
    _isInitialized = true;

    _cloudinary = CloudinaryPublic(
      _cloudName,
      _uploadPreset,
      cache: false, // لا نريد cache لأن كل رفع يُنتج رابطاً جديداً
    );

    return this;
  }

  // ══════════════════════════════════════════════════════════════
  // UPLOAD — صورة بروفايل
  // ══════════════════════════════════════════════════════════════

  /// رفع صورة بروفايل المستخدم.
  /// تُخزَّن في: qurb_app/profiles/{userId}/
  /// ترجع الـ URL الآمن (https) أو null عند الفشل.
  Future<String?> uploadProfileImage(File imageFile, String userId) async {
    return _uploadFile(imageFile, folder: '$_rootFolder/profiles/$userId');
  }

  // ══════════════════════════════════════════════════════════════
  // UPLOAD — صورة مجموعة
  // ══════════════════════════════════════════════════════════════

  /// رفع صورة مجموعة العائلة.
  /// تُخزَّن في: qurb_app/groups/{groupId}/
  Future<String?> uploadGroupImage(File imageFile, String groupId) async {
    return _uploadFile(imageFile, folder: '$_rootFolder/groups/$groupId');
  }

  // ══════════════════════════════════════════════════════════════
  // UPLOAD — من bytes (للصور المضغوطة أو web)
  // ══════════════════════════════════════════════════════════════

  /// رفع صورة من bytes مباشرة بدون ملف.
  /// مفيد عند ضغط الصورة في الذاكرة قبل الرفع.
  Future<String?> uploadFromBytes(
    List<int> bytes,
    String fileName, {
    String? folder,
  }) async {
    try {
      isUploading.value = true;
      errorMessage.value = '';

      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromBytesData(
          bytes,
          identifier: fileName,
          folder: folder ?? _rootFolder,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      return response.secureUrl;
    } catch (e) {
      errorMessage.value = e.toString();
      return null;
    } finally {
      isUploading.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // URL TRANSFORMATIONS — تعديل الرابط بدون أي رفع إضافي
  // ══════════════════════════════════════════════════════════════
  //
  // Cloudinary يسمح بتعديل الصورة عبر تغيير الرابط فقط.
  // مثال: /upload/c_thumb,w_150/ بدلاً من /upload/
  //
  // هذا يعني: لا داعي لتخزين نسخ متعددة، رابط واحد + تحويل = أي حجم.

  /// صورة مصغّرة مربعة مع تركيز على الوجه (للـ avatar)
  String getThumbnailUrl(String originalUrl, {int size = 150}) =>
      _transform(originalUrl, 'c_thumb,w_$size,h_$size,g_face');

  /// صورة بروفايل دائرية (للـ profile picture)
  String getProfileImageUrl(String originalUrl, {int size = 200}) =>
      _transform(originalUrl, 'c_fill,w_$size,h_$size,g_face,r_max');

  /// صورة محسّنة للعرض (جودة أقل = تحميل أسرع)
  String getOptimizedUrl(String originalUrl, {int quality = 80}) =>
      _transform(originalUrl, 'q_$quality,f_auto');

  /// تغيير عرض الصورة مع الحفاظ على النسبة
  String getResizedUrl(String originalUrl, {int maxWidth = 800}) =>
      _transform(originalUrl, 'c_scale,w_$maxWidth');

  // ══════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════

  /// هل هذا الرابط من Cloudinary؟
  bool isCloudinaryUrl(String url) => url.contains('cloudinary.com');

  /// استخراج الـ Public ID من رابط Cloudinary (مفيد للحذف مستقبلاً)
  String? getPublicIdFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      final uploadIndex = segments.indexOf('upload');

      if (uploadIndex == -1 || uploadIndex >= segments.length - 1) return null;

      // تخطّي رقم الإصدار إذا بدأ بـ 'v' (مثل v1234567)
      int startIndex = uploadIndex + 1;
      if (segments[startIndex].startsWith('v') &&
          int.tryParse(segments[startIndex].substring(1)) != null) {
        startIndex++;
      }

      final publicIdWithExt = segments.sublist(startIndex).join('/');
      final lastDot = publicIdWithExt.lastIndexOf('.');

      return lastDot != -1
          ? publicIdWithExt.substring(0, lastDot)
          : publicIdWithExt;
    } catch (_) {
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // PRIVATE METHODS
  // ══════════════════════════════════════════════════════════════

  /// منطق الرفع المشترك لجميع upload methods
  Future<String?> _uploadFile(File file, {required String folder}) async {
    try {
      isUploading.value = true;
      uploadProgress.value = 0.0;
      errorMessage.value = '';

      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          folder: folder,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      uploadProgress.value = 1.0;
      return response.secureUrl;
    } catch (e) {
      errorMessage.value = e.toString();
      return null;
    } finally {
      isUploading.value = false;
    }
  }

  /// إدراج transformation في رابط Cloudinary بعد /upload/
  String _transform(String originalUrl, String transformation) {
    if (!originalUrl.contains('/upload/')) return originalUrl;
    return originalUrl.replaceFirst('/upload/', '/upload/$transformation/');
  }
}
