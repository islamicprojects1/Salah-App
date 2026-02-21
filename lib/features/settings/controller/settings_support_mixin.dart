import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:salah/core/feedback/app_feedback.dart';
import 'package:salah/features/auth/data/services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Mixin for support/feedback/social actions in settings
mixin SettingsSupportMixin on GetxController {
  AuthService get authService;

  void showAboutDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('about'.tr),
        content: Text('${'app_name'.tr}\n${'version'.tr}: 1.0.0'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('close'.tr)),
        ],
      ),
    );
  }

  Future<void> shareApp() async {
    try {
      await Share.share('share_app_text'.tr, subject: 'app_name'.tr);
    } catch (_) {}
  }

  void openRateApp() {
    AppFeedback.showSnackbar('rate_app'.tr, 'coming_soon_store'.tr);
  }

  Future<void> openSocialLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      AppFeedback.showError('error'.tr, 'could_not_open_link'.tr);
    }
  }

  Future<void> reportBug() async {
    final subject = 'email_report_subject'.tr;
    final body =
        'email_report_body'.trParams({'id': authService.userId ?? ''});
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'tazkifyai@gmail.com',
      query: _encodeQueryParameters({'subject': subject, 'body': body}),
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      AppFeedback.showError('error'.tr, 'could_not_open_email'.tr);
    }
  }

  Future<void> suggestFeature() async {
    final subject = 'email_suggest_subject'.tr;
    final body = 'email_suggest_body'.tr;
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'tazkifyai@gmail.com',
      query: _encodeQueryParameters({'subject': subject, 'body': body}),
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      AppFeedback.showError('error'.tr, 'could_not_open_email'.tr);
    }
  }

  Future<void> syncWithGoogleCalendar() async {
    Get.dialog(
      AlertDialog(
        title: Text('google_calendar_sync'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 48,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            Text('calendar_sync_desc'.tr, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'This feature will allow you to see prayer times directly in your Google Calendar.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('ok'.tr)),
        ],
      ),
    );
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map(
          (MapEntry<String, String> e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
  }
}
