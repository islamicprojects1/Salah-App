import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/di/injection_container.dart';
import 'package:salah/core/services/sync_service.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/features/prayer/data/repositories/prayer_repository.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// CONNECTION STATUS INDICATOR
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// ✅ ضروري — شريط صغير يظهر في الداشبورد عند انقطاع الاتصال
//            أو وجود سجلات صلاة لم تُرفَع بعد.
//
// يختفي تلقائياً عندما يكون الجهاز متصلاً ولا يوجد شيء معلّق.
// عند الضغط عليه → bottom sheet يشرح الحالة ويتيح المزامنة اليدوية.
//
// يقرأ من [SyncService] فقط — لا يتعامل مع Firestore مباشرة.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class ConnectionStatusIndicator extends StatelessWidget {
  const ConnectionStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final sync = sl<SyncService>();

    return Obx(() {
      final isOnline = sync.isOnlineObs.value;
      final pending = sync.state.pendingCount.value;
      final isSyncing = sync.state.isSyncing.value;

      // لا نعرض شيئاً إذا كل شيء طبيعي
      if (isOnline && pending == 0) return const SizedBox.shrink();

      final bgColor = _bgColor(isOnline, isSyncing, pending);
      final borderColor = _borderColor(isOnline, isSyncing, pending);

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingMD,
          vertical: AppDimensions.paddingSM,
        ),
        child: Material(
          color: AppColors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          child: InkWell(
            onTap: () => _showDetails(context, sync),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMD,
                vertical: AppDimensions.paddingSM,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StatusIcon(
                    isOnline: isOnline,
                    isSyncing: isSyncing,
                    pending: pending,
                  ),
                  const SizedBox(width: 8),
                  _StatusLabel(
                    isOnline: isOnline,
                    isSyncing: isSyncing,
                    pending: pending,
                  ),
                  if (isSyncing) ...[
                    const SizedBox(width: 10),
                    _ProgressBar(progress: sync.syncProgress.value),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // ── Bottom Sheet ────────────────────────────────────────────

  void _showDetails(BuildContext context, SyncService sync) {
    final isOnline = sync.isOnlineObs.value;
    final pending = sync.state.pendingCount.value;
    final isSyncing = sync.state.isSyncing.value;
    final lastSync = sync.state.lastSyncTime.value;

    Get.bottomSheet(
      _SyncDetailsSheet(
        isOnline: isOnline,
        pending: pending,
        isSyncing: isSyncing,
        lastSync: lastSync,
        bgColor: _bgColor(isOnline, isSyncing, pending),
      ),
      isScrollControlled: true,
    );
  }

  // ── Color Helpers ───────────────────────────────────────────

  static Color _bgColor(bool online, bool syncing, int pending) {
    if (!online) return AppColors.warning.withValues(alpha: 0.1);
    if (syncing) return AppColors.primary.withValues(alpha: 0.1);
    if (pending > 0) return AppColors.info.withValues(alpha: 0.1);
    return AppColors.success.withValues(alpha: 0.1);
  }

  static Color _borderColor(bool online, bool syncing, int pending) {
    if (!online) return AppColors.warning.withValues(alpha: 0.3);
    if (syncing) return AppColors.primary.withValues(alpha: 0.3);
    if (pending > 0) return AppColors.info.withValues(alpha: 0.3);
    return AppColors.success.withValues(alpha: 0.3);
  }

  static Color _accentColor(bool online, bool syncing, int pending) {
    if (!online) return AppColors.warning;
    if (syncing) return AppColors.primary;
    if (pending > 0) return AppColors.info;
    return AppColors.success;
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SUB-WIDGETS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _StatusIcon extends StatelessWidget {
  final bool isOnline, isSyncing;
  final int pending;

  const _StatusIcon({
    required this.isOnline,
    required this.isSyncing,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    if (isSyncing) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(AppColors.primary),
        ),
      );
    }
    if (!isOnline) {
      return Icon(Icons.cloud_off_rounded, color: AppColors.warning, size: 18);
    }
    if (pending > 0) {
      return Icon(Icons.sync_rounded, color: AppColors.info, size: 18);
    }
    return Icon(Icons.cloud_done_rounded, color: AppColors.success, size: 18);
  }
}

class _StatusLabel extends StatelessWidget {
  final bool isOnline, isSyncing;
  final int pending;

  const _StatusLabel({
    required this.isOnline,
    required this.isSyncing,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    final String text;
    final Color color;

    if (isSyncing) {
      text = 'syncing'.tr;
      color = AppColors.primary;
    } else if (!isOnline) {
      text = 'offline'.tr;
      color = AppColors.warning;
    } else if (pending > 0) {
      text = 'pending_items'.trParams({'count': '$pending'});
      color = AppColors.info;
    } else {
      text = 'synced'.tr;
      color = AppColors.success;
    }

    return Text(
      text,
      style: AppFonts.labelMedium
          .withColor(color)
          .copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;

  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation(AppColors.primary),
        ),
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// SYNC DETAILS BOTTOM SHEET
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _SyncDetailsSheet extends StatelessWidget {
  final bool isOnline, isSyncing;
  final int pending;
  final DateTime? lastSync;
  final Color bgColor;

  const _SyncDetailsSheet({
    required this.isOnline,
    required this.isSyncing,
    required this.pending,
    required this.lastSync,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingXL),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXL),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingXL),

          // Icon circle
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(
              isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
              color: isOnline ? AppColors.success : AppColors.warning,
              size: 32,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMD),

          // Status title
          Text(
            isOnline ? 'online'.tr : 'offline'.tr,
            style: AppFonts.titleLarge
                .withColor(AppColors.textPrimary)
                .copyWith(fontWeight: FontWeight.bold),
          ),

          if (pending > 0) ...[
            const SizedBox(height: AppDimensions.paddingSM),
            Text(
              'pending_sync_desc'.trParams({'count': '$pending'}),
              style: AppFonts.bodyMedium.withColor(AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],

          if (lastSync != null) ...[
            const SizedBox(height: AppDimensions.paddingSM),
            Text(
              'last_sync'.trParams({'time': _formatTime(lastSync!)}),
              style: AppFonts.bodySmall.withColor(AppColors.textSecondary),
            ),
          ],

          // Sync now button
          if (isOnline && pending > 0 && !isSyncing) ...[
            const SizedBox(height: AppDimensions.paddingXL),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Get.back();
                  sl<PrayerRepository>().syncAllPending();
                },
                icon: const Icon(Icons.sync_rounded),
                label: Text('sync_now'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.paddingMD,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  ),
                ),
              ),
            ),
          ],

          SizedBox(
            height: Get.mediaQuery.padding.bottom + AppDimensions.paddingMD,
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just_now'.tr;
    if (diff.inMinutes < 60) {
      return 'minutes_ago'.trParams({'count': '${diff.inMinutes}'});
    }
    if (diff.inHours < 24) {
      return 'hours_ago'.trParams({'count': '${diff.inHours}'});
    }
    return 'days_ago'.trParams({'count': '${diff.inDays}'});
  }
}
