import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:get/get.dart';

/// Service for uploading and managing images with Cloudinary
class CloudinaryService extends GetxService {
  // ============================================================
  // CONFIGURATION
  // ============================================================
  
  /// Your Cloudinary cloud name
  static const String _cloudName = 'dbialkqit';
  
  /// Your Cloudinary upload preset (unsigned)
  static const String _uploadPreset = 'salah_app';

  // ============================================================
  // PRIVATE
  // ============================================================
  
  late final CloudinaryPublic _cloudinary;

  // ============================================================
  // OBSERVABLE STATE
  // ============================================================
  
  final isUploading = false.obs;
  final uploadProgress = 0.0.obs;
  final errorMessage = ''.obs;

  // ============================================================
  // INITIALIZATION
  // ============================================================
  
  /// Initialize the service
  Future<CloudinaryService> init() async {
    _cloudinary = CloudinaryPublic(
      _cloudName,
      _uploadPreset,
      cache: false,
    );
    return this;
  }

  // ============================================================
  // UPLOAD METHODS
  // ============================================================
  
  /// Upload image file
  Future<String?> uploadImage(File imageFile, {String? folder}) async {
    try {
      isUploading.value = true;
      uploadProgress.value = 0;
      errorMessage.value = '';

      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: folder ?? 'qurb_app',
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

  /// Upload user profile image
  Future<String?> uploadProfileImage(File imageFile, String userId) async {
    return await uploadImage(
      imageFile,
      folder: 'qurb_app/profiles/$userId',
    );
  }

  /// Upload group image
  Future<String?> uploadGroupImage(File imageFile, String groupId) async {
    return await uploadImage(
      imageFile,
      folder: 'qurb_app/groups/$groupId',
    );
  }

  /// Upload from bytes (for web or compressed images)
  Future<String?> uploadFromBytes(List<int> bytes, String fileName, {String? folder}) async {
    try {
      isUploading.value = true;
      errorMessage.value = '';

      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromBytesData(
          bytes,
          identifier: fileName,
          folder: folder ?? 'qurb_app',
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

  // ============================================================
  // IMAGE TRANSFORMATION URLs
  // ============================================================
  
  /// Get thumbnail URL (cropped and resized)
  String getThumbnailUrl(String originalUrl, {int size = 150}) {
    return _transformUrl(originalUrl, 'c_thumb,w_$size,h_$size,g_face');
  }

  /// Get profile image URL (circular crop)
  String getProfileImageUrl(String originalUrl, {int size = 200}) {
    return _transformUrl(originalUrl, 'c_fill,w_$size,h_$size,g_face,r_max');
  }

  /// Get optimized image URL
  String getOptimizedUrl(String originalUrl, {int quality = 80}) {
    return _transformUrl(originalUrl, 'q_$quality,f_auto');
  }

  /// Get resized image URL (maintain aspect ratio)
  String getResizedUrl(String originalUrl, {int maxWidth = 800}) {
    return _transformUrl(originalUrl, 'c_scale,w_$maxWidth');
  }

  /// Transform Cloudinary URL with given transformation
  String _transformUrl(String originalUrl, String transformation) {
    // Cloudinary URL format: https://res.cloudinary.com/cloud_name/image/upload/...
    // Insert transformation after /upload/
    if (!originalUrl.contains('/upload/')) {
      return originalUrl;
    }
    
    return originalUrl.replaceFirst(
      '/upload/',
      '/upload/$transformation/',
    );
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================
  
  /// Check if URL is a Cloudinary URL
  bool isCloudinaryUrl(String url) {
    return url.contains('cloudinary.com');
  }

  /// Get public ID from Cloudinary URL
  String? getPublicIdFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      final uploadIndex = segments.indexOf('upload');
      if (uploadIndex != -1 && uploadIndex < segments.length - 1) {
        // Skip version if present (starts with 'v')
        int startIndex = uploadIndex + 1;
        if (segments[startIndex].startsWith('v')) {
          startIndex++;
        }
        // Join remaining segments (folder/filename)
        final publicIdWithExt = segments.sublist(startIndex).join('/');
        // Remove extension
        final lastDot = publicIdWithExt.lastIndexOf('.');
        if (lastDot != -1) {
          return publicIdWithExt.substring(0, lastDot);
        }
        return publicIdWithExt;
      }
    } catch (e) {
      // Invalid URL
    }
    return null;
  }
}
