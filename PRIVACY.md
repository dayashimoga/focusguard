# FocusGuard - Privacy Manifesto & Offline Guarantee

## 1. The 100% Offline Commitment

In an ecosystem where "wellbeing" apps routinely monetize screen time habits by sending granular telemetry to remote ad exchanges and data brokers, **FocusGuard adheres to a strict, uncompromising privacy-first philosophy**:

> **FocusGuard has ZERO network capabilities. It does not phone home, does not collect analytics, does not track user behavior, and does not require an account or internet connection.**

---

## 2. Technical Enforcements of Privacy

### 2.1 Zero Network Permissions
- In Android's manifest (`android/app/src/main/AndroidManifest.xml`), the permission `android.permission.INTERNET` is **completely absent**.
- The Android runtime sandbox physically denies the application socket creation privileges. Even if a third-party dependency attempted an HTTP request, the OS kernel would immediately reject it with an unhandled network access violation.
- Verified automatically by `tool/security_audit.dart` in CI/CD pipelines.

### 2.2 Zero External SDKs
- No Firebase, Google Analytics, Sentry, Datadog, Mixpanel, Segment, or Facebook SDKs are bundled.
- All code dependencies are verified in the Software Bill of Materials ([sbom.json](file:///h:/focus/build/outputs/sbom.json)).

### 2.3 Local-Only SQLite Storage
- All session records, profiles, schedules, daily limits, and audit logs are stored exclusively in an on-device SQLite database (`focusguard.db`).
- Data never leaves the device. Backups are user-initiated and exported locally to user-selected filesystem paths.

### 2.4 Diagnostic Log PII Scrubbing
- All internal debugging and error logs pass through [logger.dart](file:///h:/focus/lib/core/utils/logger.dart).
- Sensitive tokens, email addresses, phone numbers, and PIN codes are sanitized before reaching standard system logging output (`[REDACTED_EMAIL]`, `[REDACTED_PIN]`).

---

## 3. Data Retention & Erasure

- Users have complete, sovereign control over their data.
- The **Settings Screen** provides a **"Clear All Data"** button that atomically drops and reinitializes the database, securely scrubbing all historical usage, profiles, and logs.
- Uninstalling the application completely deletes the sandboxed directory with zero remnants.
