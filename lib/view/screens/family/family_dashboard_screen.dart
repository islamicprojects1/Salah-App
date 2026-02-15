import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/feedback/app_feedback.dart';
import 'package:share_plus/share_plus.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/constants/app_dimensions.dart';
import 'package:salah/core/constants/image_assets.dart';
import 'package:salah/controller/family_controller.dart';
import 'package:salah/core/routes/app_routes.dart';
import 'package:salah/core/helpers/prayer_names.dart';
import 'package:salah/core/helpers/prayer_timing_helper.dart';
import 'package:salah/core/services/auth_service.dart';
import 'package:salah/core/services/prayer_time_service.dart';
import 'package:salah/data/models/family_model.dart';
import 'package:salah/core/helpers/date_time_helper.dart';
import 'package:salah/view/widgets/app_button.dart';
import 'package:salah/view/widgets/app_loading.dart';
import 'package:salah/view/widgets/family_vitality_orb.dart';
import 'package:salah/view/widgets/synchronicity_avatar.dart';
import 'package:salah/view/widgets/family_flame_widget.dart';

class FamilyDashboardScreen extends StatefulWidget {
  const FamilyDashboardScreen({super.key});

  @override
  State<FamilyDashboardScreen> createState() => _FamilyDashboardScreenState();
}

class _FamilyDashboardScreenState extends State<FamilyDashboardScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final controller = Get.find<FamilyController>();

    return Obx(() {
      if (controller.isLoading) {
        return const AppLoading();
      }

      if (!controller.hasFamily) {
        return _buildNoFamilyView(context);
      }

      return _buildFamilyView(context, controller);
    });
  }

  // ─── No Family View ──────────────────────────────────────────────

  Widget _buildNoFamilyView(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Lottie.asset(
            ImageAssets.familyPrayingAnimation,
            width: 150,
            height: 150,
          ),
          const SizedBox(height: AppDimensions.paddingXL),
          Text(
            'no_family_yet'.tr,
            style: AppFonts.headlineMedium.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.paddingMD),
          Text(
            'create_or_join_family_desc'.tr,
            style: AppFonts.bodyMedium.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.paddingXL * 2),
          AppButton(
            text: 'create_family'.tr,
            onPressed: () => Get.toNamed(AppRoutes.createFamily),
            icon: Icons.add_circle_outline,
            width: double.infinity,
          ),
          const SizedBox(height: AppDimensions.paddingMD),
          AppButton(
            text: 'join_family'.tr,
            onPressed: () => Get.toNamed(AppRoutes.joinFamily),
            type: AppButtonType.outlined,
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  // ─── Family View ─────────────────────────────────────────────────

  Widget _buildFamilyView(BuildContext context, FamilyController controller) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final family = controller.currentFamily!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header: Family Name + Switcher ──
          _buildFamilyHeader(context, family, controller),

          const SizedBox(height: AppDimensions.paddingLG),

          // ── Vitality Orb (Centerpiece) ──
          const Center(child: FamilyVitalityOrb()),

          const SizedBox(height: AppDimensions.paddingLG),

          // ── Family Flame ──
          const Center(child: FamilyFlameWidget()),

          const SizedBox(height: AppDimensions.paddingLG),

          // ── Family Daily Summary ──
          _buildFamilySummaryCard(context, family, controller),

          const SizedBox(height: AppDimensions.paddingXL),

          // ── Members ──
          Text(
            'family_members_count'.tr.replaceAll(
              '@count',
              '${family.members.length}',
            ),
            style: AppFonts.titleLarge.copyWith(color: colorScheme.onSurface),
          ),

          const SizedBox(height: AppDimensions.paddingMD),

          _buildMembersList(context, family, controller),
        ],
      ),
    );
  }

  // ─── Family Header ──────────────────────────────────────────────

  Widget _buildFamilyHeader(
    BuildContext context,
    FamilyModel family,
    FamilyController controller,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: AppDimensions.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
      ),
      color: colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLG),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showFamilySwitcher(context, controller),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            family.name,
                            style: AppFonts.headlineMedium.copyWith(
                              color: colorScheme.onPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (controller.myFamilies.length > 1) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: colorScheme.onPrimary.withValues(alpha: 0.8),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Obx(() {
                  final hasUnread = controller.pulseEvents.isNotEmpty;
                  return Stack(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.notifications_outlined,
                          color: colorScheme.onPrimary,
                        ),
                        onPressed: () => Get.toNamed(AppRoutes.notifications),
                      ),
                      if (hasUnread)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 8,
                              minHeight: 8,
                            ),
                          ),
                        ),
                    ],
                  );
                }),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingMD),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMD,
                vertical: AppDimensions.paddingXS,
              ),
              decoration: BoxDecoration(
                color: colorScheme.onPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${'invite_code_label'.tr}: ${family.inviteCode}',
                    style: AppFonts.bodyLarge.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingMD),
                  IconButton(
                    icon: Icon(
                      Icons.share,
                      color: colorScheme.onPrimary,
                      size: 20,
                    ),
                    onPressed: () {
                      Share.share(
                        'share_family_invite'.tr.replaceAll(
                          '@code',
                          family.inviteCode,
                        ),
                      );
                    },
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            if (family.isAdmin(Get.find<AuthService>().userId ?? '')) ...[
              const SizedBox(height: AppDimensions.paddingMD),
              TextButton.icon(
                onPressed: () => _showAddChildDialog(context, controller),
                icon: Icon(
                  Icons.person_add_alt_1,
                  color: colorScheme.onPrimary,
                ),
                label: Text(
                  'add_child_no_phone_btn'.tr,
                  style: AppFonts.bodyMedium.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor:
                      colorScheme.onPrimary.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMD),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Members List with Synchronicity Avatars ─────────────────────

  Widget _buildMembersList(
    BuildContext context,
    FamilyModel family,
    FamilyController controller,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: family.members.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppDimensions.paddingMD),
      itemBuilder: (context, index) {
        final member = family.members[index];
        return Obx(() {
          final isMe = member.userId == Get.find<AuthService>().userId;
          final dailyLogs = controller.memberDailyLogs[member.userId] ?? {};
          final statusInfo = _getMemberStatusInfo(
            memberId: member.userId,
            dailyLogs: dailyLogs,
          );
          final lastPrayerAt = controller.memberLastPrayer[member.userId];
          final lastQuality = controller.memberLastPrayerQuality[member.userId];

          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;

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
                      // Daily Progress Pulse (Top Left)
                      _buildPrayerProgressDots(
                        context,
                        member.userId,
                        controller,
                        statusInfo,
                      ),
                      const Spacer(),
                      // Name & Avatar (Top Right)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    member.name ?? 'member_role'.tr,
                                    style: AppFonts.titleMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      if (statusInfo.subtitle != null) ...[
                                        Icon(
                                          statusInfo.icon,
                                          size: 14,
                                          color: statusInfo.color,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          statusInfo.subtitle!,
                                          style: AppFonts.bodySmall.copyWith(
                                            color: statusInfo.color,
                                          ),
                                        ),
                                      ],
                                      if (statusInfo.subtitle == null &&
                                          lastPrayerAt != null) ...[
                                        Icon(
                                          Icons.schedule,
                                          size: 12,
                                          color: theme
                                              .textTheme.bodySmall?.color,
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
                              const SizedBox(width: 12),
                              // Synchronicity Avatar with Status Overlay
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
                    ],
                  ),
                ),
                // Footer: Actions
                if (!isMe) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingLG,
                      vertical: AppDimensions.paddingMD,
                    ),
                    child: _buildMemberActions(
                      context,
                      member,
                      statusInfo,
                      controller,
                      family,
                    ),
                  ),
                ],
              ],
            ),
          );
        });
      },
    );
  }

  // ─── Status Logic Helper ──────────────────────────────────────────

  _MemberStatusInfo _getMemberStatusInfo({
    required String memberId,
    required Map<String, String> dailyLogs,
  }) {
    final pts = Get.find<PrayerTimeService>();
    final currentPrayer = pts.currentPrayer.value;
    final todayPrayers = pts.getTodayPrayers();
    final now = DateTime.now();

    // 1. Check CURRENT PRAYER first (The "Fresh Start" Logic)
    if (currentPrayer != null) {
      final cpName = currentPrayer.prayerType?.name.toLowerCase();
      final currentLog = dailyLogs[cpName];

      if (currentLog != null) {
        // Already prayed CURRENT prayer
        bool isLate = currentLog.toLowerCase().contains('late');
        return _MemberStatusInfo(
          label: isLate ? 'status_prayed_late'.tr : 'status_prayed_on_time'.tr,
          color: isLate ? AppColors.warning : AppColors.success,
          icon: isLate ? Icons.history : Icons.check_circle_outline,
          badgeIcon: Icons.check,
          isPending: false,
          ringColor: isLate ? AppColors.warning : AppColors.success,
        );
      } else {
        // NOT YET PRAYED current prayer -> Pulsing Orange (FRESH START)
        return _MemberStatusInfo(
          label: 'status_not_prayed_yet'.tr,
          color: AppColors.orange,
          icon: Icons.pending_actions,
          badgeIcon: Icons.hourglass_empty,
          isPending: true,
          ringColor: AppColors.orange,
        );
      }
    }

    // 2. If no current prayer (rare), check if ANY previous prayer was missed today
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
      return _MemberStatusInfo(
        label: 'status_not_prayed_yet'.tr,
        color: AppColors.error,
        icon: Icons.cancel_outlined,
        badgeIcon: Icons.close,
        isPending: false,
        ringColor: AppColors.error,
        showXBadge: true,
      );
    }

    return _MemberStatusInfo(
      label: 'status_not_prayed_yet'.tr,
      color: AppColors.textSecondary,
      icon: Icons.remove_circle_outline,
      badgeIcon: Icons.remove,
      isPending: false,
    );
  }

  // ─── Status Dots Widget ──────────────────────────────────────────

  Widget _buildPrayerProgressDots(
    BuildContext context,
    String userId,
    FamilyController controller,
    _MemberStatusInfo status,
  ) {
    final dailyLogs = controller.memberDailyLogs[userId] ?? {};
    final order = [
      PrayerName.fajr,
      PrayerName.dhuhr,
      PrayerName.asr,
      PrayerName.maghrib,
      PrayerName.isha,
    ];

    final pts = Get.find<PrayerTimeService>();
    final currentPrayerType = pts.currentPrayer.value?.prayerType;
    final todayPrayers = pts.getTodayPrayers();
    final now = DateTime.now();

    return Row(
      children: order.map((p) {
        final logQuality = dailyLogs[p.name.toLowerCase()];
        final isCurrent = p == currentPrayerType;
        
        // Find the adhan time for this prayer to check if it's "Missed"
        final prayerTimeData = todayPrayers.firstWhereOrNull((tp) => tp.prayerType == p);
        final bool hasPassed = prayerTimeData != null && prayerTimeData.dateTime.isBefore(now);

        Color dotColor;
        IconData dotIcon;
        bool shouldGlow = false;

        if (logQuality != null) {
          // 1. ALREADY PRAYED
          bool isLate = logQuality.toLowerCase().contains('late');
          dotColor = isLate ? AppColors.warning : AppColors.success;
          dotIcon = Icons.check_circle_rounded;
        } else if (isCurrent) {
          // 2. CURRENT ACTIVE WINDOW
          dotColor = AppColors.orange;
          dotIcon = Icons.radio_button_checked_rounded;
          shouldGlow = true;
        } else if (hasPassed) {
          // 3. MISSED (Time passed, no log)
          dotColor = AppColors.error.withValues(alpha: 0.6);
          dotIcon = Icons.cancel_rounded;
        } else {
          // 4. FUTURE (Time hasn't come yet)
          dotColor = Theme.of(context).disabledColor.withValues(alpha: 0.3);
          dotIcon = Icons.circle;
        }

        return Container(
          margin: const EdgeInsets.only(right: 6),
          child: Tooltip(
            message: '${PrayerNames.displayName(p)}: ${logQuality ?? (hasPassed ? 'status_missed'.tr : 'status_future'.tr)}',
            child: TweenAnimationBuilder<double>(
              duration: const Duration(seconds: 1),
              tween: Tween(begin: 0.8, end: 1.0),
              curve: Curves.easeInOut,
              onEnd: () {}, 
              builder: (context, value, child) {
                return Transform.scale(
                  scale: (shouldGlow && status.isPending) ? value : 1.0,
                  child: Opacity(
                    opacity: (dotColor == AppColors.success || dotColor == AppColors.warning || shouldGlow) ? 1.0 : 0.6,
                    child: Icon(
                      dotIcon,
                      size: 18,
                      color: dotColor,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Member Actions (Popup Menu) ──────────────────────────────────

  Widget _buildMemberActions(
    BuildContext context,
    MemberModel member,
    _MemberStatusInfo status,
    FamilyController controller,
    FamilyModel family,
  ) {
    if (status.badgeIcon == Icons.check) {
      // Already prayed -> Show "Praise" or "Dua" button
      return AppButton(
        text: 'encourage_dua_done'.tr,
        icon: Icons.favorite,
        backgroundColor: AppColors.success.withValues(alpha: 0.1),
        textColor: AppColors.success,
        onPressed: () => controller.pokeMember(
          member.userId,
          member.name ?? '',
          customMessage: 'encourage_dua_done'.tr,
        ),
        width: double.infinity,
      );
    }

    // Not prayed -> Show "Encourage" with popup menu
    return Row(
      children: [
        if (family.isAdmin(Get.find<AuthService>().userId ?? '') &&
            member.role == MemberRole.child) ...[
          Expanded(
            child: AppButton(
              text: 'log_for_him'.tr,
              type: AppButtonType.outlined,
              icon: Icons.edit_note,
              onPressed: () => _showLogForMemberDialog(
                context,
                controller,
                member.userId,
                member.name ?? '',
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: _buildEncourageMenu(context, member, controller),
        ),
      ],
    );
  }

  Widget _buildEncourageMenu(
    BuildContext context,
    MemberModel member,
    FamilyController controller,
  ) {
    return PopupMenuButton<String>(
      offset: const Offset(0, -200),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
      ),
      onSelected: (msg) {
        controller.pokeMember(member.userId, member.name ?? '',
            customMessage: msg);
        AppFeedback.hapticSuccess();
      },
      itemBuilder: (context) => [
        _buildPopupItem('encourage_jazakallah'.tr, Icons.volunteer_activism),
        _buildPopupItem('encourage_may_allah_open'.tr, Icons.wb_sunny_outlined),
        _buildPopupItem('encourage_may_allah_help'.tr, Icons.mosque_outlined),
        _buildPopupItem('early_bird'.tr, Icons.campaign_outlined),
        _buildPopupItem('gentle_reminder'.tr, Icons.notifications_active_outlined),
      ],
      child: AppButton(
        text: 'encourage'.tr,
        icon: Icons.celebration_outlined,
        onPressed: null, // Let PopupMenu handle it
        width: double.infinity,
      ),
    );
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

  // ─── Pulse Feed ──────────────────────────────────────────────────

  Widget _buildPulseSection(
    BuildContext context,
    FamilyController controller,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() {
      final events = controller.pulseEvents;
      if (events.isEmpty) return const SizedBox.shrink();
      return Card(
        elevation: AppDimensions.cardElevationLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.favorite, color: colorScheme.primary, size: 20),
                  const SizedBox(width: AppDimensions.paddingSM),
                  Text(
                    'family_pulse'.tr,
                    style: AppFonts.titleMedium.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingMD),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: events.length > 5 ? 5 : events.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppDimensions.paddingXS),
                  itemBuilder: (context, index) {
                    final e = events[index];
                    final isCelebration = e.type == PulseEventType.familyCelebration;
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300 + index * 50),
                      curve: Curves.easeOut,
                      padding: EdgeInsets.symmetric(
                        vertical: isCelebration ? 8 : 4,
                        horizontal: isCelebration ? 8 : 0,
                      ),
                      decoration: isCelebration
                          ? BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.success.withValues(alpha: 0.1),
                                  AppColors.amber.withValues(alpha: 0.05),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            )
                          : null,
                      child: Row(
                        children: [
                          Icon(
                            isCelebration
                                ? Icons.celebration
                                : e.type == PulseEventType.encouragement
                                    ? Icons.thumb_up
                                    : Icons.mosque,
                            size: isCelebration ? 22 : 18,
                            color: isCelebration
                                ? AppColors.amber
                                : colorScheme.primary.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              e.displayText,
                              style: AppFonts.bodyMedium.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight:
                                    isCelebration ? FontWeight.bold : null,
                              ),
                            ),
                          ),
                          Text(
                            _relativeTime(e.timestamp),
                            style: AppFonts.bodySmall.copyWith(
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ─── Family Summary Card ──────────────────────────────────────────

  Widget _buildFamilySummaryCard(
    BuildContext context,
    FamilyModel family,
    FamilyController controller,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Obx(() {
      final totalMembers = family.members.length;
      final totalPossible = totalMembers * 5;
      int totalLogged = 0;
      for (final m in family.members) {
        totalLogged += (controller.memberProgress[m.userId] ?? 0);
      }
      final progress = totalPossible > 0 ? totalLogged / totalPossible : 0.0;

      return Card(
        elevation: AppDimensions.cardElevationLow,
        margin: const EdgeInsets.all(0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bar_chart_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: AppDimensions.paddingSM),
                  Text(
                    'family_daily_summary'.tr,
                    style: AppFonts.titleMedium.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$totalLogged/$totalPossible',
                    style: AppFonts.titleLarge.copyWith(
                      color: _getMemberProgressColor(
                        totalLogged ~/
                            (totalMembers > 0 ? totalMembers : 1),
                      ),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingSM),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor:
                      colorScheme.primary.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getMemberProgressColor(
                      totalLogged ~/
                          (totalMembers > 0 ? totalMembers : 1),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // ─── Helpers ──────────────────────────────────────────────────────

  Color _getMemberProgressColor(int count) {
    if (count >= 5) {
      return PrayerTimingHelper.getQualityColor(
        PrayerTimingQuality.veryEarly,
      );
    }
    if (count >= 3) return AppColors.amber;
    if (count >= 1) return AppColors.orange;
    return AppColors.error.withValues(alpha: 0.6);
  }

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'now_label'.tr;
    if (diff.inMinutes < 60) return '${diff.inMinutes} ${'minutes_short'.tr}';
    if (diff.inHours < 24) return '${diff.inHours} ${'hours_short'.tr}';
    return DateTimeHelper.formatTime12(time);
  }

  // ─── Dialogs ──────────────────────────────────────────────────────

  void _showLogForMemberDialog(
    BuildContext context,
    FamilyController controller,
    String memberId,
    String memberName,
  ) {
    final now = DateTime.now();
    // Only show prayers whose adhan time has passed (can't log future prayers)
    final prayers = Get.find<PrayerTimeService>()
        .getTodayPrayers()
        .where((p) => p.prayerType != PrayerName.sunrise && p.dateTime.isBefore(now))
        .toList();

    if (prayers.isEmpty) {
      AppFeedback.showSnackbar('alert'.tr, 'no_past_prayers_yet'.tr);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('select_prayer_to_log'.tr),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: prayers
                .map(
                  (p) => ListTile(
                    title: Text(
                      PrayerNames.displayName(
                        p.prayerType ?? PrayerName.fajr,
                      ),
                    ),
                    subtitle: Text(
                      DateTimeHelper.formatTime12(p.dateTime),
                    ),
                    onTap: () {
                      Get.back();
                      final pt = p.prayerType ?? PrayerName.fajr;
                      controller.logPrayerForMember(
                        memberId: memberId,
                        prayerName: pt.name,
                        adhanTime: p.dateTime,
                      );
                    },
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
        ],
      ),
    );
  }

  void _showAddChildDialog(
    BuildContext context,
    FamilyController controller,
  ) {
    final nameController = TextEditingController();
    String gender = 'male';
    DateTime birthDate = DateTime(2015);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('add_child'.tr, style: AppFonts.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'child_name'.tr),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: gender,
              items: [
                DropdownMenuItem(value: 'male', child: Text('male'.tr)),
                DropdownMenuItem(
                  value: 'female',
                  child: Text('female'.tr),
                ),
              ],
              onChanged: (v) => gender = v ?? 'male',
              decoration: InputDecoration(labelText: 'gender'.tr),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () => controller.addChild(
              nameController.text,
              birthDate,
              gender,
            ),
            child: Text('add'.tr),
          ),
        ],
      ),
    );
  }

  void _showFamilySwitcher(
    BuildContext context,
    FamilyController controller,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(AppDimensions.paddingLG),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'switch_family'.tr,
              style: AppFonts.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.paddingLG),
            Flexible(
              child: Obx(
                () => ListView.separated(
                  shrinkWrap: true,
                  itemCount: controller.myFamilies.length,
                  separatorBuilder: (context, index) =>
                      const Divider(),
                  itemBuilder: (context, index) {
                    final family = controller.myFamilies[index];
                    final isSelected =
                        family.id == controller.currentFamily?.id;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isSelected
                            ? colorScheme.primary
                            : colorScheme.secondaryContainer,
                        child: Icon(
                          Icons.group,
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSecondaryContainer,
                        ),
                      ),
                      title: Text(
                        family.name,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check,
                              color: colorScheme.primary,
                            )
                          : null,
                      onTap: () {
                        controller.selectFamily(family);
                        Get.back();
                      },
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingLG),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Get.back();
                      Get.toNamed(AppRoutes.createFamily);
                    },
                    icon: const Icon(Icons.add),
                    label: Text('create_family'.tr),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Get.back();
                      Get.toNamed(AppRoutes.joinFamily);
                    },
                    icon: const Icon(Icons.login),
                    label: Text('join_family'.tr),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingMD),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }
}

class _MemberStatusInfo {
  final String label;
  final String? subtitle;
  final Color color;
  final IconData icon;
  final IconData badgeIcon;
  final bool isPending;
  final Color? ringColor;
  final bool showXBadge;

  _MemberStatusInfo({
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
