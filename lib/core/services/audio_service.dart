import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';
import 'package:salah/core/di/injection_container.dart';
import 'package:salah/core/services/storage_service.dart';
import 'package:salah/core/constants/storage_keys.dart';
import 'package:salah/core/constants/enums.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// AUDIO SERVICE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// ✅ ضروري — يُشغّل صوتي الصلاة داخل التطبيق:
//   • صوت الاقتراب  (X دقيقة قبل وقت الصلاة) — مختلف لكل صلاة
//   • التكبير        (عند دخول وقت الصلاة بدلاً من الأذان الكامل)
//
// ملاحظة: لا يوجد أذان كامل في التطبيق بقرار تصميمي واضح.
// الإشعارات الخارجية (خارج التطبيق) تُشغَّل بواسطة NotificationService
// عبر Android raw resources، وهذا الملف للتشغيل داخل التطبيق فقط.
//
// الاستخدام:
//   AudioService.to.playTakbeer();
//   AudioService.to.playApproachSound(PrayerName.fajr);
//   AudioService.to.stop();
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// مسارات ملفات الصوت في assets/sounds/
///
/// فصل المسارات في كلاس مستقل يسهّل تعديلها دون المساس بمنطق الخدمة.
class SoundAssets {
  SoundAssets._();

  /// صوت التكبير — يُشغَّل عند دخول وقت الصلاة (داخل التطبيق)
  static const String takbeer = 'assets/sounds/Takbir 1.mp3';

  /// اسم ملف التكبير كـ Android raw resource (بدون مسافات/امتداد)
  static const String takbeerRaw = 'takbir_1';

  /// مسار صوت الاقتراب الخاص بكل صلاة (asset path)
  static String approachForPrayer(PrayerName prayer) {
    switch (prayer) {
      case PrayerName.fajr:
        return 'assets/sounds/fagrsoon.mp3';
      case PrayerName.dhuhr:
        return 'assets/sounds/zohrsoon.mp3';
      case PrayerName.asr:
        return 'assets/sounds/asrsoon.mp3';
      case PrayerName.maghrib:
        return 'assets/sounds/maghribsoon.mp3';
      case PrayerName.isha:
        return 'assets/sounds/eshaasoon.mp3';
      default:
        return 'assets/sounds/fagrsoon.mp3';
    }
  }

  /// اسم ملف الاقتراب كـ Android raw resource (بدون مسافات/امتداد)
  static String approachRawForPrayer(PrayerName prayer) {
    switch (prayer) {
      case PrayerName.fajr:
        return 'fagrsoon';
      case PrayerName.dhuhr:
        return 'zohrsoon';
      case PrayerName.asr:
        return 'asrsoon';
      case PrayerName.maghrib:
        return 'maghribsoon';
      case PrayerName.isha:
        return 'eshaasoon';
      default:
        return 'fagrsoon';
    }
  }
}

class AudioService extends GetxService {
  // اختصار للوصول السريع: AudioService.to.playTakbeer()
  static AudioService get to => Get.find();

  late final AudioPlayer _player;
  final _storage = sl<StorageService>();

  // ══════════════════════════════════════════════════════════════
  // OBSERVABLE STATE
  // ══════════════════════════════════════════════════════════════

  /// هل يوجد صوت يُشغَّل الآن
  final isPlaying = false.obs;

  bool _isInitialized = false;

  // ══════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ══════════════════════════════════════════════════════════════

  Future<AudioService> init() async {
    if (_isInitialized) return this;
    _isInitialized = true;
    _player = AudioPlayer();

    // تتبّع حالة التشغيل تلقائياً
    _player.onPlayerStateChanged.listen((state) {
      isPlaying.value = state == PlayerState.playing;
    });

    return this;
  }

  // ══════════════════════════════════════════════════════════════
  // PUBLIC API
  // ══════════════════════════════════════════════════════════════

  /// يُشغَّل عند دخول وقت الصلاة (داخل التطبيق فقط).
  /// يحترم إعداد المستخدم — إذا أوقف الإشعارات الصوتية لا يُشغَّل.
  Future<void> playAdhan() async {
    final enabled =
        _storage.read<bool>(StorageKeys.adhanNotificationsEnabled) ?? true;
    if (!enabled) return;
    await _play(AssetSource(SoundAssets.takbeer));
  }

  /// يُشغَّل قبل وقت الصلاة بـ X دقيقة (للمعاينة أو في التطبيق).
  Future<void> playApproachSound(PrayerName prayer) async {
    await _play(AssetSource(SoundAssets.approachForPrayer(prayer)));
  }

  /// يُشغَّل التكبير مباشرة (للمعاينة في الإعدادات).
  Future<void> playTakbeer() async {
    await _play(AssetSource(SoundAssets.takbeer));
  }

  /// إيقاف أي صوت يُشغَّل حالياً.
  Future<void> stop() async {
    await _player.stop();
  }

  // ══════════════════════════════════════════════════════════════
  // PRIVATE
  // ══════════════════════════════════════════════════════════════

  /// دالة مساعدة: تُوقف الصوت الحالي ثم تُشغّل المصدر الجديد.
  Future<void> _play(Source source) async {
    try {
      await _player.stop();
      await _player.play(source);
    } catch (_) {
      // فشل التشغيل لا يوقف التطبيق — نتجاهله بصمت
    }
  }

  // ══════════════════════════════════════════════════════════════
  // CLEANUP
  // ══════════════════════════════════════════════════════════════

  @override
  void onClose() {
    _player.dispose();
    super.onClose();
  }
}
