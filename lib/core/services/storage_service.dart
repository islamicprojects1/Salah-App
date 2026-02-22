import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:salah/core/constants/enums.dart';
import 'package:salah/core/constants/storage_keys.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// STORAGE SERVICE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//
// ✅ ضروري — التخزين المحلي الدائم للتطبيق (يبقى بعد إغلاق التطبيق).
//
// يستخدم GetStorage (أسرع من SharedPreferences، متزامن، بدون async).
//
// ماذا يُخزَّن هنا؟
//   • إعدادات المستخدم   : اللغة، الثيم، الإشعارات، طريقة الحساب
//   • حالة التطبيق       : أول تشغيل، الـ onboarding مكتمل
//   • الموقع المحفوظ     : خط العرض/الطول/اسم المدينة
//   • الإجراءات المعلّقة : صلاة مسجّلة من إشعار قبل فتح التطبيق
//   • بيانات مؤقتة      : streak، صلوات اليوم (cache سريع)
//   • طابور المزامنة    : عناصر انتظار الإنترنت (backup للـ SQLite)
//
// الفرق بين StorageService و DatabaseHelper:
//   StorageService → إعدادات وبيانات صغيرة (key-value)
//   DatabaseHelper → سجلات الصلاة وقوائم كبيرة (SQLite tables)
//
// الاستخدام:
//   StorageService.to.getLanguage()
//   await StorageService.to.setThemeMode('dark')
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class StorageService extends GetxService {
  static StorageService get to => Get.find();

  late final GetStorage _box;
  bool _isInitialized = false;

  // ══════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ══════════════════════════════════════════════════════════════

  Future<StorageService> init() async {
    if (_isInitialized) return this;
    _isInitialized = true;
    await GetStorage.init();
    _box = GetStorage();
    return this;
  }

  // ══════════════════════════════════════════════════════════════
  // GENERIC OPS
  // ══════════════════════════════════════════════════════════════

  T? read<T>(String key) => _box.read<T>(key);
  Future<void> write(String key, dynamic value) => _box.write(key, value);
  Future<void> remove(String key) => _box.remove(key);
  bool hasData(String key) => _box.hasData(key);
  Future<void> clearAll() => _box.erase();

  // ══════════════════════════════════════════════════════════════
  // LANGUAGE
  // ══════════════════════════════════════════════════════════════

  /// اللغة الحالية — افتراضي: لغة الجهاز أو العربية
  String getLanguage() =>
      read<String>(StorageKeys.language) ??
      Get.deviceLocale?.languageCode ??
      'ar';

  Future<void> setLanguage(String code) => write(StorageKeys.language, code);

  // ══════════════════════════════════════════════════════════════
  // THEME
  // ══════════════════════════════════════════════════════════════

  /// وضع الثيم: 'light' | 'dark' | 'system'
  String getThemeMode() => read<String>(StorageKeys.themeMode) ?? 'system';

  Future<void> setThemeMode(String mode) => write(StorageKeys.themeMode, mode);

  // ══════════════════════════════════════════════════════════════
  // ONBOARDING
  // ══════════════════════════════════════════════════════════════

  bool isFirstTime() => read<bool>(StorageKeys.isFirstTime) ?? true;
  Future<void> setNotFirstTime() => write(StorageKeys.isFirstTime, false);

  bool isOnboardingCompleted() =>
      read<bool>(StorageKeys.onboardingCompleted) ?? false;
  Future<void> setOnboardingCompleted() =>
      write(StorageKeys.onboardingCompleted, true);

  // ══════════════════════════════════════════════════════════════
  // LOCATION
  // ══════════════════════════════════════════════════════════════

  double? getLatitude() => read<double>(StorageKeys.latitude);
  double? getLongitude() => read<double>(StorageKeys.longitude);
  String? getCityName() => read<String>(StorageKeys.cityName);

  /// حفظ الموقع الجغرافي بعد جلبه من GPS أو اختيار المستخدم
  Future<void> saveLocation({
    required double latitude,
    required double longitude,
    required String cityName,
  }) async {
    await write(StorageKeys.latitude, latitude);
    await write(StorageKeys.longitude, longitude);
    await write(StorageKeys.cityName, cityName);
  }

  // ══════════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ══════════════════════════════════════════════════════════════

  bool areNotificationsEnabled() =>
      read<bool>(StorageKeys.notificationsEnabled) ?? true;
  Future<void> setNotificationsEnabled(bool v) =>
      write(StorageKeys.notificationsEnabled, v);

  /// إعداد الإشعار لصلاة معينة (يستخدم مفتاح الصلاة مباشرة)
  bool getPrayerNotification(String prayerKey) => read<bool>(prayerKey) ?? true;
  Future<void> setPrayerNotification(String prayerKey, bool v) =>
      write(prayerKey, v);

  // ══════════════════════════════════════════════════════════════
  // NOTIFICATION SOUND MODE
  // ══════════════════════════════════════════════════════════════

  /// نوع الصوت: adhan | vibrate | silent
  NotificationSoundMode getNotificationSoundMode() {
    final stored = read<String>(StorageKeys.notificationSoundMode);
    if (stored == null) return NotificationSoundMode.adhan;
    return NotificationSoundMode.values.firstWhere(
      (e) => e.name == stored,
      orElse: () => NotificationSoundMode.adhan,
    );
  }

  Future<void> setNotificationSoundMode(NotificationSoundMode mode) =>
      write(StorageKeys.notificationSoundMode, mode.name);

  // ══════════════════════════════════════════════════════════════
  // APPROACHING ALERT & TAKBEER
  // ══════════════════════════════════════════════════════════════

  /// الخيارات المتاحة لوقت تنبيه الاقتراب (بالدقائق)
  static const List<int> approachingMinutesOptions = [5, 10, 15, 20, 30];

  bool get approachingAlertEnabled =>
      read<bool>(StorageKeys.approachingAlertEnabled) ?? false;
  Future<void> setApproachingAlertEnabled(bool v) =>
      write(StorageKeys.approachingAlertEnabled, v);

  /// كم دقيقة قبل الأذان يُرسَل تنبيه الاقتراب
  int get approachingAlertMinutes =>
      read<int>(StorageKeys.approachingAlertMinutes) ?? 15;
  Future<void> setApproachingAlertMinutes(int minutes) =>
      write(StorageKeys.approachingAlertMinutes, minutes);

  /// دقائق تنبيه الفجر (20 افتراضياً)
  int get approachingFajrMinutes =>
      read<int>(StorageKeys.approachingFajrMinutes) ?? 20;

  /// تشغيل التكبير عند دخول وقت الصلاة
  bool get takbeerAtPrayerEnabled =>
      read<bool>(StorageKeys.takbeerAtPrayerEnabled) ?? true;
  Future<void> setTakbeerAtPrayerEnabled(bool v) =>
      write(StorageKeys.takbeerAtPrayerEnabled, v);

  // ══════════════════════════════════════════════════════════════
  // PENDING ACTIONS (من الإشعارات)
  // ══════════════════════════════════════════════════════════════
  //
  // عندما يضغط المستخدم "صلّيت" من الإشعار وهو خارج التطبيق،
  // نحفظ العملية هنا ونُنفّذها حين يفتح التطبيق.

  Future<void> setPendingPrayerLog(String prayer, DateTime time) => write(
    StorageKeys.pendingPrayerLog,
    jsonEncode({'prayer': prayer, 'time': time.toIso8601String()}),
  );

  Map<String, dynamic>? getPendingPrayerLog() {
    final data = read<String>(StorageKeys.pendingPrayerLog);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  Future<void> clearPendingPrayerLog() => remove(StorageKeys.pendingPrayerLog);

  Future<void> setPendingMissedPrayer(String prayer, DateTime time) => write(
    StorageKeys.pendingMissedPrayer,
    jsonEncode({'prayer': prayer, 'time': time.toIso8601String()}),
  );

  Map<String, dynamic>? getPendingMissedPrayer() {
    final data = read<String>(StorageKeys.pendingMissedPrayer);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  Future<void> clearPendingMissedPrayer() =>
      remove(StorageKeys.pendingMissedPrayer);

  // ══════════════════════════════════════════════════════════════
  // SYNC QUEUE (backup للـ SQLite عند الـ edge cases)
  // ══════════════════════════════════════════════════════════════
  //
  // ملاحظة: مصدر الحقيقة الرئيسي هو DatabaseHelper.sync_queue
  // هذا الطابور backup بسيط لعمليات صغيرة لا تحتاج SQLite.

  Future<void> addToSyncQueue(Map<String, dynamic> item) async {
    final queue = getSyncQueue();
    queue.add({
      ...item,
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'createdAt': DateTime.now().toIso8601String(),
    });
    await write(StorageKeys.offlineSyncQueue, jsonEncode(queue));
  }

  List<Map<String, dynamic>> getSyncQueue() {
    final data = read<String>(StorageKeys.offlineSyncQueue);
    if (data == null) return [];
    return (jsonDecode(data) as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> removeFromSyncQueue(String id) async {
    final queue = getSyncQueue()..removeWhere((e) => e['id'] == id);
    await write(StorageKeys.offlineSyncQueue, jsonEncode(queue));
  }

  Future<void> clearSyncQueue() => remove(StorageKeys.offlineSyncQueue);

  // ══════════════════════════════════════════════════════════════
  // LAST SYNC TIMESTAMP
  // ══════════════════════════════════════════════════════════════

  Future<void> updateLastSync() =>
      write(StorageKeys.lastSyncTimestamp, DateTime.now().toIso8601String());

  DateTime? getLastSync() {
    final data = read<String>(StorageKeys.lastSyncTimestamp);
    return data != null ? DateTime.tryParse(data) : null;
  }

  // ══════════════════════════════════════════════════════════════
  // USER DATA CACHE (cache سريع بدون SQLite)
  // ══════════════════════════════════════════════════════════════

  Future<void> cacheStreak(int streak) =>
      write(StorageKeys.currentStreak, streak);
  int getCachedStreak() => read<int>(StorageKeys.currentStreak) ?? 0;

  /// صلوات اليوم المُسجَّلة (للعرض السريع بدون query لـ SQLite)
  Future<void> cacheTodayPrayers(List<String> prayers) =>
      write(StorageKeys.todayLoggedPrayers, jsonEncode(prayers));

  List<String> getCachedTodayPrayers() {
    final data = read<String>(StorageKeys.todayLoggedPrayers);
    if (data == null) return [];
    return (jsonDecode(data) as List).map((e) => e.toString()).toList();
  }
}
