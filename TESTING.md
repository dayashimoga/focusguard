# FocusGuard - Testing Strategy & Quality Assurance

FocusGuard adheres to rigorous software engineering and quality assurance standards. Digital wellbeing enforcement requires zero-defect reliability; failing to exit a session or blocking an emergency call is critical.

---

## 1. Test Pyramid Architecture

```
          / \
         /   \     Integration Tests (10%)
        /     \    - End-to-end focus session lifecycles
       /-------\   - Database migrations & repository integration
      /         \  Widget & UI Ergonomics Tests (30%)
     /           \ - 13 responsive screens, timer ring custom painters
    /-------------\- Master-detail adaptive layouts (phones vs tablets)
   /               \ Unit Tests & Domain Property Verification (60%)
  /                 \- State machine transitions, monotonic timers, break budgets
 /                   \- Cryptographic PIN hashing, tamper detectors, overnight schedules
---------------------
```

---

## 2. Test Suites Overview

FocusGuard includes over 70 automated tests organized into targeted suites:

1. **`test/domain/session_state_machine_test.dart`**:
   - Validates all valid forward transitions (`idle -> starting -> active -> completed`, etc.).
   - Validates illegal transition rejection (e.g. `idle -> completed`, `active -> starting`).
   - Validates emergency exit reachability from every non-terminal state.
   - Validates terminal state permanence (`completed`, `cancelled`, `emergencyExited`).
   - Validates crash recovery state reconciliation.
2. **`test/domain/models_test.dart`**:
   - Tests immutability and `copyWith` behavior for all models (`FocusSession`, `FocusProfile`, `FocusSchedule`, `DailyLimit`, `AuditEntry`).
   - Tests JSON serialization and deserialization round-tripping.
3. **`test/engine/monotonic_timer_test.dart`**:
   - Verifies monotonic elapsed time progression.
   - Tests timer pause, resume, reset, and completion callbacks.
4. **`test/engine/focus_engine_test.dart`**:
   - End-to-end coordinator testing: starting sessions, taking breaks, managing overrides, emergency exit execution.
5. **`test/engine/break_manager_test.dart`**:
   - Quota enforcement, break countdowns, break expiration, and daily quota reset.
6. **`test/engine/override_coordinator_test.dart`**:
   - Evaluates all 4 override policies (Instant, Cooldown Delay, Mindful Phrase, Salted PIN).
   - Tests friction delays, phrase verification, and PIN backoff timers.
7. **`test/engine/scheduler_test.dart`**:
   - Evaluates regular single-day recurring schedules.
   - Evaluates complex spanning-midnight overnight schedules (e.g. 22:00 to 06:00) across calendar day transitions.
8. **`test/engine/daily_limit_tracker_test.dart`**:
   - Per-app usage tracking, 80%/90% threshold triggers, and limit exhaustion lockouts.
9. **`test/core/security_test.dart`**:
   - Salted SHA-256 PIN hashing, random salt generation, timing-safe constant-time comparison.
   - Clock tamper detection for positive and negative wall-clock jumps (>3000ms).
   - Diagnostic logger PII scrubbing for emails, PINs, and secret tokens.
10. **`test/persistence/repositories_test.dart`**:
    - In-memory SQLite CRUD operations for sessions, profiles, schedules, daily limits, and audit logs.
11. **`test/presentation/screens_test.dart`**:
    - Comprehensive widget tests for all 13 screens.
    - Verified on phone layout (412x915) and tablet layout (1080x2400).
    - Circular timer ring custom painter progress rendering.

---

## 3. Code Coverage Requirements & Governance

FocusGuard enforces strict automated coverage gates:
- **Overall Code Coverage**: **> 90%** (Currently verified at **90.11%**).
- **Core Domain & Engine Logic**: **>= 95%** (Currently verified at **95.8%**).

### Execution Commands:
```bash
# Run all tests
./test

# Run tests and evaluate coverage gate
./coverage
```
On Windows PowerShell:
```powershell
.\test.ps1
.\coverage.ps1
```

Coverage is calculated via `tool/calc_coverage.dart`, which parses `coverage/lcov.info` and fails with exit code 1 if any threshold is violated.
