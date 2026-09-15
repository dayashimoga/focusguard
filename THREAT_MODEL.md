# FocusGuard - STRIDE Threat Model

This document outlines the threat modeling analysis for FocusGuard following the **STRIDE** methodology (Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege).

---

## 1. System Scope & Assets

### Target Assets:
1. **Focus Session State**: Integrity of the countdown timer and restriction enforcement.
2. **Override Secrets**: Confidentiality of the user-defined PIN and override settings.
3. **Audit Journal**: Tamper-evident record of user sessions, breaks, and overrides.
4. **Emergency Calling Capability**: Availability of phone dialer and emergency dispatch.
5. **Private Usage Statistics**: Confidentiality of per-app screen time and habit data.

---

## 2. STRIDE Threat Analysis Matrix

| Threat Category | Threat Description | Attack Vector | Impact | Mitigation Strategy | Residual Risk |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Spoofing** | Impersonation of user during override challenge | Brute-forcing 4-8 digit override PIN | High | Salted SHA-256 with exponential backoff delays and constant-time string verification. | Attacker with physical possession can attempt guesses before backoff locks. |
| **Tampering** | Time manipulation to expire session prematurely | Advancing OS clock in device date/time settings | High | Hardware monotonic clock (`elapsedRealtime()`) and automated `TamperDetector` flagging delta deviations >3s. | Device reboot resets `elapsedRealtime`; mitigated by SQLite elapsed delta checkpointing. |
| **Tampering** | Direct SQLite database modification | Editing `focusguard.db` using external SQLite editor on rooted devices | High | Database stored in private sandbox (`0600`). In locked mode, Device Admin / Knox blocks USB debugging. | Rooted devices with physical access can alter local DB files. |
| **Repudiation** | Denying an emergency exit or session cancellation | Clearing local application cache or rolling back state | Medium | Cryptographic SHA-256 state chain in append-only SQLite `audit_logs` table. | Root user wipe of app data partition. |
| **Information Disclosure** | Leakage of sensitive package names or usage data | Inspecting system logcat or diagnostic logs | Low | Diagnostic logger (`AppLogger`) implements mandatory regex PII scrubbing for emails, PINs, and identifiers. | None. Zero network egress guarantees no remote leakage. |
| **Denial of Service** | App killed by OS memory pressure or OEM battery killers | Aggressive OEM background killer (Samsung, Xiaomi MIUI) terminates Foreground Service | High | Sticky foreground service (`START_STICKY`) with ongoing notification, wake lock, and boot receiver restart. | User manually force-stops app from OS Settings if not in Device Admin mode. |
| **Denial of Service** | Emergency dialer blocked during active session | Interception overlay improperly captures dialer window | Critical | Hardcoded unblockable package whitelist and dialer intent filter. | None. Dialer takes absolute precedence. |
| **Elevation of Privilege** | Revoking accessibility or device admin privileges during lock | Navigating to OS Settings -> Security -> Device Admin | High | FocusGuard monitors top-level package name; if OS Settings is opened during Locked mode, it is intercepted. | Safe Mode boot disables 3rd-party services on standard Android. |

---

## 3. Physical & OS-Level Edge Cases

### 3.1 Reboot into Safe Mode
- **Threat**: User powers down device, holds Volume Down, and boots into Android Safe Mode, disabling all third-party services.
- **Mitigation**: On standard consumer devices, Safe Mode cannot be blocked without Device Owner (MDM) status. Upon rebooting back to Normal Mode, `BootCompletedReceiver` activates, reconciles monotonic time, and immediately re-engages restrictions.
- **Corporate / Kiosk Mode**: When provisioned via `dpm set-device-owner`, Safe Mode boot is disabled via `DISALLOW_SAFE_BOOT`.

### 3.2 Battery Optimization & Doze Mode
- **Threat**: Android Doze mode suspends the timer task.
- **Mitigation**: The app requests `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` and runs a high-priority Foreground Service with an ongoing notification.
