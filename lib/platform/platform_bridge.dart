import '../domain/models/app_info.dart';

/// Abstract contract for native platform enforcement adapters (Android & iOS).
abstract class PlatformBridge {
  /// Returns platform capabilities map.
  Future<Map<String, dynamic>> getCapabilities();

  /// Queries monotonic elapsed realtime in milliseconds from kernel.
  Future<int> getMonotonicElapsedRealtime();

  /// Queries device boot count (Android only).
  Future<int> getBootCount();

  /// Starts native foreground enforcement service / Screen Time shield.
  Future<bool> startEnforcement({
    required List<String> blockedPackages,
    required List<String> allowedPackages,
    required String restrictionLevel,
    required int targetElapsedRealtime,
    required int targetWallClock,
    required String profileName,
  });

  /// Stops native enforcement service / clears Screen Time shields.
  Future<bool> stopEnforcement();

  /// Retrieves list of installed applications with metadata.
  Future<List<AppInfo>> getInstalledApps();

  /// Retrieves today's foreground usage for an app in seconds.
  Future<int> getAppDailyUsage(String packageName);

  /// Launches system settings for Usage Access.
  Future<bool> requestUsageStatsPermission();

  /// Launches system settings for Display Over Other Apps (Overlay).
  Future<bool> requestOverlayPermission();

  /// Launches system settings for Do Not Disturb policy access.
  Future<bool> requestDndPermission();

  /// Launches system settings for Accessibility services.
  Future<bool> requestAccessibilitySettings();

  /// Enables or disables Do Not Disturb filter.
  Future<bool> setDndFilter(bool enabled);
}
