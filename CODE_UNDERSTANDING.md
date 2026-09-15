# FocusGuard - Codebase Walkthrough & Engineering Guide

This document is designed to accelerate onboarding for new software engineers and architects joining the FocusGuard team.

---

## 1. High-Level Code Map

```
lib/
├── core/
│   ├── security/
│   │   ├── pin_hasher.dart          # Cryptographic Salted SHA-256 + constant-time comparison
│   │   └── tamper_detector.dart     # Compares wall-clock delta vs monotonic hardware delta
│   ├── theme/
│   │   └── app_theme.dart           # Dark OLED-optimized design tokens & typography
│   └── utils/
│       ├── logger.dart              # PII-sanitized logging utility
│       └── monotonic_time.dart      # Stopwatch-backed continuous monotonic clock provider
├── domain/
│   ├── models/
│   │   ├── focus_session.dart       # Core session entity with remainingSeconds & state
│   │   ├── focus_profile.dart       # Reusable profile entity (Work, Study, Sleep)
│   │   ├── focus_schedule.dart      # Recurring weekly schedule with overnight spanning
│   │   ├── app_info.dart            # Package info model with system app flags
│   │   ├── override_policy.dart     # Override configuration (delay, phrase, PIN)
│   │   ├── daily_limit.dart         # Daily per-app limit quotas
│   │   ├── audit_entry.dart         # Tamper-evident audit journal entry
│   │   ├── capability_matrix_entry.dart # 4-tier capability model
│   │   └── enums.dart               # SessionState, RestrictionLevel, OverrideType enums
│   └── state_machine/
│       └── session_state_machine.dart # Pure deterministic finite state machine (DFA)
├── engine/
│   ├── monotonic_timer.dart         # Monotonic countdown timer with 1Hz ticker
│   ├── focus_engine.dart            # Central business orchestration coordinator
│   ├── break_manager.dart           # Break quotas, active break countdown, daily reset
│   ├── override_coordinator.dart    # Friction delay, mindful phrase, and PIN challenge logic
│   ├── scheduler.dart               # Evaluates active schedules and overnight transitions
│   └── daily_limit_tracker.dart     # Tracks app minutes and enforces daily lockouts
├── persistence/
│   ├── database_helper.dart         # SQLite singleton with schema migrations & WAL
│   ├── session_repository.dart      # CRUD operations for sessions
│   ├── profile_repository.dart      # CRUD operations for profiles
│   ├── schedule_repository.dart     # CRUD operations for recurring schedules
│   ├── audit_repository.dart        # Append-only audit logging repository
│   └── settings_repository.dart     # Key-value persistent preferences
├── platform/
│   ├── platform_bridge.dart         # Flutter MethodChannel dispatcher to Android/iOS
│   └── capability_matrix_service.dart # Queries runtime OS capability classifications
└── presentation/
    ├── screens/                     # 13 responsive screens
    └── widgets/
        ├── adaptive_scaffold.dart   # Phone vs Tablet responsive navigation layout
        └── circular_timer_ring.dart # Smooth animated circular countdown canvas painter
```

---

## 2. Key Architecture Patterns

### 2.1 State Management (Decoupled Provider Architecture)
The user interface never talks to databases or platform channels directly. The presentation layer binds to `FocusEngine` via ChangeNotifier/Provider.
- UI triggers intentions: `focusEngine.startSession(...)`, `focusEngine.takeBreak()`, `focusEngine.emergencyExit()`.
- Engine validates business invariants, mutates the state machine, updates SQLite, dispatches platform bridge calls, and notifies listeners.

### 2.2 Deterministic State Machine Mechanics
In [session_state_machine.dart](file:///h:/focus/lib/domain/state_machine/session_state_machine.dart):
- States: `idle`, `starting`, `active`, `inBreak`, `paused`, `completed`, `cancelled`, `emergencyExited`.
- `canTransitionTo(target)` validates legal transitions.
- `transitionTo(target)` enforces valid state transitions and fires state change callbacks.
- `forceState(target)` is used exclusively during crash recovery reconciliation to restore session status after unexpected reboots.

### 2.3 SQLite Migrations
In [database_helper.dart](file:///h:/focus/lib/persistence/database_helper.dart):
- Schema versioning is handled via `onUpgrade(db, oldVersion, newVersion)`.
- All table operations run in WAL mode (`PRAGMA journal_mode = WAL;`) for high concurrency and zero UI blocking.
