import 'package:flutter/material.dart';
import 'package:get/get_utils/src/extensions/internacionalization.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/enums.dart';
import '../../core/theme/app_colors.dart';

/// Member card widget for community/family screens
class MemberCard extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final List<PrayerCardStatus> todayPrayers; // 5 prayers status
  final bool showInteractionButtons;
  final VoidCallback? onEncourage;
  final VoidCallback? onRemind;
  final VoidCallback? onTap;

  const MemberCard({
    super.key,
    required this.name,
    this.photoUrl,
    this.todayPrayers = const [],
    this.showInteractionButtons = true,
    this.onEncourage,
    this.onRemind,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingSM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMD),
          child: Row(
            children: [
              // Avatar
              _buildAvatar(context),

              const SizedBox(width: AppDimensions.paddingMD),

              // Name and prayers
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimensions.paddingSM),
                    _buildPrayerIndicators(context),
                  ],
                ),
              ),

              // Interaction buttons
              if (showInteractionButtons) _buildInteractionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return CircleAvatar(
      radius: 24,
      backgroundColor: Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: 0.1),
      backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
      child: photoUrl == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            )
          : null,
    );
  }

  Widget _buildPrayerIndicators(BuildContext context) {
    final prayers = [
      'fajr_short'.tr,
      'dhuhr_short'.tr,
      'asr_short'.tr,
      'maghrib_short'.tr,
      'isha_short'.tr,
    ]; // Fajr, Dhuhr, Asr, Maghrib, Isha

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final status = index < todayPrayers.length
            ? todayPrayers[index]
            : PrayerCardStatus.notYet;

        return Padding(
          padding: EdgeInsets.only(left: index > 0 ? 6 : 0),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _getStatusColor(status).withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: _getStatusColor(status), width: 1.5),
            ),
            child: Center(
              child: status == PrayerCardStatus.prayed
                  ? Icon(Icons.check, size: 14, color: _getStatusColor(status))
                  : Text(
                      prayers[index],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(status),
                      ),
                    ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildInteractionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Encourage button
        IconButton(
          onPressed: onEncourage,
          icon: const Icon(Icons.thumb_up_outlined),
          color: AppColors.success,
          tooltip: 'baraka_allahu_feek'.tr,
          iconSize: 20,
        ),

        // Remind button
        IconButton(
          onPressed: onRemind,
          icon: const Icon(Icons.notifications_outlined),
          color: AppColors.warning,
          tooltip: 'remind'.tr,
          iconSize: 20,
        ),
      ],
    );
  }

  Color _getStatusColor(PrayerCardStatus status) {
    switch (status) {
      case PrayerCardStatus.prayed:
        return AppColors.success;
      case PrayerCardStatus.missed:
        return AppColors.error;
      case PrayerCardStatus.notYet:
        return Colors.grey;
    }
  }
}

/// Compact member chip for inline display
class MemberChip extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final VoidCallback? onTap;

  const MemberChip({super.key, required this.name, this.photoUrl, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusXXL),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingSM,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXXL),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: Theme.of(context).colorScheme.primary,
              backgroundImage: photoUrl != null
                  ? NetworkImage(photoUrl!)
                  : null,
              child: photoUrl == null
                  ? Text(
                      name.isNotEmpty ? name[0] : '?',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 6),
            Text(name, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
