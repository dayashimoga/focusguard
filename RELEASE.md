# FocusGuard - Release Management & Versioning

FocusGuard adheres to **Semantic Versioning 2.0.0** (`MAJOR.MINOR.PATCH`):
- **MAJOR**: Breaking architectural changes, database schema breaking rewrites without forward migration, or major platform compatibility drops.
- **MINOR**: New functional features (e.g. new override mechanisms, new profiles, new platform integrations) with backward compatibility.
- **PATCH**: Bug fixes, performance optimizations, and documentation updates.

---

## 1. Release Checklist

Prior to publishing a release, the Release Lead must execute the following checklist:

- [ ] All automated tests pass: `./test`
- [ ] Code coverage satisfies threshold: `./coverage` (>= 90% overall, >= 95% domain)
- [ ] Static analysis passes with zero warnings: `./lint`
- [ ] Security audit passes: `podman exec focusguard-dev dart run tool/security_audit.dart`
- [ ] Acceptance certification suite passes: `./acceptance.sh --full`
- [ ] Production APK builds cleanly: `./build`
- [ ] Verify release artifact checksum against `focusguard-release.apk.sha256`
- [ ] SBOM generated and validated at `build/outputs/sbom.json`
- [ ] Update [CHANGELOG.md](CHANGELOG.md) with chronological release entry
- [ ] Tag git commit: `git tag -a v1.0.0 -m "Release v1.0.0"`
- [ ] Push tag to remote: `git push origin v1.0.0`

---

## 2. Signing Key Management

### 2.1 Keystore Security
- The production signing key (`focusguard-release.keystore`) is stored securely in GitHub Secrets / HashiCorp Vault.
- It is never committed to source control.
- Developers use standard Android debug keys for local container compilation.

### 2.2 Reproducible Verification
Every release publishes the exact SHA-256 checksum of the output APK. Community members and auditors can compile the application from source in the pinned Podman container (`ghcr.io/cirruslabs/flutter:3.24.3`) to verify that the binary matches the published release.

---

## 3. Rollback Procedures

If an unrecoverable defect is discovered post-release:
1. **Sideload Channels**: Issue an immediate patch release (`v1.0.x`) and mark the defective release as withdrawn on GitHub Releases.
2. **Google Play Store**: Utilize Google Play Console's staged rollout halt, or promote the previous stable version code in the production release track.
3. **Database Safeguard**: FocusGuard's SQLite migrations support forward-only schema upgrades with data preservation to prevent user data loss during hotfix rollouts.
