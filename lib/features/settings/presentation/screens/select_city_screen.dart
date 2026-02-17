import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salah/core/widgets/app_loading.dart';
import 'package:salah/core/widgets/app_text_field.dart';
import 'package:salah/features/settings/controller/selected_city_controller.dart';

class SelectCityScreen extends GetView<SelectedCityController> {
  const SelectCityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              hint: "search_city_hint".tr,
              prefixIcon: Icons.search,
              onChanged: controller.searchCity,
            ),

            const SizedBox(height: 10),

            // Search Results or GPS Section
            Expanded(
              child: Obx(() {
                if (controller.isSearching.value) {
                  return const Center(child: AppLoading());
                }

                if (controller.searchResults.isNotEmpty) {
                  return _buildSearchResults();
                }

                return _buildMainActions(context);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 10),
      itemCount: controller.searchResults.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final result = controller.searchResults[index];
        return ListTile(
          leading: const Icon(Icons.location_on_outlined, color: Colors.grey),
          title: Text(
            result['display_name'].split(',')[0],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            result['display_name'],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
          onTap: () => controller.selectLocation(result),
        );
      },
    );
  }

  Widget _buildMainActions(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Center(
            child: Text("or".tr, style: const TextStyle(color: Colors.grey)),
          ),
          const SizedBox(height: 20),

          // GPS Button
          InkWell(
            onTap: controller.currentLocationLoading.value
                ? null
                : controller.useCurrentLocation,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "use_device_location".tr,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Obx(
                          () => Text(
                            controller.currentLocationLoading.value
                                ? "detecting_location".tr
                                : "auto_location_desc".tr,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (controller.currentLocationLoading.value)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    const Icon(Icons.chevron_left, color: Colors.grey),
                ],
              ),
            ),
          ),

          // Auto-location success feedback
          Padding(
            padding: const EdgeInsets.only(top: 10, right: 10),
            child: Obx(() {
              if (controller.detectedCityName.value.isNotEmpty &&
                  !controller.currentLocationLoading.value) {
                return Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "location_detected".trParams({
                        'city': controller.detectedCityName.value,
                      }),
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            }),
          ),

          const SizedBox(height: 40),

          // Info Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.amber),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "location_importance_info".tr,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
