import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/features/prayer/controller/dashboard_controller.dart';
import 'package:salah/features/prayer/presentation/widgets/dashboard_app_bar.dart';
import 'package:salah/features/prayer/presentation/widgets/dashboard_home_content.dart';
import 'package:salah/features/prayer/presentation/widgets/drawer.dart';

class DashboardScreen extends GetView<DashboardController> {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();
    final theme = Theme.of(context);

    return Scaffold(
      key: controller.scaffoldKey,
      drawer: const CustomDrawer(),
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const DashboardAppBar(),
      body: const DashboardHomeContent(),
    );
  }
}
