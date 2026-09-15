# FocusGuard - Build & Packaging Guide

This document provides instructions for compiling and packaging FocusGuard for Android and iOS targets across debug and production configurations.

---

## 1. Android Builds

### 1.1 Debug Build
To compile a debug APK for rapid local testing and emulation:
```bash
./scripts/build --debug
# Or inside the dev container:
flutter build apk --debug
```
Artifact generated: `build/app/outputs/flutter-apk/app-debug.apk`

### 1.2 Production Release APK
To compile an optimized, minified production APK:
```bash
./build
# Or inside the dev container:
flutter build apk --release --no-tree-shake-icons
```
Artifacts generated:
- Release APK: `build/outputs/focusguard-release.apk`
- Cryptographic SHA-256: `build/outputs/focusguard-release.apk.sha256`

### 1.3 Android App Bundle (AAB) for Google Play
```bash
podman exec -w /workspace focusguard-dev flutter build appbundle --release
```
Artifact generated: `build/app/outputs/bundle/release/app-release.aab`

### 1.4 ProGuard / R8 Optimization Rules
FocusGuard's release configuration automatically invokes R8 code shrinking and resource optimization (`android/app/build.gradle`):
- Strips unused Java/Kotlin bytecode.
- Obfuscates class and method names while preserving Flutter embedding entry points (`io.flutter.**`) and SQLite native bindings (`sqflite`).

---

## 2. iOS Builds

Because iOS compilation requires Apple's proprietary Darwin toolchain and Xcode, iOS builds are compiled on macOS hosts or via CI/CD runners (macOS-14).

### 2.1 iOS Simulator Build
```bash
flutter build ios --simulator --no-codesign
```

### 2.2 iOS Production IPA / Archive
```bash
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
```

### 2.3 Required Capabilities & Entitlements
- **Family Controls (`com.apple.developer.family-controls`)**: Required to shield apps and categories.
- **App Groups**: Facilitates data sharing between the main FocusGuard container and the `DeviceActivityMonitor` and `ShieldConfiguration` app extensions.

---

## 3. Reproducible Build Verification

To verify build artifact integrity:
```bash
cd build/outputs
sha256sum -c focusguard-release.apk.sha256
```
Expected output:
```
focusguard-release.apk: OK
```
Current release SHA-256: `1867d212a1313c68c2dee859b4b7a367f429890bea3206f9968a82e3b365b6e5`
