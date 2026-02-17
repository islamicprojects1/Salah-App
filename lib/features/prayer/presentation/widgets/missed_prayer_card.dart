import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/helpers/prayer_timing_helper.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/features/prayer/data/models/prayer_time_model.dart';

/// Premium missed prayer card with smooth animations and swipe gestures
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

    // Auto-expand if prayed
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
          key: Key(widget.prayer.prayerType?.name ?? 'prayer'),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            HapticFeedback.mediumImpact();
            return await _showSkipConfirmation();
          },
          onDismissed: (_) => widget.onDismissed?.call(),
          background: _buildDismissBackground(),
          child: _buildCard(),
        ),
      ),
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.skip_next, color: AppColors.white, size: 28),
          const SizedBox(height: 4),
          Text(
            'skip'.tr,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showSkipConfirmation() async {
    return await Get.dialog<bool>(
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
            child: Text(
              'skip'.tr,
              style: const TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.white,
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
            _buildHeader(),
            _buildStatusButtons(),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: _buildTimingSelection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final prayerType = widget.prayer.prayerType ?? PrayerName.fajr;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Prayer Icon with animated background
          Hero(
            tag: 'prayer_icon_${prayerType.name}',
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getPrayerColor(prayerType),
                    _getPrayerColor(prayerType).withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _getPrayerColor(prayerType).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _getPrayerIcon(prayerType),
                color: AppColors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Prayer Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.prayer.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(widget.prayer.dateTime),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Show date label for past days, or time-ago badge for today
                    if (widget.pastDate != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatDateLabel(widget.pastDate!),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
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
                          style: TextStyle(
                            fontSize: 11,
                            color: _getTimeAgoColor(),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Status indicator
          _buildStatusIndicator(),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    if (widget.status == PrayerCardStatus.prayed) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check_circle, color: AppColors.success, size: 24),
      );
    } else if (widget.status == PrayerCardStatus.missed) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.cancel, color: AppColors.error, size: 24),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildStatusButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatusButton(
              label: 'i_prayed'.tr,
              icon: Icons.check_circle_outline,
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
              color: AppColors.error,
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
      color: AppColors.transparent,
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
              Icon(icon, color: isSelected ? AppColors.white : color, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.white : color,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimingSelection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'when_did_you_pray'.tr,
            style: TextStyle(
              fontSize: 14,
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
      color: AppColors.transparent,
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
                style: TextStyle(
                  color: isSelected ? AppColors.white : color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  Color _getCardGradientColor() {
    if (widget.status == PrayerCardStatus.prayed) return AppColors.success;
    if (widget.status == PrayerCardStatus.missed) return AppColors.error;
    return AppColors.primary;
  }

  Color _getCardShadowColor() {
    if (widget.status == PrayerCardStatus.prayed) return AppColors.success;
    if (widget.status == PrayerCardStatus.missed) return AppColors.error;
    return AppColors.primary;
  }

  Color _getCardBorderColor() {
    if (widget.status == PrayerCardStatus.prayed) return AppColors.success;
    if (widget.status == PrayerCardStatus.missed) return AppColors.error;
    return AppColors.grey400;
  }

  Color _getPrayerColor(PrayerName prayer) {
    switch (prayer) {
      case PrayerName.fajr:
        return AppColors.feature1; // Indigo
      case PrayerName.dhuhr:
        return AppColors.feature3; // Amber
      case PrayerName.asr:
        return AppColors.orange; // Orange
      case PrayerName.maghrib:
        return AppColors.pink; // Pink
      case PrayerName.isha:
        return AppColors.purple; // Purple
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
    } else {
      final hours = duration.inHours;
      final mins = duration.inMinutes % 60;
      if (mins == 0) {
        return '${'ago'.tr} $hours ${'hours'.tr}';
      }
      return '${'ago'.tr} $hours:${mins.toString().padLeft(2, '0')}';
    }
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
