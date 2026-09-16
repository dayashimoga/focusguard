#!/usr/bin/env python3
"""
Generates deterministic, lightweight fixture APKs for FocusGuard Android Real Enforcement testing:
- focusguard-test-blocked.apk (com.focusguard.test.blocked)
- focusguard-test-allowed.apk (com.focusguard.test.allowed)
"""
import os
import zipfile
import hashlib

def create_fixture_apk(output_path, package_name, app_name):
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    # Simple binary/text manifest placeholder for fixture package identification
    manifest_content = f"""<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="{package_name}"
    android:versionCode="1"
    android:versionName="1.0.0">
    <application android:label="{app_name}" android:hasCode="true">
        <activity android:name="{package_name}.MainActivity" android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
"""
    # Minimal DEX file header (empty DEX)
    # dex magic: 'dex\n035\0', followed by 104 bytes minimal DEX header
    dex_header = bytearray(b'dex\n035\x00')
    dex_header.extend(b'\x00' * 106)

    # Minimal APK zip structure
    with zipfile.ZipFile(output_path, 'w', compression=zipfile.ZIP_DEFLATED) as zf:
        zf.writestr('AndroidManifest.xml', manifest_content.encode('utf-8'))
        zf.writestr('classes.dex', bytes(dex_header))
        zf.writestr('META-INF/MANIFEST.MF', f"Manifest-Version: 1.0\nCreated-By: FocusGuard Test Harness\nPackage: {package_name}\n".encode('utf-8'))
        zf.writestr('res/values/strings.xml', f"<resources><string name=\"app_name\">{app_name}</string></resources>".encode('utf-8'))
    
    # Compute sha256
    with open(output_path, 'rb') as f:
        sha = hashlib.sha256(f.read()).hexdigest()
    
    with open(output_path + '.sha256', 'w') as f:
        f.write(f"{sha}  {os.path.basename(output_path)}\n")

    print(f"[FIXTURE] Generated {output_path} ({os.path.getsize(output_path)} bytes) SHA: {sha[:12]}...")

def main():
    root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    out_dir = os.path.join(root, 'build', 'outputs')
    os.makedirs(out_dir, exist_ok=True)
    
    create_fixture_apk(
        os.path.join(out_dir, 'focusguard-test-blocked.apk'),
        'com.focusguard.test.blocked',
        'FocusGuard Test Distraction Target'
    )
    create_fixture_apk(
        os.path.join(out_dir, 'focusguard-test-allowed.apk'),
        'com.focusguard.test.allowed',
        'FocusGuard Test Utility Target'
    )

if __name__ == '__main__':
    main()
