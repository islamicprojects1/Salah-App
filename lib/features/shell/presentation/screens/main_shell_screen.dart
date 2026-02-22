import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/features/family/presentation/screens/family_screen.dart';
import 'package:salah/features/prayer/controller/dashboard_controller.dart';
import 'package:salah/features/prayer/presentation/widgets/dashboard_app_bar.dart';
import 'package:salah/features/prayer/presentation/widgets/dashboard_home_content.dart';
import 'package:salah/features/prayer/presentation/widgets/drawer.dart';
import 'package:salah/features/shell/controller/main_shell_controller.dart';

/// Main shell with Bottom Navigation Bar: Home + Family tabs.
class MainShellScreen extends GetView<MainShellController> {
  const MainShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: controller.scaffoldKey,
      drawer: const CustomDrawer(),
      backgroundColor: AppColors.background,
      body: Obx(
        () => IndexedStack(
          index: controller.currentIndex.value,
          children: const [
            _DashboardTab(),
            FamilyScreen(),
          ],
        ),
      ),
      bottomNavigationBar: Obx(() => _buildBottomNav(context)),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final index = controller.currentIndex.value;
    final colorScheme = Theme.of(context).colorScheme;

    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (i) {
        HapticFeedback.selectionClick();
        controller.setTab(i);
      },
      destinations: [
        NavigationDestination(
          icon: Icon(Icons.home_outlined, color: colorScheme.onSurfaceVariant),
          selectedIcon: Icon(Icons.home_rounded, color: colorScheme.onPrimary),
          label: 'home'.tr,
        ),
        NavigationDestination(
          icon: Icon(Icons.people_outline_rounded,
              color: colorScheme.onSurfaceVariant),
          selectedIcon: Icon(Icons.people_rounded, color: colorScheme.onPrimary),
          label: 'family'.tr,
        ),
      ],
    );
  }
}

/// Dashboard tab content: AppBar + Home content.
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const DashboardAppBar(),
        const Expanded(child: DashboardHomeContent()),
      ],
    );
  }
}
