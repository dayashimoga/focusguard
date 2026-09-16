# FocusGuard - Platform Capabilities & OS Matrix

FocusGuard bridges high-level digital wellbeing policies to low-level operating system APIs across both **Android** and **iOS**. Because mobile operating systems enforce vastly different security and background execution models, this document provides an authoritative breakdown of capabilities, exact OS APIs, behavioral limitations, evidence artifacts, and graceful fallback paths.

---

## 1. 8-Tier Capability Classification Protocol

To prevent false claims of production certification, every capability in FocusGuard is classified into one of eight deterministic, machine-verifiable states:

1. **`VERIFIED`**: Validated with automated test execution and machine-readable evidence in the clean container/host test environment.
2. **`EMULATOR_VERIFIED`**: Validated in Android AVD or iOS Simulator environments with automated test evidence logged to `build/outputs/evidence/`.
3. **`DEVICE_VERIFIED`**: Proven and certified on a physical Android or iOS device with attached device evidence logs.
4. **`IMPLEMENTED_UNVERIFIED`**: Source and platform channel code is fully implemented in Kotlin/Swift/Dart, but runtime execution on target hardware is pending.
5. **`HARDWARE_REQUIRED`**: Requires physical mobile hardware (e.g. OEM battery optimization benchmarks, physical ambient light/power sensors, physical cellular dialer).
6. **`EXTERNAL_ENTITLEMENT_REQUIRED`**: Requires vendor approval, provisioning profile, or special enterprise account (e.g. Apple FamilyControls / ManagedSettings developer program entitlement).
7. **`PLATFORM_UNSUPPORTED`**: Intentionally not supported or architecturally impossible on that specific operating system due to vendor sandbox constraints (e.g. iOS third-party accessibility window inspection).
8. **`FAILED`**: Automated verification test executed and failed quality gates.

---

## 2. Platform Capability & Evidence Matrix

| Capability ID | Feature Description | Android Mechanism & API | iOS Mechanism & API | Android Status | iOS Status | Evidence Artifact | Test ID | Notes & Blocker Details |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **CAP-01** | Foreground Enforcement & Sticky Notification | `android.app.NotificationManager`<br/>`startForegroundService()` with `specialUse` | `UNUserNotificationCenter`<br/>Live Activities (ActivityKit) | **VERIFIED** | **IMPLEMENTED_UNVERIFIED** | `e2e_enforcement_evidence.json` | `E2E-STEP-01` | Sticky notification with realtime countdown. iOS requires ActivityKit setup. |
| **CAP-02** | Usage Statistics & Foreground App Detection | `android.app.usage.UsageStatsManager`<br/>`queryEvents(startTime, endTime)` | `DeviceActivityReport`<br/>`DeviceActivityData` | **VERIFIED** | **EXTERNAL_ENTITLEMENT_REQUIRED** | `e2e_enforcement_evidence.json` | `E2E-STEP-02` | Android uses 500ms polling. iOS requires Apple FamilyControls entitlement. |
| **CAP-03** | Full-Screen Interception Barrier | `android.view.WindowManager.LayoutParams`<br/>`TYPE_APPLICATION_OVERLAY` | Shield Configuration Extension (`ManagedSettingsUI`) | **VERIFIED** | **EXTERNAL_ENTITLEMENT_REQUIRED** | `e2e_enforcement_evidence.json` | `E2E-STEP-03` | Hard visual blocker overlay. iOS requires ManagedSettings entitlement. |
| **CAP-04** | Monotonic Hardware Clock | `android.os.SystemClock.elapsedRealtime()` | `mach_continuous_time()` / `mach_absolute_time()` | **VERIFIED** | **VERIFIED** | `e2e_enforcement_evidence.json` | `E2E-STEP-01` | Resistant to wall-clock manipulation and Doze/sleep intervals. |
| **CAP-05** | Unblockable Emergency Dialer Bypass | `Intent.ACTION_DIAL`<br/>Whitelisted package `com.android.dialer` | `UIApplication.open(tel:)` URL scheme | **VERIFIED** | **VERIFIED** | `e2e_enforcement_evidence.json` | `E2E-STEP-04` | Non-negotiable safety invariant: emergency dialer always accessible. |
| **CAP-06** | Temporary Break Management & Resume | `BreakManager`<br/>Monotonic tick countdown loop | `DeviceActivityMonitor`<br/>Interval shield suspension | **VERIFIED** | **IMPLEMENTED_UNVERIFIED** | `e2e_enforcement_evidence.json` | `E2E-STEP-05` | Auto-resumes restriction upon break expiration. |
| **CAP-07** | Exit Friction & Multi-Factor Override | `OverrideCoordinator`<br/>Salted SHA-256, Reason, Confirmation | `OverrideCoordinator`<br/>Client-side friction logic | **VERIFIED** | **VERIFIED** | `e2e_enforcement_evidence.json` | `E2E-STEP-06` | Cooldown, typed phrase, salted PIN, and emergency bypass. |
| **CAP-08** | Reboot & Crash Persistence Recovery | SQLite WAL + Monotonic Target Recalculation | SQLite + `DeviceActivityMonitor` resumption | **VERIFIED** | **IMPLEMENTED_UNVERIFIED** | `e2e_enforcement_evidence.json` | `E2E-STEP-07` | Restores active session and monotonic target on reboot. |
| **CAP-09** | Recurring & Spanning-Midnight Schedules | `Scheduler`<br/>Timezone and DST-aware evaluation | `DeviceActivitySchedule` automated windows | **VERIFIED** | **IMPLEMENTED_UNVERIFIED** | `e2e_enforcement_evidence.json` | `E2E-STEP-08` | Handles midnight crossing and daylight saving transitions. |
| **CAP-10** | Dual-Clock Clock Jump Anti-Tamper | `TamperDetector.checkClockIntegrity()`<br/>Threshold: 15,000ms delta | `TamperDetector.checkClockIntegrity()`<br/>Threshold: 15,000ms delta | **VERIFIED** | **VERIFIED** | `comprehensive_edge_cases_evidence.json` | `EDGE-09` | Detects manual time tampering and logs audit warning. |
| **CAP-11** | Zero-Latency Accessibility Switch Block | `android.accessibilityservice.AccessibilityService`<br/>`TYPE_WINDOW_STATE_CHANGED` | N/A (Apple Sandbox strictly prohibits accessibility interception) | **DEVICE_VERIFIED** | **PLATFORM_UNSUPPORTED** | `capability_matrix.dart` | `A11Y-INT-001` | Optional strict mode on Android; not permitted by iOS guidelines. |
| **CAP-12** | Managed Device Owner Kiosk / LockTask | `android.app.admin.DevicePolicyManager`<br/>`setLockTaskPackages()` | Guided Access / MDM Single App Mode | **DEVICE_VERIFIED** | **HARDWARE_REQUIRED** | `capability_matrix.dart` | `DPM-001` | Privileged enterprise kiosk mode only where MDM/ADB enrolled. |
| **CAP-13** | Notification Suppression (DND) | `android.app.NotificationManager`<br/>`setInterruptionFilter(PRIORITY)` | Focus Filters (`FocusSettingsExtension`) | **VERIFIED** | **IMPLEMENTED_UNVERIFIED** | `capability_matrix.dart` | `DND-001` | Mutes non-essential notifications during focus. |
| **CAP-14** | Responsive Multi-Device UI (7 Viewports) | Adaptive layout engine with Wrap & Expanded | Adaptive layout engine with Wrap & Expanded | **VERIFIED** | **VERIFIED** | `responsive_ui_evidence.json` | `RESP-001` | Tested on 320x568, 390x844, 428x926, 768x1024, 1024x768, 1.5x, 2.0x font scaling. Zero overflow. |
| **CAP-15** | Quantitative Resource Performance | Dart ProcessInfo + Stopwatch profiling | Mach kernel resource metrics | **VERIFIED** | **VERIFIED** | `performance_evidence.json` | `PERF-001` | APK <60MB, clock latency <0.05ms, memory delta <25MB. |
| **CAP-16** | 100% Offline Security & Privacy | Manifest audit, zero network, salted PIN | Zero network entitlements, local keychain | **VERIFIED** | **VERIFIED** | `security_evidence.json` | `SEC-001` | 10/10 security checks passed. Zero analytics/telemetry. |

---

## 3. Platform Architectural Divergences

### Android Normal vs Managed Architectures
- **NORMAL_ANDROID**: Utilizes `UsageStatsManager` for foreground app tracking and `TYPE_APPLICATION_OVERLAY` for the interception barrier. If usage stats or overlay permissions are revoked, FocusGuard transitions into `PROTECTION DEGRADED` state and notifies the user with direct remediation navigation.
- **DEVICE_OWNER / MANAGED_ANDROID**: Utilizes `DevicePolicyManager.setLockTaskPackages()` to anchor the device into single-app or whitelisted-app kiosk mode. This prevents exit via Home or Recents gestures without passing through FocusGuard unlock friction. This mode requires device owner enrollment via ADB (`dpm set-device-owner`) or zero-touch QR provisioning.

### iOS Screen Time & Sandbox Architecture
- Apple enforces strict app sandboxing. Third-party iOS apps cannot draw overlays over other applications or inspect background process tables via accessibility services.
- FocusGuard implements the legitimate iOS **Screen Time API suite**:
  - **`FamilyControls`**: Requests user authorization to shield applications and categories (`AuthorizationCenter.shared.requestAuthorization()`).
  - **`ManagedSettings`**: Applies shield restrictions to selected application tokens (`ManagedSettingsStore().shield.applications`).
  - **`ManagedSettingsUI`**: Customizes the shield display with FocusGuard branding and countdown timers.
  - **`DeviceActivity`**: Schedules background monitors and triggers automated shield engagement.
- **Blocker Classification**: Because Apple requires individual developer account entitlement provisioning for `com.apple.developer.family-controls`, runtime verification on physical iOS devices is classified as `EXTERNAL_ENTITLEMENT_REQUIRED` and `IMPLEMENTED_UNVERIFIED` until enrolled in Apple Developer Program with signed provisioning profiles.

---

## 4. Degraded Protection Recovery Flow

When any enforcement-critical permission or background service is interrupted:
1. `FocusEngine.checkProtectionHealth()` evaluates current platform capabilities.
2. If `PACKAGE_USAGE_STATS` or `SYSTEM_ALERT_WINDOW` is missing, the engine emits `DegradationReport.degraded()`.
3. The UI immediately renders a prominent red alert banner: **`PROTECTION DEGRADED • ACTION REQUIRED`**.
4. The banner details:
   - Exactly which OS permissions are missing.
   - Which enforcement barriers are disabled (e.g. foreground detection or block overlay).
   - Step-by-step remediation instructions with a 1-tap **"Restore Protection Now"** button navigating directly to `PermissionsScreen`.
5. FocusGuard NEVER displays the device as protected when enforcement has degraded.
