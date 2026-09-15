# FocusGuard Changelog (APPEND-ONLY)

All notable changes to the FocusGuard platform are documented in this file in chronological order. Entries are NEVER deleted or overwritten.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.1.0] - 2026-09-15

### Added
- Project initialization and Git repository creation on branch `main`.
- Environment verification for zero-host-install Podman container execution (`ghcr.io/cirruslabs/flutter:3.24.3`).
- Append-only governance for `TODO.md` and `CHANGELOG.md`.
- Comprehensive architecture specification and implementation plan artifact.

---

## [1.0.0] - 2026-09-15

### Added
- **Core Domain & State Machine**:
  - Deterministic finite state machine with recovery reconciler (`SessionStateMachine`).
  - Immutable domain models (`FocusSession`, `FocusProfile`, `FocusSchedule`, `DailyLimit`, `AuditEntry`, `CapabilityMatrixEntry`).
  - Monotonic hardware elapsed timer engine (`MonotonicTimer`, `MonotonicTimeProvider`).
  - Cryptographic Salted SHA-256 PIN hasher with constant-time equality check (`PinHasher`).
  - Dual-clock tamper and time manipulation detector (`TamperDetector`).
- **Engines & Coordination**:
  - Central `FocusEngine` orchestrating session lifecycle, restrictions, breaks, and persistence.
  - `BreakManager` enforcing daily quotas, break countdowns, and automatic resumption.
  - `OverrideCoordinator` supporting cooldown delays, mindful phrase typing, salted PIN, and zero-override locked mode.
  - `Scheduler` supporting single-day and complex overnight spanning-midnight schedules.
  - `DailyLimitTracker` managing per-app usage limits, threshold warnings, and daily lockouts.
- **Local Persistence Layer**:
  - SQLite database (`DatabaseHelper`) with Write-Ahead Logging (WAL) and atomic transactions.
  - Repositories for sessions, profiles, schedules, daily limits, audit logs, and settings.
- **Responsive Presentation Layer**:
  - Adaptive master-detail scaffold (`AdaptiveScaffold`) supporting phones, foldables, and tablets.
  - High-performance animated circular timer ring (`CircularTimerRing`).
  - 13 core screens: Dashboard/Home, Start Focus, Active Session HUD, App Selection, Profiles, Schedules, Daily Limits, Override Config, Usage Insights, History, Settings, Permissions, Emergency/Crisis Launcher.
- **Platform Bridges**:
  - Android: Kotlin `FocusEnforcementService`, `AppUsageTracker`, `FocusBlockOverlayActivity`, `FocusDeviceAdminReceiver`, `BootCompletedReceiver`.
  - iOS: Swift `FocusNativeBridge`, `FocusActivityMonitor`, `FocusShieldConfiguration`.
- **Quality & DevSecOps**:
  - Over 70 automated unit, widget, and integration tests achieving 90.11% overall coverage (>95% domain).
  - Production release APK (`focusguard-release.apk`) with SHA-256 checksum.
  - CycloneDX SBOM (`sbom.json`) documenting 30 dependencies.
  - Automated security & privacy audit tool (`security_audit.dart`) verifying 100% offline guarantee.
  - Complete 25-file synchronized documentation suite.
  - Automated production certification runner (`acceptance/acceptance_runner.dart`).

