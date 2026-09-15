package com.focusguard.app

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.view.accessibility.AccessibilityEvent

/**
 * Optional zero-latency accessibility service used when user explicitly enables it for Strict/Deep Focus modes.
 * Listens for TYPE_WINDOW_STATE_CHANGED events to instantly intercept blocked applications before they render.
 */
class FocusAccessibilityService : AccessibilityService() {

    companion object {
        @Volatile
        var isEnabled = false
            private set

        @Volatile
        var activeBlockedPackages = HashSet<String>()

        @Volatile
        var isStrictWhitelist = false

        @Volatile
        var activeAllowedPackages = HashSet<String>()
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        isEnabled = true
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null || event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return
        if (!FocusEnforcementService.isRunning) return

        val targetPackage = event.packageName?.toString() ?: return

        // Bypass self, system UI, dialers
        if (targetPackage == packageName ||
            targetPackage == "com.android.systemui" ||
            targetPackage.contains("dialer") ||
            targetPackage.contains("emergency")
        ) {
            return
        }

        var shouldBlock = false
        if (isStrictWhitelist) {
            if (!activeAllowedPackages.contains(targetPackage)) {
                shouldBlock = true
            }
        } else {
            if (activeBlockedPackages.contains(targetPackage)) {
                shouldBlock = true
            }
        }

        if (shouldBlock) {
            // Immediately kick user back to home screen or overlay
            val overlayIntent = Intent(this, FocusBlockOverlayActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("BLOCKED_PACKAGE", targetPackage)
            }
            startActivity(overlayIntent)
        }
    }

    override fun onInterrupt() {
        // Required callback
    }

    override fun onDestroy() {
        super.onDestroy()
        isEnabled = false
    }
}
