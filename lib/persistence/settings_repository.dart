import 'dart:convert';
import '../core/security/pin_hasher.dart';
import 'database_helper.dart';

/// Repository for persistent user preferences, secure PIN secrets, and backup/restore.
class SettingsRepository {
  final DatabaseHelper db;

  SettingsRepository({DatabaseHelper? databaseHelper})
      : db = databaseHelper ?? DatabaseHelper.instance;

  static const String _keyThemeMode = 'theme_mode';
  static const String _keyPinHash = 'pin_hash';
  static const String _keyPinSalt = 'pin_salt';
  static const String _keyHapticsEnabled = 'haptics_enabled';
  static const String _keyNotificationsEnabled = 'notifications_enabled';

  Future<String> getThemeMode() async {
    return await db.getSetting(_keyThemeMode) ?? 'dark';
  }

  Future<void> setThemeMode(String mode) async {
    await db.setSetting(_keyThemeMode, mode);
  }

  Future<bool> hasPinConfigured() async {
    final hash = await db.getSetting(_keyPinHash);
    return hash != null && hash.isNotEmpty;
  }

  Future<String?> getPinHash() async => db.getSetting(_keyPinHash);
  Future<String?> getPinSalt() async => db.getSetting(_keyPinSalt);

  Future<bool> setPin(String pin) async {
    if (!PinHasher.isValidPinFormat(pin)) return false;
    final salt = PinHasher.generateSalt();
    final hash = PinHasher.hashPin(pin, salt);
    await db.setSetting(_keyPinSalt, salt);
    await db.setSetting(_keyPinHash, hash);
    return true;
  }

  Future<bool> verifyPin(String candidatePin) async {
    final salt = await getPinSalt();
    final hash = await getPinHash();
    if (salt == null || hash == null) return false;
    return PinHasher.verifyPin(
        candidatePin: candidatePin, salt: salt, expectedHash: hash);
  }

  Future<void> removePin() async {
    await db.setSetting(_keyPinHash, '');
    await db.setSetting(_keyPinSalt, '');
  }

  Future<bool> areHapticsEnabled() async {
    return (await db.getSetting(_keyHapticsEnabled)) != 'false';
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    await db.setSetting(_keyHapticsEnabled, enabled.toString());
  }

  Future<bool> areNotificationsEnabled() async {
    return (await db.getSetting(_keyNotificationsEnabled)) != 'false';
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await db.setSetting(_keyNotificationsEnabled, enabled.toString());
  }

  /// Exports all configuration as a JSON string.
  Future<String> exportBackupJson() async {
    final profiles = await db.getAllProfiles();
    final schedules = await db.getAllSchedules();
    final dailyLimits = await db.getAllDailyLimits();

    final data = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'profiles': profiles,
      'schedules': schedules,
      'dailyLimits': dailyLimits,
    };
    return jsonEncode(data);
  }

  /// Restores configuration from a JSON string.
  Future<bool> importBackupJson(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final profiles = (data['profiles'] as List<dynamic>?) ?? [];
      final schedules = (data['schedules'] as List<dynamic>?) ?? [];
      final dailyLimits = (data['dailyLimits'] as List<dynamic>?) ?? [];

      for (final p in profiles) {
        await db.insertProfile(Map<String, dynamic>.from(p as Map));
      }
      for (final s in schedules) {
        await db.insertSchedule(Map<String, dynamic>.from(s as Map));
      }
      for (final l in dailyLimits) {
        await db.insertDailyLimit(Map<String, dynamic>.from(l as Map));
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Clears all local application data (Privacy data deletion).
  Future<void> clearAllUserData() async {
    await db.clearAllData();
  }
}
