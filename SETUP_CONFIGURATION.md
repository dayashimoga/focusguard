# FocusGuard - Initial Setup & Configuration Guide

To provide reliable digital wellbeing enforcement, FocusGuard requires explicit system permissions and OEM battery optimization exemptions.

---

## 1. Initial Permissions Setup Walkthrough

When you first open FocusGuard, navigate to the **Permissions & Diagnostics** screen (shield icon) to grant necessary system privileges:

1. **Usage Access (`PACKAGE_USAGE_STATS`)**:
   - Tap **"Grant Usage Access"**.
   - Android will open the **Usage Access** settings menu.
   - Locate **FocusGuard** in the list and toggle **Permit usage access** to ON.
   - *Why*: Allows FocusGuard to detect when a blocked app is brought to the foreground.
2. **Display Over Other Apps (`SYSTEM_ALERT_WINDOW`)**:
   - Tap **"Grant Overlay Permission"**.
   - In the system settings, toggle **Allow display over other apps** to ON.
   - *Why*: Enables FocusGuard to draw the focus blocker HUD when a restricted app is launched.
3. **Do Not Disturb Access (`ACCESS_NOTIFICATION_POLICY`)**:
   - Tap **"Grant DND Access"** (optional).
   - Authorize FocusGuard to suppress non-essential notifications during high-intensity sessions.
4. **Notifications (`POST_NOTIFICATIONS`)**:
   - On Android 13+, tap **Allow** when prompted for notification permissions so the persistent countdown notification remains visible.

---

## 2. OEM Battery Optimization & Background Killing Workarounds

Certain smartphone manufacturers implement aggressive background killers that terminate background services to artificially inflate battery life scores. To prevent FocusGuard's timer from being suspended:

### 2.1 Samsung Devices (OneUI)
1. Open **Settings -> Apps -> FocusGuard -> Battery**.
2. Select **"Unrestricted"** (do NOT choose "Optimized" or "Restricted").
3. Go to **Settings -> Battery and device care -> Battery -> Background usage limits**.
4. Tap **"Never sleeping apps"** -> Add **FocusGuard**.

### 2.2 Xiaomi / Redmi / POCO Devices (MIUI / HyperOS)
1. Long press the FocusGuard app icon -> tap **App Info**.
2. Enable **"Autostart"**.
3. Under **Battery Saver**, change setting to **"No restrictions"**.
4. Open the Android Recents screen, long press the FocusGuard card, and tap the **Lock Icon** to lock it in RAM.

### 2.3 Huawei / Honor Devices (EMUI / MagicOS)
1. Go to **Settings -> Battery -> App launch**.
2. Find FocusGuard, toggle from **"Manage automatically"** to **"Manage manually"**.
3. Ensure all three toggles are enabled: **Auto-launch**, **Secondary launch**, and **Run in background**.

### 2.4 OnePlus / Oppo / Realme Devices (OxygenOS / ColorOS)
1. Go to **Settings -> Apps -> App management -> FocusGuard**.
2. Tap **Battery usage** -> enable **"Allow background activity"** and **"Allow auto-launch"**.

---

## 3. iOS Screen Time Authorization

On iOS devices (iOS 15.0+):
1. FocusGuard prompts for authorization via Apple's `FamilyControls` system dialog.
2. Tap **"Continue"** on the Apple Screen Time authorization modal.
3. Authenticate with **FaceID**, **TouchID**, or device passcode.
4. You can now select individual apps or complete categories using the Apple-native `FamilyActivityPicker`.
