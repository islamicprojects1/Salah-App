import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/di/injection_container.dart';
import 'package:salah/core/feedback/app_feedback.dart';
import 'package:salah/core/helpers/date_time_helper.dart';
import 'package:salah/core/helpers/prayer_names.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/widgets/app_button.dart';
import 'package:salah/features/auth/data/services/auth_service.dart';
import 'package:salah/features/family/controller/family_controller.dart';
import 'package:salah/features/family/data/models/family_model.dart';
import 'package:salah/features/family/presentation/widgets/synchronicity_avatar.dart';
import 'package:salah/features/prayer/data/services/prayer_time_service.dart';

/// Status info for a family member (prayer state).
class MemberStatusInfo {
  final String label;
  final String? subtitle;
  final Color color;
  final IconData icon;
  final IconData badgeIcon;
  final bool isPending;
  final Color? ringColor;
  final bool showXBadge;

  MemberStatusInfo({
    required this.label,
    this.subtitle,
    required this.color,
    required this.icon,
    required this.badgeIcon,
    this.isPending = false,
    this.ringColor,
    this.showXBadge = false,
  });
}

/// Full member card with progress dots, avatar, status, and actions.
class FamilyMemberCard extends StatelessWidget {
  final MemberModel member;
  final FamilyModel family;
  final FamilyController controller;
  final VoidCallback? onLogForMember;

  const FamilyMemberCard({
    super.key,
    required this.member,
    required this.family,
    required this.controller,
    this.onLogForMember,
  });

  static MemberStatusInfo getMemberStatusInfo({
    required Map<String, String> dailyLogs,
  }) {
    final pts = sl<PrayerTimeService>();
    final currentPrayer = pts.currentPrayer.value;
    final todayPrayers = pts.getTodayPrayers();
    final now = DateTime.now();

    if (currentPrayer != null) {
      final cpName = currentPrayer.prayerType?.name.toLowerCase();
      final currentLog = dailyLogs[cpName];

      if (currentLog != null) {
        final isLate = currentLog.toLowerCase().contains('late');
        return MemberStatusInfo(
          label: isLate ? 'status_prayed_late'.tr : 'status_prayed_on_time'.tr,
          subtitle: isLate ? 'status_prayed_late'.tr : 'status_prayed_on_time'.tr,
          color: isLate ? AppColors.warning : AppColors.success,
          icon: isLate ? Icons.history : Icons.check_circle_outline,
          badgeIcon: Icons.check,
          isPending: false,
          ringColor: isLate ? AppColors.warning : AppColors.success,
        );
      } else {
        return MemberStatusInfo(
          label: 'status_not_prayed_yet'.tr,
          subtitle: 'status_not_prayed_yet'.tr,
          color: AppColors.orange,
          icon: Icons.pending_actions,
          badgeIcon: Icons.hourglass_empty,
          isPending: true,
          ringColor: AppColors.orange,
        );
      }
    }

    bool anyMissed = false;
    for (final tp in todayPrayers) {
      if (tp.dateTime.isBefore(now)) {
        final pName = tp.prayerType?.name.toLowerCase();
        if (pName != null && !dailyLogs.containsKey(pName)) {
          anyMissed = true;
          break;
        }
      }
    }

    if (anyMissed) {
      return MemberStatusInfo(
        label: 'status_not_prayed_yet'.tr,
        subtitle: 'status_not_prayed_yet'.tr,
        color: AppColors.error,
        icon: Icons.cancel_outlined,
        badgeIcon: Icons.close,
        isPending: false,
        ringColor: AppColors.error,
        showXBadge: true,
      );
    }

    return MemberStatusInfo(
      label: 'status_not_prayed_yet'.tr,
      color: AppColors.textSecondary,
      icon: Icons.remove_circle_outline,
      badgeIcon: Icons.remove,
      isPending: false,
    );
  }

  static String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'now_label'.tr;
    if (diff.inMinutes < 60) return '${diff.inMinutes} ${'minutes_short'.tr}';
    if (diff.inHours < 24) return '${diff.inHours} ${'hours_short'.tr}';
    return DateTimeHelper.formatTime12(time);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMe = member.userId == sl<AuthService>().userId;

    return Obx(() {
      final dailyLogs = controller.memberDailyLogs[member.userId] ?? {};
      final statusInfo = getMemberStatusInfo(dailyLogs: dailyLogs);
      final lastPrayerAt = controller.memberLastPrayer[member.userId];

      return Card(
        elevation: AppDimensions.cardElevationLow,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingLG),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPrayerProgressDots(context, member.userId, statusInfo),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    member.name ?? 'member_role'.tr,
                                    style: AppFonts.titleMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    textAlign: TextAlign.right,
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (statusInfo.subtitle != null) ...[
                                        Icon(
                                          statusInfo.icon,
                                          size: 14,
                                          color: statusInfo.color,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            statusInfo.subtitle!,
                                            style: AppFonts.bodySmall.copyWith(
                                              color: statusInfo.color,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                      if (statusInfo.subtitle == null &&
                                          lastPrayerAt != null) ...[
                                        Icon(
                                          Icons.schedule,
                                          size: 12,
                                          color: theme.textTheme.bodySmall?.color,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          _relativeTime(lastPrayerAt),
                                          style: AppFonts.bodySmall,
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            SynchronicityAvatar(
                              photoUrl: member.photoUrl,
                              initial: (member.name ?? 'M')[0].toUpperCase(),
                              isInPrayerWindow: statusInfo.isPending,
                              statusColor: statusInfo.ringColor,
                              showXBadge: statusInfo.showXBadge,
                              radius: 28,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!isMe) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingLG,
                  vertical: AppDimensions.paddingMD,
                ),
                child: _buildMemberActions(context, statusInfo),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildPrayerProgressDots(
    BuildContext context,
    String userId,
    MemberStatusInfo status,
  ) {
    final dailyLogs = controller.memberDailyLogs[userId] ?? {};
    final order = [
      PrayerName.fajr,
      PrayerName.dhuhr,
      PrayerName.asr,
      PrayerName.maghrib,
      PrayerName.isha,
    ];

    final pts = sl<PrayerTimeService>();
    final currentPrayerType = pts.currentPrayer.value?.prayerType;
    final todayPrayers = pts.getTodayPrayers();
    final now = DateTime.now();

    return Row(
      children: order.map((p) {
        final logQuality = dailyLogs[p.name.toLowerCase()];
        final isCurrent = p == currentPrayerType;

        final prayerTimeData = todayPrayers.firstWhereOrNull(
          (tp) => tp.prayerType == p,
        );
        final hasPassed = prayerTimeData != null &&
            prayerTimeData.dateTime.isBefore(now);

        Color dotColor;
        IconData dotIcon;
        bool shouldGlow = false;

        if (logQuality != null) {
          final isLate = logQuality.toLowerCase().contains('late');
          dotColor = isLate ? AppColors.warning : AppColors.success;
          dotIcon = Icons.check_circle_rounded;
        } else if (isCurrent) {
          dotColor = AppColors.orange;
          dotIcon = Icons.radio_button_checked_rounded;
          shouldGlow = true;
        } else if (hasPassed) {
          dotColor = AppColors.error.withValues(alpha: 0.6);
          dotIcon = Icons.cancel_rounded;
        } else {
          dotColor = Theme.of(context).disabledColor.withValues(alpha: 0.3);
          dotIcon = Icons.circle;
        }

        return Container(
          margin: const EdgeInsets.only(right: 6),
          child: Tooltip(
            message:
                '${PrayerNames.displayName(p)}: ${logQuality ?? (hasPassed ? 'status_missed'.tr : 'status_future'.tr)}',
            child: TweenAnimationBuilder<double>(
              duration: const Duration(seconds: 1),
              tween: Tween(begin: 0.8, end: 1.0),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: (shouldGlow && status.isPending) ? value : 1.0,
                  child: Opacity(
                    opacity: (dotColor == AppColors.success ||
                            dotColor == AppColors.warning ||
                            shouldGlow)
                        ? 1.0
                        : 0.6,
                    child: Icon(dotIcon, size: 18, color: dotColor),
                  ),
                );
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMemberActions(BuildContext context, MemberStatusInfo status) {
    final isAdmin = family.isAdmin(sl<AuthService>().userId ?? '');

    if (status.badgeIcon == Icons.check) {
      return Obx(() => AppButton(
            text: 'encourage_dua_done'.tr,
            icon: Icons.favorite,
            backgroundColor: AppColors.success.withValues(alpha: 0.1),
            textColor: AppColors.success,
            isLoading: controller.sendingEncouragementToUserId.value ==
                member.userId,
            onPressed: () => controller.pokeMember(
              member.userId,
              member.name ?? '',
              customMessage: 'encourage_dua_done'.tr,
            ),
            width: double.infinity,
          ));
    }

    return Row(
      children: [
        if (isAdmin && member.role == MemberRole.child && onLogForMember != null) ...[
          Expanded(
            child: AppButton(
              text: 'log_for_him'.tr,
              type: AppButtonType.outlined,
              icon: Icons.edit_note,
              onPressed: onLogForMember,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(child: _buildEncourageMenu(context)),
      ],
    );
  }

  Widget _buildEncourageMenu(BuildContext context) {
    return Obx(() {
      final sending =
          controller.sendingEncouragementToUserId.value == member.userId;
      if (sending) {
        return AppButton(
          text: 'encourage'.tr,
          icon: Icons.celebration_outlined,
          isLoading: true,
          width: double.infinity,
        );
      }
      return PopupMenuButton<String>(
        offset: const Offset(0, -200),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        ),
        onSelected: (msg) {
          controller.pokeMember(
            member.userId,
            member.name ?? '',
            customMessage: msg,
          );
          AppFeedback.hapticSuccess();
        },
        itemBuilder: (context) => [
          _buildPopupItem('encourage_jazakallah'.tr, Icons.volunteer_activism),
          _buildPopupItem('encourage_may_allah_open'.tr, Icons.wb_sunny_outlined),
          _buildPopupItem('encourage_may_allah_help'.tr, Icons.mosque_outlined),
          _buildPopupItem('early_bird'.tr, Icons.campaign_outlined),
          _buildPopupItem(
            'gentle_reminder'.tr,
            Icons.notifications_active_outlined,
          ),
        ],
        child: AppButton(
          text: 'encourage'.tr,
          icon: Icons.celebration_outlined,
          onPressed: null,
          width: double.infinity,
        ),
      );
    });
  }

  PopupMenuItem<String> _buildPopupItem(String text, IconData icon) {
    return PopupMenuItem<String>(
      value: text,
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(text, style: AppFonts.bodyMedium),
        ],
      ),
    );
  }
}
