package com.focusguard.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch

/**
 * Android Foreground Service maintaining persistent session enforcement, monotonic countdown,
 * foreground application interception, and DND notification management.
 */
class FocusEnforcementService : Service() {

    companion object {
        const val CHANNEL_ID = "focusguard_enforcement_channel"
        const val NOTIFICATION_ID = 1001

        const val ACTION_START = "com.focusguard.action.START"
        const val ACTION_STOP = "com.focusguard.action.STOP"
        const val ACTION_UPDATE_CONFIG = "com.focusguard.action.UPDATE_CONFIG"

        const val EXTRA_BLOCKED_PACKAGES = "BLOCKED_PACKAGES"
        const val EXTRA_ALLOWED_PACKAGES = "ALLOWED_PACKAGES"
        const val EXTRA_RESTRICTION_LEVEL = "RESTRICTION_LEVEL"
        const val EXTRA_TARGET_ELAPSED_REALTIME = "TARGET_ELAPSED_REALTIME"
        const val EXTRA_PROFILE_NAME = "PROFILE_NAME"

        @Volatile
        var isRunning = false
            private set
    }

    private val serviceJob = Job()
    private val scope = CoroutineScope(Dispatchers.Main + serviceJob)
    private lateinit var appTracker: AppUsageTracker

    private var blockedPackages = HashSet<String>()
    private var allowedPackages = HashSet<String>()
    private var restrictionLevel = "focus"
    private var targetElapsedRealtime: Long = 0L
    private var profileName: String = "Focus Session"

    private var monitorJob: Job? = null

    override fun onCreate() {
        super.onCreate()
        appTracker = AppUsageTracker(this)
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null) return START_NOT_STICKY

        when (intent.action) {
            ACTION_START -> {
                extractConfig(intent)
                startForeground(NOTIFICATION_ID, buildNotification(calculateRemainingSeconds()))
                isRunning = true
                startMonitoring()
            }
            ACTION_UPDATE_CONFIG -> {
                extractConfig(intent)
            }
            ACTION_STOP -> {
                stopEnforcement()
            }
        }

        return START_STICKY
    }

    private fun extractConfig(intent: Intent) {
        val blockedList = intent.getStringArrayListExtra(EXTRA_BLOCKED_PACKAGES)
        if (blockedList != null) {
            blockedPackages = HashSet(blockedList)
        }

        val allowedList = intent.getStringArrayListExtra(EXTRA_ALLOWED_PACKAGES)
        if (allowedList != null) {
            allowedPackages = HashSet(allowedList)
        }

        restrictionLevel = intent.getStringExtra(EXTRA_RESTRICTION_LEVEL) ?: "focus"
        targetElapsedRealtime = intent.getLongExtra(EXTRA_TARGET_ELAPSED_REALTIME, 0L)
        profileName = intent.getStringExtra(EXTRA_PROFILE_NAME) ?: "Focus Session"
    }

    private fun startMonitoring() {
        monitorJob?.cancel()
        monitorJob = scope.launch(Dispatchers.Default) {
            while (isActive && isRunning) {
                val remainingSeconds = calculateRemainingSeconds()
                if (remainingSeconds <= 0) {
                    // Session naturally expired
                    stopEnforcement()
                    break
                }

                checkForegroundApplication(remainingSeconds)

                // Update notification every 5 seconds to minimize battery/CPU
                if (remainingSeconds % 5 == 0L) {
                    updateNotification(remainingSeconds)
                }

                delay(500) // 500ms polling for responsive overlay
            }
        }
    }

    private fun checkForegroundApplication(remainingSeconds: Long) {
        val currentForeground = appTracker.getForegroundPackageName() ?: return

        // Never intercept self or system UI
        if (currentForeground == packageName ||
            currentForeground == "com.android.systemui" ||
            currentForeground.contains("dialer") ||
            currentForeground.contains("emergency")
        ) {
            return
        }

        var shouldBlock = false

        if (restrictionLevel == "strict" || restrictionLevel == "deepFocus") {
            // Whitelist mode: block if NOT in allowed packages
            if (!allowedPackages.contains(currentForeground)) {
                shouldBlock = true
            }
        } else {
            // Blacklist mode: block if IN blocked packages
            if (blockedPackages.contains(currentForeground)) {
                shouldBlock = true
            }
        }

        if (shouldBlock) {
            triggerBlockOverlay(currentForeground, remainingSeconds)
        }
    }

    private fun triggerBlockOverlay(blockedPackage: String, remainingSeconds: Long) {
        val overlayIntent = Intent(this, FocusBlockOverlayActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("BLOCKED_PACKAGE", blockedPackage)
            putExtra("REMAINING_SECONDS", remainingSeconds)
            putExtra("PROFILE_NAME", profileName)
        }
        startActivity(overlayIntent)
    }

    private fun calculateRemainingSeconds(): Long {
        val now = MonotonicClock.elapsedRealtime()
        val diff = targetElapsedRealtime - now
        return if (diff > 0) diff / 1000 else 0L
    }

    private fun buildNotification(remainingSeconds: Long): Notification {
        val hours = remainingSeconds / 3600
        val minutes = (remainingSeconds % 3600) / 60
        val seconds = remainingSeconds % 60
        val timeString = if (hours > 0) {
            String.format("%02d:%02d:%02d remaining", hours, minutes, seconds)
        } else {
            String.format("%02d:%02d remaining", minutes, seconds)
        }

        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Focus Active: $profileName")
            .setContentText(timeString)
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)
            .build()
    }

    private fun updateNotification(remainingSeconds: Long) {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        notificationManager?.notify(NOTIFICATION_ID, buildNotification(remainingSeconds))
    }

    private fun stopEnforcement() {
        isRunning = false
        monitorJob?.cancel()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "FocusGuard Active Session",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Displays the monotonic countdown for your active focus session."
                setShowBadge(false)
            }
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            notificationManager?.createNotificationChannel(channel)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        serviceJob.cancel()
        isRunning = false
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
