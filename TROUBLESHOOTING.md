# FocusGuard - Diagnostics & Troubleshooting Guide

This guide covers common operational challenges, edge cases, and automated recovery procedures.

---

## 1. Troubleshooting Matrix

| Problem | Root Cause | Recommended Solution |
| :--- | :--- | :--- |
| **Timer pauses or freezes when screen turns off** | OEM aggressive battery management terminated background service. | Follow [SETUP_CONFIGURATION.md](SETUP_CONFIGURATION.md) to set Battery to "Unrestricted" and enable Auto-start. |
| **Blocked apps are not intercepted** | Usage Access permission was revoked or disabled by OS auto-reset. | Open FocusGuard -> Permissions tab -> tap "Grant Usage Access" to re-authorize. |
| **Block overlay does not appear** | System Alert Window permission is missing. | Open FocusGuard -> Permissions tab -> toggle "Display over other apps". |
| **Phone rebooted during an active session** | Battery died or device was manually restarted. | FocusGuard's `BootCompletedReceiver` restores state automatically. Simply unlock device. |
| **Emergency exit button not responding** | UI thread freeze under heavy system load. | Open phone dialer directly from lock screen or home screen. Emergency dialers bypass all overlays. |
| **Session expired while phone was powered off** | Device was powered off during scheduled end time. | On next boot, the deterministic state machine detects expiration via monotonic delta and cleans up state to `completed`. |
| **Clock Tamper Warning Alert displayed** | System date/time was adjusted manually or NTP time jumped > 3 seconds. | Re-enable automatic network date & time in Android Settings. Monotonic hardware timer continues unaffected. |
| **Database corruption error on startup** | Power loss during uncommitted write transaction. | Database automatically recovers via SQLite WAL journal. If unrecoverable, navigate to Settings -> "Clear All Data". |

---

## 2. Emergency Recovery Key Sequences

If you are in **Locked Mode** and encounter an unexpected situation:

1. **Unblockable Phone Dialer**: Press the hardware power button or swipe to open the emergency dialer on your device lock screen. Dial `911`, `112`, or any emergency contact. FocusGuard will never intercept active phone calls.
2. **Emergency Exit from HUD**: Tap the red **Emergency Exit** button situated on the bottom bar of the Active Session HUD.
3. **Safe Mode Boot**: Power down device completely. Power on while holding the Volume Down key. Third-party apps are disabled, allowing you to uninstall or reconfigure if necessary.

---

## 3. Diagnostic Log Export

To inspect diagnostic logs:
1. Open **Settings** -> tap **"Export Diagnostics"**.
2. FocusGuard outputs a sanitized JSON log file with all PII (emails, PINs) automatically scrubbed.
3. Share the file with the engineering team or inspect locally.
