package com.focusguard.app

import android.content.Context
import android.os.SystemClock
import android.provider.Settings

/**
 * Hardware-backed monotonic time provider resistant to system clock manipulation.
 * SystemClock.elapsedRealtime() measures time since boot including sleep/deep-doze.
 */
object MonotonicClock {

    /**
     * Returns monotonic milliseconds elapsed since system boot.
     */
    fun elapsedRealtime(): Long {
        return SystemClock.elapsedRealtime()
    }

    /**
     * Returns boot count from Android global settings to detect reboots across sessions.
     */
    fun getBootCount(context: Context): Int {
        return try {
            Settings.Global.getInt(context.contentResolver, Settings.Global.BOOT_COUNT, 0)
        } catch (e: Exception) {
            0
        }
    }

    /**
     * Returns current wall clock time in milliseconds (for logging and display only).
     */
    fun currentTimeMillis(): Long {
        return System.currentTimeMillis()
    }
}
