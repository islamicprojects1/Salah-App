import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/helpers/date_time_helper.dart';
import 'package:salah/features/notifications/controller/notifications_controller.dart';

class NotificationsScreen extends GetView<NotificationsController> {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('family_pulse'.tr),
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        final notifications = controller.notifications;

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  size: 64,
                  color: colorScheme.primary.withValues(alpha: 0.2),
                ),
                const SizedBox(height: AppDimensions.paddingMD),
                Text(
                  'no_data'.tr,
                  style: AppFonts.titleMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppDimensions.paddingMD),
          itemCount: notifications.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppDimensions.paddingSM),
          itemBuilder: (context, index) {
            final e = notifications[index];
            final isCelebration = e.type == PulseEventType.familyCelebration;

            return Card(
              elevation: AppDimensions.cardElevationLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingMD),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isCelebration
                            ? AppColors.amber.withValues(alpha: 0.1)
                            : colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCelebration
                            ? Icons.celebration
                            : e.type == PulseEventType.encouragement
                            ? Icons.thumb_up
                            : Icons.mosque,
                        size: 20,
                        color: isCelebration
                            ? AppColors.amber
                            : colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.paddingMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.displayText,
                            style: AppFonts.bodyLarge.copyWith(
                              fontWeight: isCelebration
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _relativeTime(e.timestamp),
                            style: AppFonts.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'now_label'.tr;
    if (diff.inMinutes < 60) return '${diff.inMinutes} ${'minutes_short'.tr}';
    if (diff.inHours < 24) return '${diff.inHours} ${'hours_short'.tr}';
    return DateTimeHelper.formatTime12(time);
  }
}
