# FocusGuard - Continuous Integration & Delivery (CI/CD) Pipeline

FocusGuard employs automated CI/CD workflows powered by GitHub Actions to guarantee code quality, test coverage, cryptographic integrity, and release packaging.

---

## 1. CI Pipeline Architecture (`.github/workflows/ci.yml`)

The CI workflow executes on every commit pushed to `main`, `feature/**`, `fix/**`, and all Pull Requests.

```mermaid
graph TD
    Trigger([Push / PR]) --> Job1[Job 1: Quality, Security & Automated Tests]
    Job1 --> Step1[1. Checkout Repository]
    Step1 --> Step2[2. Setup Java 17 & Flutter 3.24.3]
    Step2 --> Step3[3. Check Code Formatting<br/>dart format --set-exit-if-changed]
    Step3 --> Step4[4. Static Analysis<br/>flutter analyze --fatal-infos]
    Step4 --> Step5[5. Test Execution & Coverage<br/>flutter test --coverage]
    Step5 --> Step6[6. Coverage Threshold Gate<br/>Overall >= 90%, Domain >= 95%]
    Step6 --> Step7[7. Security & Offline Audit<br/>tool/security_audit.dart]
    Step7 --> Job2[Job 2: Build Production Release Artifacts]
    Job2 --> Step8[8. Build Release APK<br/>flutter build apk --release]
    Step8 --> Step9[9. Checksum Calculation<br/>sha256sum]
    Step9 --> Step10[10. SBOM Generation<br/>tool/generate_sbom.dart]
    Step10 --> Step11[11. Upload Release Artifacts]
```

### 1.1 Strict Quality Gates
1. **Formatting**: Any unformatted Dart file fails the build immediately.
2. **Analysis**: Zero warnings, zero errors, zero hints permitted.
3. **Coverage**: Must achieve at least 90.0% overall line coverage.
4. **Security Audit**: Scans source code for tracking SDKs, unauthorized network endpoints, and verifies zero network permissions in `AndroidManifest.xml`.

---

## 2. Release Pipeline Architecture (`.github/workflows/release.yml`)

Triggered automatically upon pushing a semantic version tag (e.g. `v1.0.0`):
1. Runs full static analysis and automated test suites.
2. Compiles production release APK with minification and tree-shaking.
3. Generates cryptographic SHA-256 checksum file (`focusguard-release.apk.sha256`).
4. Generates Software Bill of Materials in CycloneDX format (`sbom.json`).
5. Executes Acceptance Certification Suite producing `acceptance.json` and `acceptance.html`.
6. Creates an official GitHub Release with signed artifacts, release notes, and acceptance certificates attached.
