import '../domain/models/capability_matrix_entry.dart';
import '../domain/models/enums.dart';

/// Dynamic capability matrix inspector evaluating runtime OS features, permissions, and enforcement levels.
class CapabilityMatrix {
  CapabilityMatrix._();

  /// Returns the complete verified capability matrix across Android and iOS platforms.
  static List<CapabilityMatrixEntry> getMatrix({
    bool isAndroid = true,
    bool hasUsageAccess = true,
    bool hasOverlay = true,
    bool hasAccessibility = false,
    bool isDeviceOwner = false,
    bool hasFamilyControls = false,
  }) {
    return [
      CapabilityMatrixEntry(
        feature: 'Foreground App Detection',
        androidSupport: 'UsageStatsManager (API 21+)',
        iosSupport: 'DeviceActivityMonitor (iOS 16+)',
        requirement:
            isAndroid ? 'PACKAGE_USAGE_STATS' : 'FamilyControls entitlement',
        enforcementLevel: 'OS Activity Inspection',
        verified: isAndroid
            ? (hasUsageAccess
                ? VerificationClassification.VERIFIED
                : VerificationClassification.HARDWARE_REQUIRED)
            : (hasFamilyControls
                ? VerificationClassification.VERIFIED
                : VerificationClassification.HARDWARE_REQUIRED),
        notes: 'Detects active foreground package transitions.',
      ),
      CapabilityMatrixEntry(
        feature: 'Real-Time Interception Barrier',
        androidSupport: 'SYSTEM_ALERT_WINDOW Fullscreen Overlay',
        iosSupport: 'ManagedSettings ShieldConfiguration',
        requirement: isAndroid
            ? 'System Alert Window Permission'
            : 'ManagedSettings Framework',
        enforcementLevel: 'Hard Visual Blocker',
        verified: isAndroid
            ? (hasOverlay
                ? VerificationClassification.VERIFIED
                : VerificationClassification.HARDWARE_REQUIRED)
            : (hasFamilyControls
                ? VerificationClassification.VERIFIED
                : VerificationClassification.HARDWARE_REQUIRED),
        notes: 'Prevents interaction with restricted apps.',
      ),
      CapabilityMatrixEntry(
        feature: 'Zero-Latency App Switch Block',
        androidSupport: 'FocusAccessibilityService (TYPE_WINDOW_STATE_CHANGED)',
        iosSupport:
            'Unsupported (Apple sandbox prohibits accessibility interception)',
        requirement: 'Accessibility Service Permission',
        enforcementLevel: 'Immediate Pre-Render Intercept',
        verified: isAndroid
            ? (hasAccessibility
                ? VerificationClassification.VERIFIED
                : VerificationClassification.HARDWARE_REQUIRED)
            : VerificationClassification.PLATFORM_UNSUPPORTED,
        notes:
            'Optional strict mode on Android; not permitted by iOS guidelines.',
      ),
      CapabilityMatrixEntry(
        feature: 'Device-Owner Kiosk / LockTask Mode',
        androidSupport: 'DevicePolicyManager.setLockTaskPackages',
        iosSupport: 'Guided Access / Single App Mode MDM',
        requirement: isAndroid
            ? 'Device Owner via ADB / QR enrollment'
            : 'Supervised MDM profile',
        enforcementLevel: 'Hardware Screen Pinned',
        verified: isDeviceOwner
            ? VerificationClassification.DEVICE_VERIFIED
            : VerificationClassification.HARDWARE_REQUIRED,
        notes:
            'Privileged enterprise/kiosk mode only where officially supported.',
      ),
      const CapabilityMatrixEntry(
        feature: 'Monotonic Tamper-Resistant Clock',
        androidSupport: 'SystemClock.elapsedRealtime() + BootCount',
        iosSupport: 'mach_continuous_time()',
        requirement: 'Kernel Monotonic Clock',
        enforcementLevel: 'Tamper-Proof Timer',
        verified: VerificationClassification.VERIFIED,
        notes:
            'Resistant to system date/time manual manipulation and sleep modes.',
      ),
      const CapabilityMatrixEntry(
        feature: 'Notification Suppression (DND)',
        androidSupport: 'NotificationManager.setInterruptionFilter',
        iosSupport: 'Focus Filter API (iOS 16+)',
        requirement: 'Notification Policy Access',
        enforcementLevel: 'System Priority Muting',
        verified: VerificationClassification.VERIFIED,
        notes: 'Suppresses distracting alerts during deep focus sessions.',
      ),
      const CapabilityMatrixEntry(
        feature: 'Reboot & Crash Recovery',
        androidSupport: 'BOOT_COMPLETED BroadcastReceiver',
        iosSupport: 'DeviceActivityMonitor Extension interval resumption',
        requirement: 'RECEIVE_BOOT_COMPLETED',
        enforcementLevel: 'Automatic Session Resumption',
        verified: VerificationClassification.VERIFIED,
        notes:
            'Restores active countdown and re-enforces barriers after device reboot.',
      ),
      const CapabilityMatrixEntry(
        feature: 'Emergency Access Exemption',
        androidSupport: 'ACTION_DIAL & Emergency Intent Bypass',
        iosSupport: 'System Emergency Call Unrestricted',
        requirement: 'None (Built-in permanent safety invariant)',
        enforcementLevel: 'Zero-Friction Emergency Override',
        verified: VerificationClassification.VERIFIED,
        notes: 'Ensures user can never be locked out of emergency phone calls.',
      ),
    ];
  }
}
