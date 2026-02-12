import 'dart:async';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service for monitoring internet connectivity
class ConnectivityService extends GetxService {
  // ============================================================
  // OBSERVABLE STATE
  // ============================================================
  
  final isConnected = true.obs;
  final connectionType = Rxn<ConnectivityResult>();
  
  // ============================================================
  // PRIVATE
  // ============================================================
  
  late final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isInitialized = false;

  /// Initialize the service
  Future<ConnectivityService> init() async {
    if (_isInitialized) return this;
    _connectivity = Connectivity();
    _isInitialized = true;
    await _checkConnectivity();
    _startListening();
    return this;
  }

  /// Check current connectivity
  Future<void> _checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _updateConnectionStatus(results);
  }

  /// Start listening to connectivity changes
  void _startListening() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _updateConnectionStatus(results);
    });
  }

  /// Update connection status based on results
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      isConnected.value = false;
      connectionType.value = ConnectivityResult.none;
    } else {
      isConnected.value = true;
      // Get the first available connection type
      connectionType.value = results.first;
    }
  }

  // ============================================================
  // GETTERS
  // ============================================================
  
  /// Check if connected to WiFi
  bool get isWifi => connectionType.value == ConnectivityResult.wifi;
  
  /// Check if connected to Mobile data
  bool get isMobile => connectionType.value == ConnectivityResult.mobile;
  
  /// Check if connected to Ethernet
  bool get isEthernet => connectionType.value == ConnectivityResult.ethernet;
  
  /// Check if offline
  bool get isOffline => !isConnected.value;

  // ============================================================
  // METHODS
  // ============================================================
  
  /// Force check connectivity
  Future<bool> checkConnection() async {
    await _checkConnectivity();
    return isConnected.value;
  }

  /// Get connection type as string
  String get connectionTypeString {
    switch (connectionType.value) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.none:
      case null:
        return 'No Connection';
      default:
        return 'Unknown';
    }
  }

  // ============================================================
  // CLEANUP
  // ============================================================
  
  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
