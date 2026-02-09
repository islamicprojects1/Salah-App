import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/services/sync_service.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/data/repositories/prayer_repository.dart';

/// Connection status indicator – reactive via GetX Obx.
/// Uses [SyncService] for sync state and [PrayerRepository.syncAllPending] for manual sync.
class ConnectionStatusIndicator extends StatelessWidget {
  const ConnectionStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final syncService = Get.find<SyncService>();
    return Obx(() {
      final isOnline = syncService.isOnlineObs.value;
      final pendingCount = syncService.state.pendingCount.value;
      final isSyncing = syncService.state.isSyncing.value;

      if (isOnline && pendingCount == 0) {
        return const SizedBox.shrink();
      }

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showSyncDetails(context, syncService),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _getBackgroundColor(isOnline, isSyncing, pendingCount),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getBorderColor(isOnline, isSyncing, pendingCount),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildIcon(isOnline, isSyncing, pendingCount),
                  const SizedBox(width: 10),
                  _buildText(isOnline, isSyncing, pendingCount),
                  if (isSyncing) ...[
                    const SizedBox(width: 12),
                    _buildProgressIndicator(syncService.syncProgress.value),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildIcon(bool isOnline, bool isSyncing, int pendingCount) {
    if (isSyncing) {
      return SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(AppColors.primary),
        ),
      );
    }
    if (!isOnline) {
      return Icon(Icons.cloud_off_rounded, color: AppColors.warning, size: 20);
    }
    if (pendingCount > 0) {
      return Icon(Icons.sync_rounded, color: AppColors.info, size: 20);
    }
    return Icon(Icons.cloud_done_rounded, color: AppColors.success, size: 20);
  }

  Widget _buildText(bool isOnline, bool isSyncing, int pendingCount) {
    final isArabic = Get.locale?.languageCode == 'ar';
    String text;
    Color color;
    if (isSyncing) {
      text = isArabic ? 'جاري المزامنة...' : 'Syncing...';
      color = AppColors.primary;
    } else if (!isOnline) {
      text = isArabic ? 'غير متصل' : 'Offline';
      color = AppColors.warning;
    } else if (pendingCount > 0) {
      text = isArabic ? '$pendingCount عناصر معلقة' : '$pendingCount pending';
      color = AppColors.info;
    } else {
      text = isArabic ? 'متزامن' : 'Synced';
      color = AppColors.success;
    }
    return Text(
      text,
      style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
    );
  }

  Widget _buildProgressIndicator(double progress) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: constraints.maxWidth * progress.clamp(0.0, 1.0),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getBackgroundColor(bool isOnline, bool isSyncing, int pendingCount) {
    if (!isOnline) return AppColors.warning.withValues(alpha: 0.1);
    if (isSyncing) return AppColors.primary.withValues(alpha: 0.1);
    if (pendingCount > 0) return AppColors.info.withValues(alpha: 0.1);
    return AppColors.success.withValues(alpha: 0.1);
  }

  Color _getBorderColor(bool isOnline, bool isSyncing, int pendingCount) {
    if (!isOnline) return AppColors.warning.withValues(alpha: 0.3);
    if (isSyncing) return AppColors.primary.withValues(alpha: 0.3);
    if (pendingCount > 0) return AppColors.info.withValues(alpha: 0.3);
    return AppColors.success.withValues(alpha: 0.3);
  }

  void _showSyncDetails(BuildContext context, SyncService service) {
    final isArabic = Get.locale?.languageCode == 'ar';
    final isOnline = service.isOnlineObs.value;
    final pendingCount = service.state.pendingCount.value;
    final isSyncing = service.state.isSyncing.value;
    final lastSync = service.state.lastSyncTime.value;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _getBackgroundColor(isOnline, isSyncing, pendingCount),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                color: isOnline ? AppColors.success : AppColors.warning,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isOnline
                  ? (isArabic ? 'متصل بالإنترنت' : 'Online')
                  : (isArabic ? 'غير متصل' : 'Offline'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            if (pendingCount > 0) ...[
              Text(
                isArabic
                    ? '$pendingCount عناصر في انتظار المزامنة'
                    : '$pendingCount items waiting to sync',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
            ],
            if (lastSync != null) ...[
              Text(
                isArabic
                    ? 'آخر مزامنة: ${_formatTime(lastSync)}'
                    : 'Last synced: ${_formatTime(lastSync)}',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
            ],
            if (isOnline && pendingCount > 0 && !isSyncing)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.back();
                    Get.find<PrayerRepository>().syncAllPending();
                  },
                  icon: const Icon(Icons.sync_rounded),
                  label: Text(isArabic ? 'مزامنة الآن' : 'Sync Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    final isArabic = Get.locale?.languageCode == 'ar';
    if (diff.inMinutes < 1) return isArabic ? 'الآن' : 'Just now';
    if (diff.inMinutes < 60) {
      return isArabic ? 'منذ ${diff.inMinutes} دقيقة' : '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return isArabic ? 'منذ ${diff.inHours} ساعة' : '${diff.inHours}h ago';
    }
    return isArabic ? 'منذ ${diff.inDays} يوم' : '${diff.inDays}d ago';
  }
}
