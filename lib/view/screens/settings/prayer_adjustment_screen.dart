import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/controller/settings/settings_controller.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';

class PrayerAdjustmentScreen extends GetView<SettingsController> {
  const PrayerAdjustmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('adjust_prayer_times'.tr),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: Obx(() {
        final user = controller.userModel.value;
        // If user is null, we can still show 0 offsets or loading
        final offsets = user?.prayerOffsets ?? {};

        return ListView(
          padding: const EdgeInsets.all(AppDimensions.paddingMD),
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),
            _buildAdjustmentTile(
              context, 
              'fajr'.tr, 
              'fajr', 
              offsets['fajr'] ?? 0
            ),
            const SizedBox(height: 12),
            _buildAdjustmentTile(
              context, 
              'sunrise'.tr, 
              'sunrise', 
              offsets['sunrise'] ?? 0
            ),
            const SizedBox(height: 12),
            _buildAdjustmentTile(
              context, 
              'dhuhr'.tr, 
              'dhuhr', 
              offsets['dhuhr'] ?? 0
            ),
            const SizedBox(height: 12),
            _buildAdjustmentTile(
              context, 
              'asr'.tr, 
              'asr', 
              offsets['asr'] ?? 0
            ),
            const SizedBox(height: 12),
            _buildAdjustmentTile(
              context, 
              'maghrib'.tr, 
              'maghrib', 
              offsets['maghrib'] ?? 0
            ),
            const SizedBox(height: 12),
            _buildAdjustmentTile(
              context, 
              'isha'.tr, 
              'isha', 
              offsets['isha'] ?? 0
            ),
          ],
        );
      }),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'adjustment_desc'.tr,
              style: AppFonts.bodySmall.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustmentTile(BuildContext context, String name, String key, int currentOffset) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: AppFonts.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          
          _buildCounterButton(
            icon: Icons.remove,
            onTap: () {
               controller.updatePrayerOffset(key, currentOffset - 1);
            },
          ),
          
          SizedBox(
            width: 80,
            child: Text(
              currentOffset == 0 
                  ? '0 ${'min'.tr}' 
                  : '${currentOffset > 0 ? '+' : ''}$currentOffset ${'min'.tr}',
              textAlign: TextAlign.center,
              style: AppFonts.bodyLarge.copyWith(
                color: currentOffset == 0 ? Colors.grey : AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          _buildCounterButton(
            icon: Icons.add,
            onTap: () {
              controller.updatePrayerOffset(key, currentOffset + 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCounterButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}
