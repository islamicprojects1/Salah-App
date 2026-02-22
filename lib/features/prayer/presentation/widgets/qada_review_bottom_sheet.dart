import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/di/injection_container.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/feedback/app_feedback.dart';
import 'package:salah/features/auth/data/services/auth_service.dart';
import 'package:salah/features/prayer/data/models/prayer_log_model.dart';
import 'package:salah/features/prayer/data/repositories/prayer_repository.dart';
import 'package:salah/features/prayer/data/services/live_context_service.dart';
import 'package:salah/features/prayer/data/services/qada_detection_service.dart';

/// Bottom sheet for reviewing and bulk-logging unlogged prayers (qada).
///
/// FIX: _logAll now runs in parallel (Future.wait) instead of sequential
/// await-in-loop which was slow when logging multiple prayers.
class QadaReviewBottomSheet extends StatefulWidget {
  const QadaReviewBottomSheet({super.key});

  static Future<void> show() async {
    if (!Get.isRegistered<QadaDetectionService>()) return;
    final qadaService = sl<QadaDetectionService>();
    if (qadaService.allPendingQada.isEmpty) return;
    await Get.bottomSheet(
      const QadaReviewBottomSheet(),
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: AppColors.transparent,
    );
  }

  @override
  State<QadaReviewBottomSheet> createState() => _QadaReviewBottomSheetState();
}

class _QadaReviewBottomSheetState extends State<QadaReviewBottomSheet> {
  final QadaDetectionService _qadaService = sl<QadaDetectionService>();
  final PrayerRepository _prayerRepo = sl<PrayerRepository>();
  final AuthService _authService = sl<AuthService>();

  final RxSet<String> _loggedKeys = <String>{}.obs;
  final RxSet<String> _dismissedKeys = <String>{}.obs;
  final RxBool _isLogging = false.obs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXXL),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          const SizedBox(height: AppDimensions.paddingMD),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withAlpha(50),
              borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingLG),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingXXL,
            ),
            child: Column(
              children: [
                Text(
                  'qada_sheet_title'.tr,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppDimensions.paddingXS),
                Text(
                  'qada_sheet_subtitle'.tr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withAlpha(153),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.paddingLG),

          // Prayer list
          Flexible(
            child: Obx(() {
              final items = _qadaService.allPendingQada
                  .where(
                    (p) =>
                        !_loggedKeys.contains(p.key) &&
                        !_dismissedKeys.contains(p.key),
                  )
                  .toList();

              if (items.isEmpty) {
                Future.delayed(const Duration(milliseconds: 800), () {
                  if (mounted) Get.back();
                });
                return Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingXXXL),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: AppDimensions.iconHero,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: AppDimensions.paddingMD),
                      Text(
                        'all_prayers_complete'.tr,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingLG,
                ),
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppDimensions.paddingSM),
                itemBuilder: (ctx, i) => _buildPrayerCard(ctx, items[i]),
              );
            }),
          ),

          // Log all button
          Obx(() {
            final remaining = _qadaService.allPendingQada
                .where(
                  (p) =>
                      !_loggedKeys.contains(p.key) &&
                      !_dismissedKeys.contains(p.key),
                )
                .toList();

            if (remaining.isEmpty) {
              return const SizedBox(height: AppDimensions.paddingLG);
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.paddingLG,
                  AppDimensions.paddingSM,
                  AppDimensions.paddingLG,
                  AppDimensions.paddingLG,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: AppDimensions.buttonHeightLG,
                  child: FilledButton.icon(
                    onPressed: _isLogging.value
                        ? null
                        : () => _logAll(remaining),
                    icon: _isLogging.value
                        ? SizedBox(
                            width: AppDimensions.iconMD,
                            height: AppDimensions.iconMD,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline_rounded),
                    label: Text('qada_log_all'.tr),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMD,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPrayerCard(BuildContext context, UnloggedPrayerInfo prayer) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isYesterday = prayer.date.day != DateTime.now().day;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingLG,
        vertical: AppDimensions.paddingMD,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(120),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(
          color: isYesterday
              ? colorScheme.error.withAlpha(40)
              : colorScheme.primary.withAlpha(40),
        ),
      ),
      child: Row(
        children: [
          // Prayer icon
          Container(
            width: AppDimensions.buttonHeightLG,
            height: AppDimensions.buttonHeightLG,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isYesterday
                    ? [
                        colorScheme.error.withAlpha(40),
                        colorScheme.error.withAlpha(20),
                      ]
                    : [
                        colorScheme.primary.withAlpha(40),
                        colorScheme.primary.withAlpha(20),
                      ],
              ),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            ),
            child: Icon(
              _prayerIcon(prayer.prayer),
              color: isYesterday ? colorScheme.error : colorScheme.primary,
              size: AppDimensions.iconLG,
            ),
          ),
          const SizedBox(width: AppDimensions.paddingMD),

          // Prayer info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prayer.displayName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  isYesterday ? 'qada_yesterday'.tr : 'qada_today'.tr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withAlpha(128),
                  ),
                ),
              ],
            ),
          ),

          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionChip(
                label: 'qada_i_prayed'.tr,
                color: colorScheme.primary,
                onTap: () => _logSingle(prayer),
              ),
              const SizedBox(width: AppDimensions.paddingSM),
              _ActionChip(
                label: 'qada_i_missed'.tr,
                color: colorScheme.onSurface.withAlpha(100),
                onTap: () => _dismiss(prayer),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _logSingle(UnloggedPrayerInfo prayer) async {
    final userId = _authService.userId;
    if (userId == null) return;

    try {
      final log = PrayerLogModel(
        id: '',
        oderId: userId,
        prayer: prayer.prayer,
        prayedAt: DateTime.now(),
        adhanTime: prayer.adhanTime,
        quality: PrayerQuality.late,
        timingQuality: PrayerTimingQuality.missed,
      );
      final synced = await _prayerRepo.addPrayerLog(userId: userId, log: log);
      _loggedKeys.add(prayer.key);
      _qadaService.onPrayerLogged();

      if (sl.isRegistered<LiveContextService>()) {
        sl<LiveContextService>().onPrayerLogged();
      }
      if (!synced && Get.isSnackbarOpen != true) {
        AppFeedback.showSuccess('done'.tr, 'saved_will_sync_later'.tr);
      }
    } catch (_) {
      AppFeedback.showError('error'.tr, 'prayer_log_failed'.tr);
    }
  }

  void _dismiss(UnloggedPrayerInfo prayer) => _dismissedKeys.add(prayer.key);

  /// FIX: Run all logs in parallel instead of sequential await-in-loop
  Future<void> _logAll(List<UnloggedPrayerInfo> prayers) async {
    _isLogging.value = true;
    await Future.wait(prayers.map(_logSingle));
    _isLogging.value = false;
  }

  IconData _prayerIcon(PrayerName prayer) {
    switch (prayer) {
      case PrayerName.fajr:
        return Icons.wb_twilight_rounded;
      case PrayerName.dhuhr:
        return Icons.wb_sunny_rounded;
      case PrayerName.asr:
        return Icons.sunny_snowing;
      case PrayerName.maghrib:
        return Icons.nights_stay_rounded;
      case PrayerName.isha:
        return Icons.dark_mode_rounded;
      case PrayerName.sunrise:
        return Icons.wb_sunny_outlined;
    }
  }
}

/// Small action chip used for "I Prayed" / "I Missed" actions.
class _ActionChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: AppDimensions.borderRadiusSM,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingSM + 2,
          vertical: AppDimensions.paddingSM,
        ),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: AppDimensions.borderRadiusSM,
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Text(
          label,
          style:
              theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ) ??
              TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
        ),
      ),
    );
  }
}
