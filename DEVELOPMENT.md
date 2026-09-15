# FocusGuard - Developer Onboarding & Development Workflow

Welcome to the FocusGuard engineering team. FocusGuard is built with zero-host-install requirements using containerized toolchains.

---

## 1. Prerequisites

The **only prerequisite** required on your host machine is **Podman** (or Docker). You do not need to install Flutter, Dart, Java, or the Android SDK on your host system.

- **Linux / macOS**: `podman` installed via package manager.
- **Windows**: `podman-desktop` or `podman machine` running via WSL2 / Hyper-V.

---

## 2. Quickstart Development Commands

FocusGuard provides unified shell and PowerShell scripts in the root directory:

| Task | Linux / macOS Bash | Windows PowerShell | Direct Container Command |
| :--- | :--- | :--- | :--- |
| **Start Dev Container** | `./dev-up` | `.\dev-up.ps1` | `podman run -d --name focusguard-dev ...` |
| **Stop Dev Container** | `./dev-down` | `.\dev-down.ps1` | `podman rm -f focusguard-dev` |
| **Run Static Analysis** | `./lint` | `.\lint.ps1` | `flutter analyze --fatal-infos` |
| **Run Automated Tests** | `./test` | `.\test.ps1` | `flutter test` |
| **Run Coverage Gate** | `./coverage` | `.\coverage.ps1` | `flutter test --coverage && dart run tool/calc_coverage.dart` |
| **Build Release APK** | `./build` | `.\build.ps1` | `flutter build apk --release --no-tree-shake-icons` |
| **Full Acceptance Cert** | `./acceptance.sh --full` | `.\acceptance.ps1 -full` | `dart run acceptance/acceptance_runner.dart --full` |
| **Clean Build Artifacts**| `bash scripts/clean` | `.\clean.ps1` | `flutter clean && rm -rf build` |

---

## 3. Directory Structure

```
h:/focus/
├── .github/workflows/         # GitHub Actions CI/CD workflows (ci.yml, release.yml)
├── acceptance/                # Acceptance certification runner (acceptance_runner.dart)
├── android/                   # Native Android Kotlin module & Gradle project
│   ├── app/src/main/kotlin/   # Foreground service, overlay activity, device admin, receivers
│   └── app/src/main/res/      # Layouts, mipmaps, XML configs, adaptive launcher icons
├── ios/                       # Native iOS Swift module & Xcode project
│   └── Runner/                # Screen Time bridge, activity monitor, shield config
├── lib/                       # Core Flutter/Dart Application Code
│   ├── core/                  # Security (PIN hasher, tamper detector), theme, logger, monotonic time
│   ├── domain/                # Models, enums, value objects, session state machine
│   ├── engine/                # Countdown timer, focus engine, break manager, scheduler, daily limits
│   ├── persistence/           # SQLite database helper, migrations, repositories
│   ├── platform/              # Platform channel bridge and dynamic capability matrix
│   └── presentation/          # Adaptive scaffold, circular timer ring, and 13 screens
├── scripts/                   # Cross-platform developer automation scripts
├── test/                      # Unit, widget, and integration test suites (>90% coverage)
├── tool/                      # Tooling: coverage calculator, security audit, SBOM generator
├── Containerfile              # Reproducible Podman container definition
├── pubspec.yaml               # Pinned dependencies and asset declarations
├── TODO.md                    # Append-only engineering journal
└── CHANGELOG.md               # Append-only version changelog
```

---

## 4. Coding & Architecture Standards

1. **Deterministic Logic**: Domain and engine layers must be 100% testable without Flutter UI dependencies or live platform channels.
2. **Offline Purity**: Never introduce dependencies that make network connections or bundle external tracking SDKs.
3. **Zero Lint Tolerations**: The codebase must maintain **zero errors, zero warnings, and zero hints** under `analysis_options.yaml`.
4. **Append-Only Governance**: `TODO.md` and `CHANGELOG.md` are strictly append-only. Never delete historical logs.
5. **Coverage Enforcement**: Every PR must satisfy the coverage gate: **overall coverage > 90%** and **core domain logic >= 95%**.
