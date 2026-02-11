import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:salah/core/services/location_service.dart';
import 'package:salah/core/services/prayer_time_service.dart';
import 'package:salah/core/services/storage_service.dart';

class SelectedCityController extends GetxController {
  // Dependencies
  final LocationService _locationService = Get.find<LocationService>();
  final StorageService _storageService = Get.find<StorageService>();
  final PrayerTimeService _prayerTimeService = Get.find<PrayerTimeService>();

  // State
  final currentLocationLoading = false.obs;
  final detectedCityName = ''.obs;
  final isSearching = false.obs;
  final searchResults = <Map<String, dynamic>>[].obs;
  
  // Timer for debouncing search
  Timer? _searchDebounce;

  @override
  void onInit() {
    super.onInit();
    // Automatically try to get current location on entry
    useCurrentLocation(isAutomatic: true);
  }

  /// Fetch location using GPS
  Future<void> useCurrentLocation({bool isAutomatic = false}) async {
    try {
      currentLocationLoading.value = true;
      final position = await _locationService.getCurrentLocation();
      
      if (position != null && !_locationService.isUsingDefaultLocation.value) {
        detectedCityName.value = _locationService.cityName.value;
        
        // Save to storage
        await _storageService.saveLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          cityName: _locationService.cityName.value,
        );
        
        // Refresh prayer times
        await _prayerTimeService.calculatePrayerTimes();
        
        // If manual click (not automatic), close the screen
        if (!isAutomatic) {
          Get.back();
        }
      } else if (!isAutomatic) {
        // Only show error if manual click
        Get.snackbar(
          "error".tr,
          "location_error_gps".tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      currentLocationLoading.value = false;
    }
  }

  /// Search for a city using Nominatim API
  void searchCity(String query) {
    if (query.isEmpty) {
      searchResults.clear();
      return;
    }

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        isSearching.value = true;
        final language = Get.locale?.languageCode ?? 'ar';
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=$query&accept-language=$language&limit=5',
        );

        final response = await http.get(
          url,
          headers: {'User-Agent': 'SalahApp/1.0'},
        );

        if (response.statusCode == 200) {
          final List data = json.decode(response.body);
          searchResults.value = data.cast<Map<String, dynamic>>();
        }
      } catch (e) {
        print("Search error: $e");
      } finally {
        isSearching.value = false;
      }
    });
  }

  /// Select a location from search results
  Future<void> selectLocation(Map<String, dynamic> result) async {
    try {
      final double lat = double.parse(result['lat']);
      final double lon = double.parse(result['lon']);
      
      // Extract city name from display name or address if available
      String cityName = _extractCityName(result);
      String countryName = _extractCountryName(result);

      // Update LocationService
      await _locationService.updateManualLocation(
        latitude: lat,
        longitude: lon,
        city: cityName,
        country: countryName,
      );

      // Save to storage
      await _storageService.saveLocation(
        latitude: lat,
        longitude: lon,
        cityName: cityName,
      );

      // Refresh prayer times
      await _prayerTimeService.calculatePrayerTimes();

      Get.back();
      Get.snackbar(
        "success".tr,
        "location_select_success".trParams({'city': cityName}),
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar("error".tr, "location_select_error".tr);
    }
  }

  String _extractCityName(Map<String, dynamic> result) {
    final address = result['address'] as Map<String, dynamic>?;
    if (address != null) {
      return address['city'] ?? address['town'] ?? address['village'] ?? address['state'] ?? result['name'] ?? '';
    }
    // Fallback: use first part of display_name
    return result['display_name'].split(',')[0];
  }

  String _extractCountryName(Map<String, dynamic> result) {
    final address = result['address'] as Map<String, dynamic>?;
    if (address != null) {
      return address['country'] ?? '';
    }
    // Fallback: use last part of display_name
    final parts = result['display_name'].split(',');
    return parts.last.trim();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    super.onClose();
  }
}
