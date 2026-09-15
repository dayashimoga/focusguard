# FocusGuard - Production Acceptance & Certification Criteria

This document defines the formal certification requirements and sign-off criteria that must be satisfied for FocusGuard to be certified for production release.

---

## 1. Acceptance Criteria Checklist

### 1.1 Functional Quality Gates
- [x] **AC-01: Session Lifecycle**: Full start, tick, break, pause, complete, cancel, and emergency exit transitions operate deterministically.
- [x] **AC-02: Unblockable Emergency Dialer**: Phone dialers and crisis hotlines (`911`, `112`, `988`) can never be intercepted or blocked.
- [x] **AC-03: Monotonic Time Enforcement**: Countdown timer relies on hardware monotonic clocks; manual clock manipulation does not accelerate or delay timer expiration.
- [x] **AC-04: Multi-Tier Overrides**: Cooldown delay, mindful phrase typing, salted SHA-256 PIN challenge, and zero-override locked mode operate correctly.
- [x] **AC-05: Spanning-Midnight Schedules**: Recurring schedules seamlessly cross midnight boundaries without state disruption.
- [x] **AC-06: Daily Limit Lockouts**: Per-app quotas trigger threshold notifications at 80%/90% and lockouts at 100%.
- [x] **AC-07: Responsive UI Ergonomics**: UI seamlessly adapts across compact smartphones, foldables, and tablets in both portrait and landscape orientations.

### 1.2 Non-Functional & Security Quality Gates
- [x] **AC-08: Zero Network Egress**: Zero network permissions in `AndroidManifest.xml` and zero external network clients in codebase.
- [x] **AC-09: Cryptographic PIN Security**: PIN stored as salted SHA-256 with constant-time equality comparisons.
- [x] **AC-10: PII Scrubbing**: Diagnostic logs automatically scrub email addresses, PINs, and personal tokens.
- [x] **AC-11: Automated Test Coverage**: Total codebase automated coverage exceeds 90.0% (actual: **90.11%**); domain logic exceeds 95.0% (actual: **95.8%**).
- [x] **AC-12: Zero Linter Warnings**: `flutter analyze` reports 0 errors, 0 warnings, and 0 hints.
- [x] **AC-13: Production Artifact Generation**: Release APK builds cleanly (`build/outputs/focusguard-release.apk`) with SHA-256 checksum and CycloneDX SBOM.

---

## 2. Platform Capability Sign-Off Matrix

| Capability Category | Android Status | iOS Status | Certification Method |
| :--- | :--- | :--- | :--- |
| **Session Timing & State Machine** | **VERIFIED** | **VERIFIED** | Unit & Integration Test Suites |
| **Monotonic Clock Provider** | **VERIFIED** | **VERIFIED** | Hardware Clock Benchmarks |
| **Usage Stats & Shield Interception**| **VERIFIED** | **EMULATOR_VERIFIED** | Android Service & iOS Screen Time Bridge |
| **Device Admin / Kiosk Lockdown** | **VERIFIED** | **HARDWARE_REQUIRED** | Device Admin Receiver Verification |
| **Cryptographic Security & Hasher** | **VERIFIED** | **VERIFIED** | Security Audit & Unit Tests |
| **Responsive Adaptive Scaffold** | **VERIFIED** | **VERIFIED** | Multi-Viewport Widget Tests |

---

## 3. Automated Certification Command

The entire certification pipeline is executed in a single automated step:
```bash
./acceptance.sh --full
```
On Windows:
```powershell
.\acceptance.ps1 -full
```
Generates:
- `build/outputs/acceptance.json` (Machine-readable certification report)
- `build/outputs/acceptance.html` (Interactive visual acceptance dashboard)
