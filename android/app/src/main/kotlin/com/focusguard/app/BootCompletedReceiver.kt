package com.focusguard.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * BroadcastReceiver triggered when device finishes booting or application package is replaced.
 * Automatically restores interrupted focus sessions and reschedules recurring timers.
 */
class BootCompletedReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action == Intent.ACTION_BOOT_COMPLETED ||
            action == Intent.ACTION_LOCKED_BOOT_COMPLETED ||
            action == Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            val prefs = context.getSharedPreferences("focusguard_session_prefs", Context.MODE_PRIVATE)
            val isSessionActive = prefs.getBoolean("is_active", false)
            val targetWallClock = prefs.getLong("target_wall_clock", 0L)
            val nowWallClock = System.currentTimeMillis()

            if (isSessionActive && targetWallClock > nowWallClock) {
                // Resume session enforcement
                val remainingMillis = targetWallClock - nowWallClock
                val targetElapsed = MonotonicClock.elapsedRealtime() + remainingMillis

                val serviceIntent = Intent(context, FocusEnforcementService::class.java).apply {
                    this.action = FocusEnforcementService.ACTION_START
                    putExtra(FocusEnforcementService.EXTRA_TARGET_ELAPSED_REALTIME, targetElapsed)
                    putExtra(FocusEnforcementService.EXTRA_RESTRICTION_LEVEL, prefs.getString("restriction_level", "focus"))
                    putExtra(FocusEnforcementService.EXTRA_PROFILE_NAME, prefs.getString("profile_name", "Focus Session"))
                }

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
            }
        }
    }
}
