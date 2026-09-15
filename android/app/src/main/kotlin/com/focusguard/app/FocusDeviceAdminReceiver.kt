package com.focusguard.app

import android.app.admin.DeviceAdminReceiver
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent

/**
 * DeviceAdminReceiver for Managed / Kiosk mode enforcement.
 * When provisioned as Device Owner (via ADB or NFC), FocusGuard can enforce LockTaskMode.
 */
class FocusDeviceAdminReceiver : DeviceAdminReceiver() {

    companion object {
        fun getComponentName(context: Context): ComponentName {
            return ComponentName(context.applicationContext, FocusDeviceAdminReceiver::class.java)
        }

        fun isDeviceOwner(context: Context): Boolean {
            val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as? DevicePolicyManager
            return dpm?.isDeviceOwnerApp(context.packageName) ?: false
        }

        fun isProfileOwner(context: Context): Boolean {
            val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as? DevicePolicyManager
            return dpm?.isProfileOwnerApp(context.packageName) ?: false
        }

        fun setLockTaskPackages(context: Context, packages: Array<String>) {
            val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as? DevicePolicyManager
            val admin = getComponentName(context)
            if (dpm != null && dpm.isDeviceOwnerApp(context.packageName)) {
                dpm.setLockTaskPackages(admin, packages)
            }
        }
    }

    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
    }
}
