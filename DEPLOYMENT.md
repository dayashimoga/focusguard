# FocusGuard - Deployment & Distribution Guide

FocusGuard is distributed across consumer app stores, direct sideloading channels, and enterprise MDM deployments.

---

## 1. Android Deployment Options

### 1.1 Direct Sideloading (Recommended for Maximum Sovereignty)
Users seeking 100% telemetry-free installations can download the signed release APK directly from the GitHub Releases page:
```bash
adb install -r build/outputs/focusguard-release.apk
```
- **Integrity Check**: Always verify SHA-256 against `build/outputs/focusguard-release.apk.sha256`.

### 1.2 Enterprise / MDM Kiosk Deployment (Device Owner Mode)
For educational institutions, exam environments, or strict digital wellbeing deployments, FocusGuard can be provisioned as **Android Device Owner**:
```bash
# Provision device owner on a freshly wiped or unprovisioned device
adb shell dpm set-device-owner com.focusguard.app/.FocusDeviceAdminReceiver
```
**Privileges Granted in Device Owner Mode**:
- Lock Task Mode (kiosk pinning where Home and Recents cannot be pressed).
- Inability for the user to uninstall FocusGuard during an active session.
- Hardware power menu lock and safe mode reboot suppression (`DISALLOW_SAFE_BOOT`).

### 1.3 Google Play Store Deployment
For Google Play distribution, build the Android App Bundle:
```bash
flutter build appbundle --release
```
**Google Play Policy Considerations**:
- **Usage Stats & Overlay Permissions**: Google Play permits `PACKAGE_USAGE_STATS` and `SYSTEM_ALERT_WINDOW` for digital wellbeing applications under the "Device Experience / Wellbeing" declaration.
- **Accessibility Service**: The optional accessibility helper is distributed via sideloading / F-Droid builds to adhere to Google Play's strict accessibility declaration policies.

---

## 2. iOS Deployment Options

### 2.1 Apple App Store & TestFlight
- Distribution requires an Apple Developer Program enrollment with the **Family Controls Entitlement** approved by Apple.
- Submitted via Xcode Archive or `flutter build ipa`.

### 2.2 Enterprise In-House Distribution (Apple Developer Enterprise Program)
- Organizations can sign FocusGuard with an Enterprise Distribution Certificate for internal company devices, bypassing standard App Store review.
