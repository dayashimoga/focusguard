# FocusGuard - OS Permissions & Authorization Architecture

FocusGuard requires specific system-level privileges on Android and iOS to enforce digital wellbeing restrictions, detect app switching, and maintain background timer fidelity.

---

## 1. Android Permissions Breakdown

| Permission Name | Android Manifest Declaration | Functional Rationale | Protection Level | Revocation Handling |
| :--- | :--- | :--- | :--- | :--- |
| **Usage Stats** | `android.permission.PACKAGE_USAGE_STATS` | Detects when a restricted app enters the foreground. | Special Access (App Ops) | Graceful downgrade to timer-only mode; UI prompts user to re-enable. |
| **System Alert Window** | `android.permission.SYSTEM_ALERT_WINDOW` | Displays the focus block overlay on top of restricted apps. | Special Access (Overlay) | App switches to launching the overlay as a full-screen intent activity. |
| **Foreground Service** | `android.permission.FOREGROUND_SERVICE`<br/>`FOREGROUND_SERVICE_SPECIAL_USE` | Keeps the countdown timer active and maintains an ongoing status notification. | Normal (API 34 specialUse) | Service restarts via `START_STICKY` and alarm triggers. |
| **Do Not Disturb** | `android.permission.ACCESS_NOTIFICATION_POLICY` | Mutes non-essential notifications during high-intensity focus sessions. | Special Access (DND) | Soft in-app muting and silence reminders. |
| **Post Notifications** | `android.permission.POST_NOTIFICATIONS` | Displays the active countdown timer and break progress in notification drawer. | Runtime (API 33+) | Timer operates invisibly without notification HUD. |
| **Boot Completed** | `android.permission.RECEIVE_BOOT_COMPLETED` | Restores active sessions and recurring schedule alarms after device reboot. | Normal | Session restored on next manual app launch. |
| **Wake Lock** | `android.permission.WAKE_LOCK` | Prevents CPU sleep from terminating accurate monotonic timer ticks. | Normal | Fallback to periodic alarm wakeups. |
| **Device Admin** | `android.permission.BIND_DEVICE_ADMIN` | Enables kiosk mode and prevents app uninstallation during Locked Mode sessions. | Admin / Device Owner | Locked mode unavailable; downgrades to Strict mode. |
| **Accessibility Service** | `android.permission.BIND_ACCESSIBILITY_SERVICE` | Optional zero-latency window state detection without polling overhead. | Accessibility | Fallback to standard UsageStats polling. |

---

## 2. iOS Entitlements & Authorizations

| Entitlement / API | Apple Framework | Functional Rationale | Authorization Flow |
| :--- | :--- | :--- | :--- |
| **Family Controls** | `FamilyControls` | Core permission granting capability to shield apps and categories. | System authorization prompt via `AuthorizationCenter.shared.requestAuthorization()`. |
| **Device Activity** | `DeviceActivity` | Schedules background monitoring schedules and triggers shield activations. | Tied to Family Controls entitlement. |
| **Managed Settings** | `ManagedSettings` | Applies system-level shields on restricted application bundles. | Automatically authorized once Family Controls is granted. |
| **Local Authentication** | `LocalAuthentication` | Verifies user identity (FaceID / TouchID) for secure override requests. | Biometric system prompt via `LAContext.evaluatePolicy()`. |

---

## 3. Battery Optimization & OEM Killing Workarounds

Aggressive battery management software implemented by OEMs (e.g. Samsung OneUI, Xiaomi MIUI, Huawei EMUI, OnePlus OxygenOS) often terminates background services despite active foreground service notifications.

FocusGuard addresses this via:
1. **`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`**: Requests system battery optimization exclusion.
2. **OEM Setup Guides in [SETUP_CONFIGURATION.md](SETUP_CONFIGURATION.md)**: Clear in-app step-by-step instructions for auto-start, memory lock, and unrestricted background execution on major OEM brands.
3. **Reconciliation on Wake**: If the service is suspended, the engine reconciles elapsed time from `elapsedRealtime()` immediately upon wakeup.
