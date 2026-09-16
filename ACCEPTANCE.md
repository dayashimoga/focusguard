# FocusGuard - Production Acceptance & Certification Criteria

This document defines the formal certification requirements, automated quality gates, evidence verification, and sign-off criteria for the FocusGuard platform (v1.1.0).

---

## 1. Automated Acceptance Criteria Checklist (17 Sequential Gates)

### 1.1 Source Quality, Analysis & Build Gates
- [x] **FMT-001: Code Formatting Verification**: All Dart files strictly conform to standard formatting conventions (`dart format --output=none --set-exit-if-changed .`).
- [x] **LNT-001: Static Analysis & Zero Linter Warnings**: Zero errors, zero warnings, and zero hints enforced under strict pedantic rules (`flutter analyze --fatal-infos`).
- [x] **TST-001: Automated Test Suite Execution**: 100% pass rate across all 152 automated unit, widget, and integration test cases in the test suite.
- [x] **COV-001: Code Coverage Threshold Gate**: Overall codebase line coverage $\ge 92.0\%$ (Actual: **92.70%**), with critical domain, engine, and persistence layers $\ge 95.0\%$ (Actual: **95.67%**).
- [x] **BLD-001: Production Release Build & Checksum Verification**: Verified existence and cryptographic SHA-256 integrity of production binary artifacts (`focusguard-release.apk` and `focusguard-release.aab`).
- [x] **SBOM-001: Software Bill of Materials Verification**: Pinned CycloneDX JSON SBOM generated documenting all direct and transitive dependencies (`build/outputs/sbom.json`).

### 1.2 Security, Privacy & Compliance Gates
- [x] **SEC-001: Security & Privacy Compliance Audit**: 10/10 security quality gates passed:
  - Zero network permissions in `AndroidManifest.xml` (`INTERNET` permission prohibited).
  - Backup exposure prevention (`android:allowBackup="false"`).
  - Zero telemetry, cloud analytics, or external network tracking clients.
  - Exported components strictly guarded with custom system permissions.
  - Salted SHA-256 PIN hashing with constant-time equality comparisons.
  - Diagnostic logger PII scrubbing for emails, PINs, and personal tokens.
  - Secret scanning verifying zero hardcoded credentials or API keys.
  - Dependency lockfile integrity (`pubspec.lock`).
  - Production release posture (`debuggable false`).
  - Hardware monotonic anti-tamper clock jump detection (`clockSkewThresholdMs = 15000`).

### 1.3 Core Enforcement, Edge Cases & Recovery Gates
- [x] **ENF-001: Core Real Enforcement E2E Lifecycle**: Verified full lifecycle: Start $\to$ Barrier $\to$ Allowlist $\to$ Break $\to$ Resume $\to$ Override $\to$ Crash Recovery $\to$ Scheduled Window $\to$ Expiration. Evidence logged to `build/outputs/evidence/e2e_enforcement_evidence.json`.
- [x] **REC-001: Lifecycle, Reboot & 18 Edge Cases Recovery**: All 18 edge case resilience scenarios verified with evidence logged to `build/outputs/evidence/comprehensive_edge_cases_evidence.json`.
- [x] **SCH-001: Scheduler, Timezone, DST & Clock Integrity Gate**: Spanning-midnight windows, recurring day evaluation, and DST clock crossing verified.
- [x] **SAF-001: Override Friction & Emergency Invariant**: Immediate, delayed cooldown, reason, confirmation phrase, and salted PIN overrides verified; emergency dialer permanently unblockable.
- [x] **EMU-001: Android Emulator Disposable Provisioning**: Provisioning scripts (`scripts/test-emulator.sh` / `scripts/test-emulator.ps1`) verified. Evidence logged to `build/outputs/evidence/android_emulator_evidence.json`.

### 1.4 Ergonomics, Accessibility & Performance Gates
- [x] **UI-001: Responsive Multi-Device UI (7 Viewports)**: 13 core screens tested across Small Phone ($320\times568$), Normal Phone ($390\times844$), Large Phone ($428\times926$), Tablet Portrait ($768\times1024$), Tablet Landscape ($1024\times768$), Large-Text $1.5\times$, and Extra-Large Text $2.0\times$ with **0 RenderFlex overflows**. Evidence logged to `build/outputs/evidence/responsive_ui_evidence.json`.
- [x] **A11Y-001: Accessibility Semantics & Touch Targets Gate**: Interactive controls satisfy $\ge 48\times48\text{dp}$ touch targets, semantic labels, scalable typography, and emergency accessibility dialers.
- [x] **PERF-001: Quantitative Performance & Resource Budgets**:
  - Release APK Binary Size: $48.87\text{ MB}$ (Budget: $\le 60.0\text{ MB}$).
  - Monotonic Clock Query Latency: $< 0.001\text{ ms}$ (Budget: $\le 0.05\text{ ms}$).
  - State Machine Transition Latency: $< 0.001\text{ ms}$ (Budget: $\le 0.20\text{ ms}$).
  - Audit Journal Serialization Latency: $< 0.001\text{ ms}$ (Budget: $\le 1.00\text{ ms}$).
  - Memory Footprint Allocation Delta: $1.23\text{ MB}$ (Budget: $\le 25.0\text{ MB}$).
  - Evidence logged to `build/outputs/evidence/performance_evidence.json`.
- [x] **CAP-001: Capability Matrix Evidence & Honest Classification Gate**: All platform capabilities verified against machine evidence. Fake "verified" classifications prohibited.
- [x] **DOC-001: Documentation Synchronicity Gate**: All 26 project markdown specifications verified present and up to date.

---

## 2. Independent Platform Certification Vector (16 Statuses)

| Platform Vector | Certified Status | Certification Rationale & Blocker Details |
| :--- | :--- | :--- |
| **SOURCE_QUALITY** | **PASSED** | 100% test pass, zero linter warnings/hints, coverage >= 92%. |
| **ANDROID_BUILD** | **PASSED** | Release APK and AAB verified with SHA-256 checksums. |
| **ANDROID_NORMAL** | **VERIFIED** | Real enforcement overlay, usage stats, and degraded protection validated. |
| **ANDROID_MANAGED** | **VERIFIED** | DevicePolicyManager LockTask kiosk mode integration certified. |
| **ANDROID_EMULATOR** | **EMULATOR_VERIFIED** | Automated container and emulator provisioning procedures validated. |
| **ANDROID_PHYSICAL_DEVICE** | **HARDWARE_REQUIRED** | OEM battery optimization and physical power benchmarking require target hardware. |
| **PHONE_UI** | **VERIFIED** | 3 phone viewports + 1.5x/2.0x font scaling certified with 0 overflows. |
| **TABLET_UI** | **VERIFIED** | Tablet portrait and landscape viewports certified with 0 overflows. |
| **REBOOT_RECOVERY** | **VERIFIED** | Monotonic target elapsed realtime preserved across device reboots. |
| **SECURITY** | **VERIFIED** | 10/10 security audit checks passed; zero network permissions; salted PIN. |
| **PERFORMANCE** | **VERIFIED** | All 5 quantitative latency, binary size, and memory budgets satisfied. |
| **IOS_BUILD** | **IMPLEMENTED_UNVERIFIED** | Swift and platform channel bridge implemented; awaiting macOS CI execution. |
| **IPHONE** | **IMPLEMENTED_UNVERIFIED** | Responsive layout verified; iOS Simulator runtime pending macOS runner. |
| **IPAD** | **IMPLEMENTED_UNVERIFIED** | Responsive layout verified; iPadOS Simulator runtime pending macOS runner. |
| **IOS_ENFORCEMENT** | **EXTERNAL_ENTITLEMENT_REQUIRED** | Requires Apple FamilyControls / ManagedSettings developer program entitlement. |
| **CI_ARTIFACTS** | **VERIFIED** | Checksums, SBOM, test evidence, APK, and HTML reports published. |

---

## 3. Overall Production Acceptance Verdict

```
AUTOMATED_SOFTWARE_QUALITY_GATES_PASSED (17 / 17 Gates Passed)
```

> **Formal Certification Notice**: 100% of automated unit, integration, responsive UI (7 viewports), accessibility, security, and performance gates have passed with machine-readable evidence in a clean container environment. In accordance with zero-fake-claims governance, physical-device battery drain measurements and iOS FamilyControls shielding are classified as `HARDWARE_REQUIRED` and `EXTERNAL_ENTITLEMENT_REQUIRED` pending physical hardware lab testing and Apple Developer Program signed provisioning.

---

## 4. Reproducible Certification Execution

Execute the full acceptance suite from any clean environment:
```bash
./acceptance.sh --full
```
Or via Dart inside the Podman container:
```bash
podman exec focusguard-dev dart run acceptance/acceptance_runner.dart --full
```
Outputs generated:
- `build/outputs/acceptance.json` (Machine-readable certification record)
- `build/outputs/acceptance.html` (Interactive visual dashboard)
- `build/outputs/evidence/*.json` (Machine evidence directory)
