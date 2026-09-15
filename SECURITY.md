# FocusGuard - Security Architecture & Specifications

## 1. Security Philosophy & Principles

FocusGuard is built on a **Zero-Trust, Zero-Egress, Defense-in-Depth** security model:

1. **Zero Network Egress**: The application does not request `android.permission.INTERNET` or iOS network entitlements. Network transmission of user data is physically prevented by the OS sandbox.
2. **Cryptographic Protection for Access Overrides**: All PINs are hashed using salted SHA-256 with constant-time equality comparisons to mitigate timing side-channel attacks.
3. **Monotonic Integrity**: Timers use hardware monotonic clocks, actively detecting and mitigating wall-clock rollbacks and NTP time-travel tampering.
4. **Guaranteed Emergency Dialer Access**: Human safety precedes digital restriction. Dialer packages and emergency calls are hardcoded as unblockable across all enforcement mechanisms.
5. **Tamper-Evident Audit Logging**: System security and state transitions are immutably logged to an SQLite audit log with SHA-256 state hashes.

---

## 2. Cryptographic Architecture

### 2.1 PIN Storage & Verification
The user can optionally configure a 4 to 8-digit override PIN. Plaintext PINs are never stored in memory or disk.

* Implementation: [pin_hasher.dart](file:///h:/focus/lib/core/security/pin_hasher.dart)
* Algorithm: Salted SHA-256 (PBKDF2-equivalent salt derivation)
* Salt Generation: 32 cryptographically secure random bytes generated via `Random.secure()`:
  $$\text{Hash} = \text{SHA-256}(\text{Salt} \mathbin{\Vert} \text{PIN})$$
* Storage Format: `salt_hex:hash_hex`
* Timing Attack Mitigation: Comparison is performed using bitwise XOR accumulation over the entire digest length ($O(1)$ constant time) rather than string equality:

```dart
static bool constantTimeEquals(String a, String b) {
  if (a.length != b.length) return false;
  int result = 0;
  for (int i = 0; i < a.length; i++) {
    result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return result == 0;
}
```

---

## 3. Monotonic Clock & Tamper Detection

Users often attempt to bypass restriction apps by manually advancing or rolling back the system clock in Android/iOS Settings. FocusGuard defeats this attack vector via a dual-clock architecture:

* **Hardware Monotonic Clock**: FocusGuard queries `android.os.SystemClock.elapsedRealtime()` on Android and `mach_absolute_time()` on iOS. This clock counts continuous milliseconds since hardware boot, including CPU deep sleep states, and cannot be changed by the user or network time updates.
* **Tamper Detector ([tamper_detector.dart](file:///h:/focus/lib/core/security/tamper_detector.dart))**: On every timer tick, the engine compares the delta of system time ($\Delta T_{\text{system}}$) with the delta of monotonic time ($\Delta T_{\text{monotonic}}$):
  $$|\Delta T_{\text{system}} - \Delta T_{\text{monotonic}}| > 3000\,\text{ms} \implies \text{Tamper Alert}$$
* **Mitigation**: When a clock jump is detected, the engine freezes the session or recalculates remaining time solely from the monotonic hardware delta, preventing time-warp bypasses.

---

## 4. Emergency Dialer Protection

Human safety is an absolute constraint. The enforcement mechanisms in FocusGuard (`FocusBlockOverlayActivity`, `FocusEnforcementService`, and `FocusAccessibilityService`) explicitly bypass:

- `com.android.dialer`
- `com.android.server.telecom`
- `com.google.android.dialer`
- `com.samsung.android.dialer`
- All intents matching `Intent.ACTION_DIAL`, `Intent.ACTION_CALL_PRIVILEGED`, or `tel:` URI schemes.
- Emergency numbers: `911`, `112`, `999`, `000`, `988` (Suicide & Crisis Lifeline).

---

## 5. Storage Security & Encryption

- **Database**: SQLite database `focusguard.db` resides inside the app's sandboxed private storage directory (`/data/user/0/com.focusguard.app/databases/` on Android; `~/Library/Application Support/` on iOS).
- **Permissions**: Database files are created with mode `0600` (read/write only by the application UID).
- **Diagnostics**: All logged diagnostic output runs through [logger.dart](file:///h:/focus/lib/core/utils/logger.dart) with regex PII scrubbing for emails, PINs, and personal tokens.
