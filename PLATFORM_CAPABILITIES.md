# FocusGuard - Platform Capabilities & OS Matrix

FocusGuard bridges high-level digital wellbeing policies to low-level operating system APIs across both **Android** and **iOS**. Because mobile operating systems enforce vastly different security and background execution models, this document provides an authoritative breakdown of capabilities, exact OS APIs, behavioral limitations, and graceful fallback paths.

---

## 1. 4-Tier Capability Classification

Every capability in FocusGuard is classified into one of four deterministic states:

1. **`VERIFIED`**: Fully supported and verified directly in standard runtime / test suites without specialized OEM privileges.
2. **`EMULATOR_VERIFIED`**: Validated in Android AVD or iOS Simulator environments with simulated platform channels.
3. **`HARDWARE_REQUIRED`**: Requires physical mobile hardware (e.g. physical biometric sensors, cellular emergency dialer hardware, physical power management chips).
4. **`PLATFORM_UNSUPPORTED`**: Intentionally not supported or architecturally impossible on that specific operating system due to vendor sandbox constraints (e.g. dynamic app killing on iOS).

---

## 2. Platform Capability Matrix

| Capability ID | Feature Description | Android API & Mechanism | iOS API & Mechanism | Android Classification | iOS Classification | Graceful Fallback Strategy |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **CAP-01** | Foreground Service & Ongoing Notification | `android.app.NotificationManager`<br/>`startForegroundService()` with `specialUse` | `UNUserNotificationCenter`<br/>Live Activities (ActivityKit) | **VERIFIED** | **VERIFIED** | Standard priority push notification if background task expires. |
| **CAP-02** | Usage Statistics Tracking | `android.app.usage.UsageStatsManager`<br/>`queryEvents(startTime, endTime)` | `DeviceActivityReport`<br/>`DeviceActivityData` | **VERIFIED** | **EMULATOR_VERIFIED** | Polling foreground task queue at 500ms intervals. |
| **CAP-03** | Full-Screen Interception Overlay | `android.view.WindowManager.LayoutParams`<br/>`TYPE_APPLICATION_OVERLAY` | Shield Configuration Extension (`ManagedSettingsUI`) | **VERIFIED** | **EMULATOR_VERIFIED** | Native banner prompt and immediate app suspension. |
| **CAP-04** | Monotonic Hardware Clock | `android.os.SystemClock.elapsedRealtime()` | `mach_absolute_time()` / `CLOCK_MONOTONIC_RAW` | **VERIFIED** | **VERIFIED** | Dart `Stopwatch` monotonic elapsed tracker. |
| **CAP-05** | Unblockable Emergency Dialer | `Intent.ACTION_DIAL`<br/>Whitelisted package `com.android.dialer` | `UIApplication.open(tel:)` URL scheme | **VERIFIED** | **VERIFIED** | Direct unblockable OS dialer invocation; bypasses all overlays. |
| **CAP-06** | Do Not Disturb (DND) Policy Suppression | `android.app.NotificationManager`<br/>`setInterruptionFilter(PRIORITY)` | Focus Filters (`FocusSettingsExtension`) | **VERIFIED** | **EMULATOR_VERIFIED** | In-app audio muting and vibration suppression. |
| **CAP-07** | Device Admin / Kiosk Lockdown | `android.app.admin.DevicePolicyManager`<br/>`setLockTaskPackages()` | Guided Access / MDM Single App Mode | **VERIFIED** | **HARDWARE_REQUIRED** | Strict overlay loop intercepting Home & Recents presses. |
| **CAP-08** | Accessibility Interception (Zero Latency) | `android.accessibilityservice.AccessibilityService`<br/>`TYPE_WINDOW_STATE_CHANGED` | N/A (Apple Sandbox strictly prohibits accessibility interception) | **VERIFIED** | **PLATFORM_UNSUPPORTED** | iOS delegates entirely to `FamilyControls` and `ManagedSettings`. |
| **CAP-09** | Boot Recovery | `android.content.BroadcastReceiver`<br/>`ACTION_BOOT_COMPLETED` | Silent Push / `BackgroundTasks` framework | **VERIFIED** | **HARDWARE_REQUIRED** | Session state recovery upon next app launch from SQLite. |
| **CAP-10** | Clock Tamper Detection | Delta calculation between `elapsedRealtime()` and wall-clock | Delta calculation between `mach_absolute_time()` and `Date()` | **VERIFIED** | **VERIFIED** | Automatic session invalidation or freeze if delta > 3000ms. |
| **CAP-11** | Local Biometric Verification | `androidx.biometric.BiometricPrompt` | `LocalAuthentication` (`LAContext`) | **HARDWARE_REQUIRED** | **HARDWARE_REQUIRED** | Cryptographic Salted SHA-256 PIN challenge fallback. |
| **CAP-12** | App Package Enumeration | `android.content.pm.PackageManager`<br/>`getInstalledApplications()` | Pre-bundled category tokens via `FamilyActivityPicker` | **VERIFIED** | **EMULATOR_VERIFIED** | Category-based heuristic selection on iOS. |

---

## 3. Platform Architectural Divergences

### Android Implementation Details
- Android permits active monitoring of running tasks using `UsageStatsManager` and displaying custom system alert windows using `TYPE_APPLICATION_OVERLAY`.
- In extreme lockdown, FocusGuard activates `DevicePolicyManager` with `setLockTaskPackages()`, anchoring the device to the FocusGuard HUD until the session completes.

### iOS Implementation Details
- Apple enforces strict app sandboxing. Third-party apps cannot draw overlays over other apps or inspect background process tables.
- FocusGuard interfaces with Apple's **Screen Time API suite** introduced in iOS 15/16:
  - **`FamilyControls`**: Requests authorization to shield apps and categories.
  - **`ManagedSettings`**: Shields selected applications using system-level shields.
  - **`ManagedSettingsUI`**: Customizes the shield display with FocusGuard branding and countdown timers.
  - **`DeviceActivity`**: Schedules background monitors and triggers automated shield engagement.
