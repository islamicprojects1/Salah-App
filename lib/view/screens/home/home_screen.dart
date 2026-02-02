import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/routes/app_routes.dart';
import 'package:salah/core/theme/app_colors.dart';

/// Home screen - main screen showing prayer times
///
/// This is a basic structure that will be expanded with prayer time features
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('app_name'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Get.toNamed(AppRoutes.settings),
            tooltip: 'settings'.tr,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Card
              _buildWelcomeCard(context),
              const SizedBox(height: 16),

              // Next Prayer Card
              _buildNextPrayerCard(context),
              const SizedBox(height: 16),

              // Prayer Times List
              _buildPrayerTimesList(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryLight],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.wb_sunny_outlined,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'welcome'.tr,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    Text(
                      DateTime.now().day.toString(),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextPrayerCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'next_prayer'.tr,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'dhuhr'.tr,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '12:30 PM',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 18,
                    color: AppColors.secondaryDark,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '2:30:00',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.secondaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerTimesList(BuildContext context) {
    final prayers = [
      {
        'name': 'fajr',
        'time': '05:30 AM',
        'icon': Icons.dark_mode_outlined,
        'color': AppColors.fajr,
      },
      {
        'name': 'sunrise',
        'time': '06:45 AM',
        'icon': Icons.wb_twilight,
        'color': Colors.orange,
      },
      {
        'name': 'dhuhr',
        'time': '12:30 PM',
        'icon': Icons.wb_sunny,
        'color': AppColors.dhuhr,
      },
      {
        'name': 'asr',
        'time': '04:00 PM',
        'icon': Icons.wb_sunny_outlined,
        'color': AppColors.asr,
      },
      {
        'name': 'maghrib',
        'time': '06:15 PM',
        'icon': Icons.nights_stay_outlined,
        'color': AppColors.maghrib,
      },
      {
        'name': 'isha',
        'time': '07:45 PM',
        'icon': Icons.nightlight_round,
        'color': AppColors.isha,
      },
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'prayer_times'.tr,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            ...prayers.map(
              (prayer) => _buildPrayerRow(
                context,
                (prayer['name'] as String).tr,
                prayer['time'] as String,
                prayer['icon'] as IconData,
                prayer['color'] as Color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerRow(
    BuildContext context,
    String name,
    String time,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(name, style: Theme.of(context).textTheme.titleMedium),
          ),
          Text(
            time,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
