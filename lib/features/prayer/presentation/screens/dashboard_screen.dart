import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/theme/app_colors.dart';
import 'package:salah/features/prayer/controller/dashboard_controller.dart';
import 'package:salah/features/prayer/presentation/widgets/dashboard_app_bar.dart';
import 'package:salah/features/prayer/presentation/widgets/dashboard_home_content.dart';
import 'package:salah/features/prayer/presentation/widgets/drawer.dart';

class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();

    return Scaffold(
      key: controller.scaffoldKey,
      // Drawer with a gentle overlay tint matching the app palette
      drawer: const CustomDrawer(),
      // Let the content decide its own background (SliverAppBar handles it)
      backgroundColor: AppColors.background,
      // Keep the AppBar and content as-is — visual improvements are in
      // DashboardAppBar and DashboardHomeContent themselves.
      appBar: const DashboardAppBar(),
      body: const DashboardHomeContent(),
    );
  }
}
