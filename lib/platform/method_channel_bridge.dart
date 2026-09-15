import 'package:flutter/services.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/logger.dart';
import '../domain/models/app_info.dart';
import '../domain/models/enums.dart';
import 'platform_bridge.dart';

/// Concrete MethodChannel implementation bridging Dart with native Android Kotlin and iOS Swift modules.
class MethodChannelPlatformBridge implements PlatformBridge {
  static const MethodChannel _channel =
      MethodChannel(AppConstants.methodChannelName);

  @override
  Future<Map<String, dynamic>> getCapabilities() async {
    try {
      final result =
          await _channel.invokeMapMethod<String, dynamic>('getCapabilities');
      return result ?? _fallbackCapabilities();
    } on MissingPluginException {
      AppLogger.warn(
          'MethodChannel getCapabilities not available in current environment');
      return _fallbackCapabilities();
    } catch (e, st) {
      AppLogger.error('Failed to query native capabilities',
          error: e, stackTrace: st);
      return _fallbackCapabilities();
    }
  }

  @override
  Future<int> getMonotonicElapsedRealtime() async {
    try {
      final result =
          await _channel.invokeMethod<int>('getMonotonicElapsedRealtime');
      return result ?? DateTime.now().millisecondsSinceEpoch;
    } on MissingPluginException {
      return DateTime.now().millisecondsSinceEpoch;
    } catch (e) {
      return DateTime.now().millisecondsSinceEpoch;
    }
  }

  @override
  Future<int> getBootCount() async {
    try {
      final result = await _channel.invokeMethod<int>('getBootCount');
      return result ?? 0;
    } on MissingPluginException {
      return 0;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<bool> startEnforcement({
    required List<String> blockedPackages,
    required List<String> allowedPackages,
    required String restrictionLevel,
    required int targetElapsedRealtime,
    required int targetWallClock,
    required String profileName,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('startEnforcement', {
        'blockedPackages': blockedPackages,
        'allowedPackages': allowedPackages,
        'restrictionLevel': restrictionLevel,
        'targetElapsedRealtime': targetElapsedRealtime,
        'targetWallClock': targetWallClock,
        'profileName': profileName,
      });
      return result ?? true;
    } on MissingPluginException {
      AppLogger.info('startEnforcement simulated in mock environment');
      return true;
    } catch (e, st) {
      AppLogger.error('Failed to start native enforcement',
          error: e, stackTrace: st);
      return false;
    }
  }

  @override
  Future<bool> stopEnforcement() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopEnforcement');
      return result ?? true;
    } on MissingPluginException {
      return true;
    } catch (e, st) {
      AppLogger.error('Failed to stop native enforcement',
          error: e, stackTrace: st);
      return false;
    }
  }

  @override
  Future<List<AppInfo>> getInstalledApps() async {
    try {
      final result = await _channel
          .invokeListMethod<Map<dynamic, dynamic>>('getInstalledApps');
      if (result == null || result.isEmpty) {
        return _defaultAppList();
      }

      return result.map((item) {
        final pkg = item['packageName'] as String? ?? 'unknown';
        final name = item['appName'] as String? ?? 'App';
        final isSystem = item['isSystemApp'] as bool? ?? false;
        final isEssential = item['isEssential'] as bool? ?? false;

        return AppInfo(
          packageName: pkg,
          appName: name,
          category: _categorizePackage(pkg),
          isSystemApp: isSystem,
          isEssential: isEssential,
        );
      }).toList();
    } on MissingPluginException {
      return _defaultAppList();
    } catch (e, st) {
      AppLogger.error('Failed to query installed apps',
          error: e, stackTrace: st);
      return _defaultAppList();
    }
  }

  @override
  Future<int> getAppDailyUsage(String packageName) async {
    try {
      final result = await _channel
          .invokeMethod<int>('getAppDailyUsage', {'packageName': packageName});
      return result ?? 0;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<bool> requestUsageStatsPermission() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('requestUsageStatsPermission');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> requestOverlayPermission() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('requestOverlayPermission');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> requestDndPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestDndPermission');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> requestAccessibilitySettings() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('requestAccessibilitySettings');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> setDndFilter(bool enabled) async {
    try {
      final result = await _channel
          .invokeMethod<bool>('setDndFilter', {'enabled': enabled});
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  Map<String, dynamic> _fallbackCapabilities() {
    return {
      'platform': 'container_mock',
      'osVersion': 34,
      'hasUsageStatsPermission': true,
      'hasOverlayPermission': true,
      'hasAccessibilityPermission': false,
      'isDeviceAdminActive': false,
      'isDeviceOwner': false,
      'hasDndPermission': true,
      'hasMonotonicClock': true,
      'isEnforcementRunning': false,
    };
  }

  List<AppInfo> _defaultAppList() {
    return const [
      AppInfo(
        packageName: 'com.android.dialer',
        appName: 'Phone & Emergency',
        category: AppCategory.communication,
        isSystemApp: true,
        isEssential: true,
      ),
      AppInfo(
        packageName: 'com.google.android.apps.messaging',
        appName: 'Messages',
        category: AppCategory.communication,
        isSystemApp: true,
        isEssential: true,
      ),
      AppInfo(
        packageName: 'com.google.android.apps.maps',
        appName: 'Google Maps',
        category: AppCategory.utility,
        isSystemApp: true,
        isEssential: true,
      ),
      AppInfo(
        packageName: 'com.instagram.android',
        appName: 'Instagram',
        category: AppCategory.social,
        isSystemApp: false,
        isEssential: false,
      ),
      AppInfo(
        packageName: 'com.google.android.youtube',
        appName: 'YouTube',
        category: AppCategory.entertainment,
        isSystemApp: false,
        isEssential: false,
      ),
      AppInfo(
        packageName: 'com.twitter.android',
        appName: 'X / Twitter',
        category: AppCategory.social,
        isSystemApp: false,
        isEssential: false,
      ),
      AppInfo(
        packageName: 'com.zhiliaoapp.musically',
        appName: 'TikTok',
        category: AppCategory.social,
        isSystemApp: false,
        isEssential: false,
      ),
      AppInfo(
        packageName: 'com.reddit.frontpage',
        appName: 'Reddit',
        category: AppCategory.news,
        isSystemApp: false,
        isEssential: false,
      ),
      AppInfo(
        packageName: 'com.spotify.music',
        appName: 'Spotify',
        category: AppCategory.entertainment,
        isSystemApp: false,
        isEssential: false,
      ),
    ];
  }

  AppCategory _categorizePackage(String packageName) {
    final lower = packageName.toLowerCase();
    if (lower.contains('instagram') ||
        lower.contains('facebook') ||
        lower.contains('twitter') ||
        lower.contains('tiktok')) {
      return AppCategory.social;
    }
    if (lower.contains('youtube') ||
        lower.contains('netflix') ||
        lower.contains('spotify') ||
        lower.contains('twitch')) {
      return AppCategory.entertainment;
    }
    if (lower.contains('game') ||
        lower.contains('pubg') ||
        lower.contains('candycrush') ||
        lower.contains('roblox')) {
      return AppCategory.gaming;
    }
    if (lower.contains('amazon') ||
        lower.contains('ebay') ||
        lower.contains('shopping')) {
      return AppCategory.shopping;
    }
    if (lower.contains('dialer') ||
        lower.contains('phone') ||
        lower.contains('message') ||
        lower.contains('whatsapp')) {
      return AppCategory.communication;
    }
    return AppCategory.utility;
  }
}
