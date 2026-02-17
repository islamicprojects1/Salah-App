import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/helpers/prayer_timing_helper.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/features/prayer/controller/missed_prayers_controller.dart';
import 'package:salah/features/prayer/data/models/prayer_time_model.dart';
import 'package:salah/features/prayer/data/services/qada_detection_service.dart';
import 'package:salah/features/prayer/presentation/widgets/missed_prayer_card.dart';

/// Screen for quickly logging missed/unlogged prayers
class MissedPrayersScreen extends GetView<MissedPrayersController> {
  const MissedPrayersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('missed_prayers'.tr), centerTitle: true),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: Lottie.asset(
              'assets/animations/loading.json',
              width: 150,
              height: 150,
            ),
          );
        }

        final hasData =
            controller.unloggedByDay.isNotEmpty ||
            controller.missedPrayers.isNotEmpty;
        if (!hasData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/animations/success.json',
                  width: 200,
                  height: 200,
                  repeat: false,
                ),
                const SizedBox(height: 16),
                Text(
                  'all_prayers_completed'.tr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'missed_prayers_title'.tr,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'missed_prayers_desc'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Content: by-day sections or legacy flat list
            Expanded(
              child: controller.unloggedByDay.isEmpty
                  ? _buildLegacyList(context)
                  : _buildByDayList(context),
            ),

            // Bottom Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: controller.skip,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('skip_for_now'.tr),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Obx(
                      () => ElevatedButton(
                        onPressed: controller.isSaving.value
                            ? null
                            : controller.saveAll,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: AppColors.primary,
                        ),
                        child: controller.isSaving.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'save_all'.tr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildLegacyList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.missedPrayers.length,
      itemBuilder: (context, index) {
        final prayer = controller.missedPrayers[index];
        final prayerType = prayer.prayerType;
        if (prayerType == null) return const SizedBox.shrink();
        return Obx(() {
          final status =
              controller.prayerStatuses[prayerType] ?? PrayerCardStatus.prayed;
          final timing =
              controller.prayerTimings[prayerType] ??
              PrayerTimingQuality.onTime;
          return MissedPrayerCard(
            prayer: prayer,
            status: status,
            timing: timing,
            onStatusChanged: (newStatus) {
              HapticFeedback.mediumImpact();
              controller.setPrayerStatus(prayerType, newStatus);
            },
            onTimingChanged: (newTiming) =>
                controller.setPrayerTiming(prayerType, newTiming),
            onDismissed: () => controller.missedPrayers.removeAt(index),
          );
        });
      },
    );
  }

  Widget _buildByDayList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.unloggedByDay.length,
      itemBuilder: (context, groupIndex) {
        final group = controller.unloggedByDay[groupIndex];
        return Obx(() {
          final isLogging = controller.isLoggingDay.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day header + "I prayed all" button
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(
                      '${group.label} (${group.count})',
                      style: AppFonts.titleSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: isLogging
                          ? null
                          : () => controller.logAllForDay(group),
                      icon: isLogging
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_outline, size: 18),
                      label: Text('qada_log_all'.tr),
                    ),
                  ],
                ),
              ),
              // Cards for this day
              ...group.prayers.map((info) {
                final prayerModel = prayerTimeModelFromUnlogged(info);
                return Obx(() {
                  final status =
                      controller.statusByKey[info.key] ??
                      PrayerCardStatus.prayed;
                  final timing =
                      controller.timingByKey[info.key] ??
                      PrayerTimingQuality.onTime;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: MissedPrayerCard(
                      prayer: prayerModel,
                      status: status,
                      timing: timing,
                      onStatusChanged: (newStatus) {
                        HapticFeedback.mediumImpact();
                        controller.setPrayerStatusByKey(info.key, newStatus);
                      },
                      onTimingChanged: (newTiming) =>
                          controller.setPrayerTimingByKey(info.key, newTiming),
                      pastDate: info.date,
                    ),
                  );
                });
              }),
              const SizedBox(height: 16),
            ],
          );
        });
      },
    );
  }

  static PrayerTimeModel prayerTimeModelFromUnlogged(UnloggedPrayerInfo info) {
    return PrayerTimeModel(
      name: info.displayName,
      prayerType: info.prayer,
      dateTime: info.adhanTime,
    );
  }

  Widget _buildStatusButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimingChip(
    PrayerName prayer,
    PrayerTimingQuality quality,
    String label,
    PrayerTimingQuality selectedTiming,
  ) {
    final isSelected = selectedTiming == quality;
    final color = PrayerTimingHelper.getQualityColor(quality);

    return InkWell(
      onTap: () => controller.setPrayerTiming(prayer, quality),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(PrayerTimingHelper.getQualityEmoji(quality)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPrayerIcon(PrayerName prayer) {
    switch (prayer) {
      case PrayerName.fajr:
        return Icons.wb_twilight;
      case PrayerName.dhuhr:
        return Icons.wb_sunny;
      case PrayerName.asr:
        return Icons.wb_cloudy;
      case PrayerName.maghrib:
        return Icons.wb_twilight;
      case PrayerName.isha:
        return Icons.nights_stay;
      default:
        return Icons.access_time;
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
