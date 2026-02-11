import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:salah/core/services/auth_service.dart';
import 'package:salah/core/services/cloudinary_service.dart';
import 'package:salah/data/repositories/user_repository.dart';

class ProfileController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final CloudinaryService _cloudinaryService = Get.find<CloudinaryService>();
  final UserRepository _userRepository = Get.find<UserRepository>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();

  // Password Change Controllers
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxString userImage = ''.obs;
  final RxDouble uploadProgress = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
    
    // Listen to upload progress from CloudinaryService
    ever(_cloudinaryService.uploadProgress, (progress) {
      uploadProgress.value = progress;
    });
  }

  void _loadUserData() {
    final user = _authService.currentUser.value;
    if (user != null) {
      nameController.text = user.displayName ?? '';
      emailController.text = user.email ?? '';
      userImage.value = user.photoURL ?? '';
    }
  }

  Future<void> updateProfile() async {
    if (nameController.text.trim().isEmpty) {
      Get.snackbar('خطأ', 'يرجى إدخال الاسم');
      return;
    }

    try {
      isLoading.value = true;
      
      final displayName = nameController.text.trim();
      final photoURL = userImage.value;
      final userId = _authService.userId;

      if (userId == null) throw Exception('User not logged in');

      // 1. Update Firebase Auth (for Drawer/Display)
      final success = await _authService.updateProfile(
        displayName: displayName,
        photoURL: photoURL,
      );

      if (!success) throw Exception('Failed to update auth profile');

      // 2. Update Firestore (for Family/Groups)
      await _userRepository.updateUserProfile(
        userId: userId,
        updates: {
          'name': displayName,
          'photoUrl': photoURL,
          'lastUpdated': DateTime.now().toIso8601String(),
        },
      );

      Get.snackbar('نجاح', 'تم تحديث الملف الشخصي بنجاح');
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تحديث الملف الشخصي: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60, // Better compression for performance
      maxWidth: 800,
    );

    if (image != null) {
      try {
        isLoading.value = true;
        uploadProgress.value = 0.01; // Start progress
        
        final userId = _authService.userId;
        if (userId == null) return;

        // Upload to Cloudinary
        final String? url = await _cloudinaryService.uploadProfileImage(
          File(image.path), 
          userId
        );

        if (url != null) {
          userImage.value = url;
          // Proactively update user profile with new image
          await updateProfile();
          Get.snackbar('نجاح', 'تم رفع وتحديث الصورة بنجاح');
        } else {
          final error = _cloudinaryService.errorMessage.value;
          Get.snackbar('خطأ الرفع', error.isNotEmpty ? error : 'فشل رفع الصورة، يرجى المحاولة لاحقاً');
        }
      } catch (e) {
        Get.snackbar('خطأ تقني', 'حدث خطأ غير متوقع: $e');
      } finally {
        isLoading.value = false;
        uploadProgress.value = 0.0;
      }
    }
  }

  Future<void> changePassword() async {
    if (newPasswordController.text != confirmPasswordController.text) {
      Get.snackbar('error'.tr, 'passwords_do_not_match'.tr);
      return;
    }

    if (newPasswordController.text.length < 8) {
      Get.snackbar('error'.tr, 'password_too_short'.tr);
      return;
    }

    try {
      isLoading.value = true;
      await _authService.updatePassword(newPasswordController.text);

      Get.back(); // Close dialog
      Get.snackbar('success'.tr, 'password_changed'.tr);

      // Clear fields
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
    } catch (e) {
      Get.snackbar('error'.tr, 'password_change_failed'.tr);
    } finally {
      isLoading.value = false;
    }
  }
}
