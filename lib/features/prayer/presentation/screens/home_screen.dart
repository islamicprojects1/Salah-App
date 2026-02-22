import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/routes/app_routes.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/core/theme/app_fonts.dart';
import 'package:salah/core/constants/app_dimensions.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingLG,
              vertical: AppDimensions.paddingMD,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildNextPrayerCard(context),
                const SizedBox(height: AppDimensions.paddingLG),
                _buildPrayerTimesList(context),
                const SizedBox(height: AppDimensions.paddingXL),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final now = DateTime.now();
    final weekdays = [
      'الأحد',
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
    ];
    final months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.primary,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white),
          onPressed: () => Get.toNamed(AppRoutes.settings),
          tooltip: 'settings'.tr,
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
          child: Stack(
            children: [
              // Decorative geometric pattern (Islamic art inspired)
              Positioned(
                top: -40,
                right: -40,
                child: _GeometricCircle(size: 200, opacity: 0.06),
              ),
              Positioned(
                bottom: -20,
                left: -30,
                child: _GeometricCircle(size: 150, opacity: 0.05),
              ),
              // Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'welcome'.tr,
                                  style: AppFonts.bodyMedium.copyWith(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'app_name'.tr,
                                  style: AppFonts.headlineMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _LocationChip(),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${weekdays[now.weekday % 7]}، ${now.day} ${months[now.month - 1]}',
                                style: AppFonts.labelLarge.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '١٥ رمضان ١٤٤٦', // Hijri date — replace with actual calculation
                                style: AppFonts.titleSmall.copyWith(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNextPrayerCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top section with gradient
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.primaryLight.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppDimensions.radiusLG),
                topRight: Radius.circular(AppDimensions.radiusLG),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'next_prayer'.tr,
                        style: AppFonts.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'dhuhr'.tr,
                        style: AppFonts.headlineMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '12:30 PM',
                        style: AppFonts.titleLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                _CountdownChip(),
              ],
            ),
          ),
          // Progress bar
          _PrayerProgressBar(),
        ],
      ),
    );
  }

  Widget _buildPrayerTimesList(BuildContext context) {
    final prayers = [
      _PrayerData(
        name: 'fajr',
        nameAr: 'الفجر',
        time: '05:30',
        period: 'ص',
        icon: Icons.nights_stay_rounded,
        color: AppColors.fajr,
        isPassed: true,
      ),
      _PrayerData(
        name: 'sunrise',
        nameAr: 'الشروق',
        time: '06:45',
        period: 'ص',
        icon: Icons.wb_twilight_rounded,
        color: AppColors.orange,
        isPassed: true,
      ),
      _PrayerData(
        name: 'dhuhr',
        nameAr: 'الظهر',
        time: '12:30',
        period: 'م',
        icon: Icons.wb_sunny_rounded,
        color: AppColors.dhuhr,
        isNext: true,
      ),
      _PrayerData(
        name: 'asr',
        nameAr: 'العصر',
        time: '04:00',
        period: 'م',
        icon: Icons.wb_sunny_outlined,
        color: AppColors.asr,
      ),
      _PrayerData(
        name: 'maghrib',
        nameAr: 'المغرب',
        time: '06:15',
        period: 'م',
        icon: Icons.wb_twilight_outlined,
        color: AppColors.maghrib,
      ),
      _PrayerData(
        name: 'isha',
        nameAr: 'العشاء',
        time: '07:45',
        period: 'م',
        icon: Icons.nightlight_rounded,
        color: AppColors.isha,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 14, right: 4),
          child: Text(
            'prayer_times'.tr,
            style: AppFonts.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: prayers.asMap().entries.map((entry) {
              final index = entry.key;
              final prayer = entry.value;
              final isLast = index == prayers.length - 1;
              return _PrayerTimeRow(prayer: prayer, isLast: isLast);
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────

class _LocationChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on_rounded,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 5),
            Text(
              'الرياض',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountdownChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.timer_outlined, color: Colors.white, size: 16),
          const SizedBox(height: 4),
          Text(
            '2:30',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              fontFamily: 'Cairo',
            ),
          ),
          Text(
            'ساعة',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 10,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerProgressBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الفجر  05:30',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontFamily: 'Cairo',
                ),
              ),
              Text(
                'العشاء  07:45',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 0.42,
              minHeight: 6,
              backgroundColor: AppColors.primary.withValues(alpha: 0.10),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerData {
  final String name;
  final String nameAr;
  final String time;
  final String period;
  final IconData icon;
  final Color color;
  final bool isPassed;
  final bool isNext;

  const _PrayerData({
    required this.name,
    required this.nameAr,
    required this.time,
    required this.period,
    required this.icon,
    required this.color,
    this.isPassed = false,
    this.isNext = false,
  });
}

class _PrayerTimeRow extends StatelessWidget {
  final _PrayerData prayer;
  final bool isLast;

  const _PrayerTimeRow({required this.prayer, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: prayer.isNext
            ? prayer.color.withValues(alpha: 0.05)
            : Colors.transparent,
        border: prayer.isNext
            ? Border(right: BorderSide(color: prayer.color, width: 3))
            : null,
        borderRadius: prayer.isNext || isLast || prayer.isPassed
            ? BorderRadius.only(
                topLeft: prayer.name == 'fajr'
                    ? const Radius.circular(AppDimensions.radiusLG)
                    : Radius.zero,
                topRight: prayer.name == 'fajr'
                    ? const Radius.circular(AppDimensions.radiusLG)
                    : Radius.zero,
                bottomLeft: isLast
                    ? const Radius.circular(AppDimensions.radiusLG)
                    : Radius.zero,
                bottomRight: isLast
                    ? const Radius.circular(AppDimensions.radiusLG)
                    : Radius.zero,
              )
            : null,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: prayer.isPassed
                        ? Colors.grey.withValues(alpha: 0.08)
                        : prayer.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    prayer.isPassed ? Icons.check_circle_rounded : prayer.icon,
                    color: prayer.isPassed
                        ? Colors.grey.shade400
                        : prayer.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prayer.nameAr,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: prayer.isNext
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: prayer.isPassed
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      if (prayer.isNext)
                        Text(
                          'التالية',
                          style: TextStyle(
                            fontSize: 11,
                            color: prayer.color,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Cairo',
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '${prayer.time} ${prayer.period}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: prayer.isNext
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: prayer.isNext
                        ? prayer.color
                        : (prayer.isPassed
                              ? AppColors.textSecondary
                              : AppColors.textPrimary),
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
          if (!isLast)
            Divider(
              height: 1,
              indent: 68,
              endIndent: 16,
              color: Colors.grey.withValues(alpha: 0.10),
            ),
        ],
      ),
    );
  }
}

class _GeometricCircle extends StatelessWidget {
  final double size;
  final double opacity;
  const _GeometricCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
      ),
    );
  }
}
