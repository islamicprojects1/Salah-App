import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';
import 'package:salah/core/di/injection_container.dart';
import 'package:salah/core/services/storage_service.dart';
import 'package:salah/core/constants/storage_keys.dart';

/// Service to handle Adhan and other app sounds
class AudioService extends GetxService {
  late final AudioPlayer _player;
  final _storage = sl<StorageService>();

  bool _isInitialized = false;

  Future<AudioService> init() async {
    if (_isInitialized) return this;
    _isInitialized = true;
    _player = AudioPlayer();
    return this;
  }

  /// Play the full Adhan from assets
  Future<void> playAdhan() async {
    // Check if adhan is enabled in settings
    final enabled = _storage.read<bool>(StorageKeys.fajrNotification) ?? true;
    if (!enabled) return;

    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/athan.mp3'));
    } catch (e) {
      print('Error playing adhan: $e');
    }
  }

  /// Stop any playing audio
  Future<void> stop() async {
    await _player.stop();
  }

  @override
  void onClose() {
    _player.dispose();
    super.onClose();
  }
}
