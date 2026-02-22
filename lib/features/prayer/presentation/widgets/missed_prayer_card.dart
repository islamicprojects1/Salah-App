import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/helpers/prayer_timing_helper.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/features/prayer/data/models/prayer_time_model.dart';

/// Premium missed prayer card with smooth animations and swipe gestures.
/// Supports RTL layout and uses theme colors instead of hardcoded white.
class MissedPrayerCard extends StatefulWidget {
  final PrayerTimeModel prayer;
  final PrayerCardStatus status;
  final PrayerTimingQuality timing;
  final Function(PrayerCardStatus) onStatusChanged;
  final Function(PrayerTimingQuality) onTimingChanged;
  final VoidCallback? onDismissed;

  /// Optional: if set, this card represents a past day's prayer (qada)
  final DateTime? pastDate;

  const MissedPrayerCard({
    super.key,
    required this.prayer,
    required this.status,
    required this.timing,
    required this.onStatusChanged,
    required this.onTimingChanged,
    this.onDismissed,
    this.pastDate,
  });

  @override
  State<MissedPrayerCard> createState() => _MissedPrayerCardState();
}

class _MissedPrayerCardState extends State<MissedPrayerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    if (widget.status == PrayerCardStatus.prayed) {
      _isExpanded = true;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MissedPrayerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status != oldWidget.status) {
      setState(() {
        _isExpanded = widget.status == PrayerCardStatus.prayed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Dismissible(
          key: Key(widget.prayer.prayerType.name),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) async {
            HapticFeedback.mediumImpact();
            return _showSkipConfirmation();
          },
          onDismissed: (_) => widget.onDismissed?.call(),
          background: _buildDismissBackground(context),
          child: _buildCard(context),
        ),
      ),
    );
  }

  Widget _buildDismissBackground(BuildContext context) {
    return Container(
      alignment: AlignmentDirectional.centerEnd,
      padding: const EdgeInsetsDirectional.only(end: 24),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.skip_next, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(
            'skip'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showSkipConfirmation() {
    return Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.skip_next, color: AppColors.warning),
            const SizedBox(width: 8),
            Text('skip_prayer'.tr),
          ],
        ),
        content: Text('skip_prayer_confirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: Text('skip'.tr, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface,
            _getCardGradientColor().withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getCardShadowColor().withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: _getCardBorderColor().withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            _buildHeader(context),
            _buildStatusButtons(context),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: _buildTimingSelection(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final prayerType = widget.prayer.prayerType;
    final prayerColor = _getPrayerColor(prayerType);
    final isQada = widget.pastDate != null;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Prayer icon
          Hero(
            tag: 'prayer_icon_${prayerType.name}',
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [prayerColor, prayerColor.withValues(alpha: 0.7)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: prayerColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _getPrayerIcon(prayerType),
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Prayer info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.prayer.name,
                      style: AppFonts.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (isQada) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.orange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _formatDateLabel(widget.pastDate!),
                          style: AppFonts.labelSmall.copyWith(
                            color: AppColors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(widget.prayer.dateTime),
                      style: AppFonts.bodySmall.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Time ago badge
                    if (widget.pastDate == null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getTimeAgoColor().withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getTimeAgo(),
                          style: AppFonts.labelSmall.copyWith(
                            color: _getTimeAgoColor(),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButtons(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatusButton(
              label: 'i_prayed'.tr,
              icon: Icons.check_circle_outline_rounded,
              isSelected: widget.status == PrayerCardStatus.prayed,
              color: AppColors.success,
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onStatusChanged(PrayerCardStatus.prayed);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatusButton(
              label: 'i_missed'.tr,
              icon: Icons.cancel_outlined,
              isSelected: widget.status == PrayerCardStatus.missed,
              color: colorScheme.error,
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onStatusChanged(PrayerCardStatus.missed);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.white : color, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppFonts.bodyMedium.copyWith(
                  color: isSelected ? Colors.white : color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimingSelection(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: theme.dividerColor.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text(
            'when_did_you_pray'.tr,
            style: AppFonts.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTimingChip(
                  PrayerTimingQuality.veryEarly,
                  '🌟',
                  'beginning_of_time'.tr,
                ),
                const SizedBox(width: 8),
                _buildTimingChip(
                  PrayerTimingQuality.onTime,
                  '✅',
                  'middle_of_time'.tr,
                ),
                const SizedBox(width: 8),
                _buildTimingChip(
                  PrayerTimingQuality.late,
                  '⏰',
                  'end_of_time'.tr,
                ),
                const SizedBox(width: 8),
                _buildTimingChip(
                  PrayerTimingQuality.onTime,
                  '🤷',
                  'dont_remember'.tr,
                  isDontRemember: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingChip(
    PrayerTimingQuality quality,
    String emoji,
    String label, {
    bool isDontRemember = false,
  }) {
    final isSelected = !isDontRemember && widget.timing == quality;
    final color = isDontRemember
        ? AppColors.textSecondary
        : PrayerTimingHelper.getQualityColor(quality);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTimingChanged(quality);
        },
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppFonts.bodySmall.copyWith(
                  color: isSelected ? Colors.white : color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Color _getCardGradientColor() {
    switch (widget.status) {
      case PrayerCardStatus.prayed:
        return AppColors.success;
      case PrayerCardStatus.missed:
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  Color _getCardShadowColor() => _getCardGradientColor();

  Color _getCardBorderColor() {
    switch (widget.status) {
      case PrayerCardStatus.prayed:
        return AppColors.success;
      case PrayerCardStatus.missed:
        return AppColors.error;
      default:
        return AppColors.grey400;
    }
  }

  Color _getPrayerColor(PrayerName prayer) {
    switch (prayer) {
      case PrayerName.fajr:
        return AppColors.feature1;
      case PrayerName.dhuhr:
        return AppColors.feature3;
      case PrayerName.asr:
        return AppColors.orange;
      case PrayerName.maghrib:
        return AppColors.pink;
      case PrayerName.isha:
        return AppColors.purple;
      default:
        return AppColors.primary;
    }
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

  Color _getTimeAgoColor() {
    final minutesAgo = DateTime.now()
        .difference(widget.prayer.dateTime)
        .inMinutes;
    if (minutesAgo < 30) return AppColors.success;
    if (minutesAgo < 120) return AppColors.warning;
    return AppColors.error;
  }

  String _getTimeAgo() {
    final duration = DateTime.now().difference(widget.prayer.dateTime);
    if (duration.inMinutes < 60) {
      return '${'ago'.tr} ${duration.inMinutes} ${'minutes'.tr}';
    }
    final hours = duration.inHours;
    final mins = duration.inMinutes % 60;
    if (mins == 0) return '${'ago'.tr} $hours ${'hours'.tr}';
    return '${'ago'.tr} $hours:${mins.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12
        ? time.hour - 12
        : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;
    if (diff == 1) return 'yesterday'.tr;
    if (diff < 7) return '${'ago'.tr} $diff ${'days'.tr}';
    return '${date.day}/${date.month}';
  }
}
