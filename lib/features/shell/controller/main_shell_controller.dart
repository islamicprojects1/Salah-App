import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Controller for the main shell with Bottom Navigation Bar.
///
/// Holds scaffoldKey for the drawer and current tab index.
class MainShellController extends GetxController {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final currentIndex = 0.obs;

  static const int tabHome = 0;
  static const int tabFamily = 1;

  void setTab(int index) => currentIndex.value = index;

  void openDrawer() => scaffoldKey.currentState?.openDrawer();
}
