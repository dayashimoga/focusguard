package com.focusguard.app

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Process
import java.util.Calendar

/**
 * Tracks foreground application transitions and queries application usage stats.
 */
class AppUsageTracker(private val context: Context) {

    private val usageStatsManager =
        context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager

    /**
     * Checks whether PACKAGE_USAGE_STATS permission is granted by user.
     */
    fun hasUsageAccessPermission(): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as? AppOpsManager ?: return false
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            context.packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    /**
     * Queries the most recent foreground application package name.
     */
    fun getForegroundPackageName(): String? {
        if (!hasUsageAccessPermission() || usageStatsManager == null) return null

        val endTime = System.currentTimeMillis()
        val startTime = endTime - 1000 * 60 // Inspect last 60 seconds of events
        val usageEvents = usageStatsManager.queryEvents(startTime, endTime) ?: return null

        val event = UsageEvents.Event()
        var lastForegroundPackage: String? = null
        var lastEventTime: Long = 0

        while (usageEvents.hasNextEvent()) {
            usageEvents.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED && event.timeStamp > lastEventTime) {
                lastForegroundPackage = event.packageName
                lastEventTime = event.timeStamp
            }
        }

        return lastForegroundPackage
    }

    /**
     * Returns total foreground screen time for a given package since midnight today in seconds.
     */
    fun getDailyUsageSeconds(packageName: String): Long {
        if (!hasUsageAccessPermission() || usageStatsManager == null) return 0L

        val calendar = Calendar.getInstance()
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)

        val startTime = calendar.timeInMillis
        val endTime = System.currentTimeMillis()

        val statsList = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        ) ?: return 0L

        for (stats in statsList) {
            if (stats.packageName == packageName) {
                return stats.totalTimeInForeground / 1000
            }
        }

        return 0L
    }

    /**
     * Returns a list of all installed launchable applications with metadata.
     */
    fun getInstalledApps(): List<Map<String, Any>> {
        val pm = context.packageManager
        val intent = android.content.Intent(android.content.Intent.ACTION_MAIN, null)
        intent.addCategory(android.content.Intent.CATEGORY_LAUNCHER)

        val resolveInfoList = pm.queryIntentActivities(intent, 0)
        val apps = mutableListOf<Map<String, Any>>()

        for (info in resolveInfoList) {
            val pkgName = info.activityInfo.packageName
            val appName = info.loadLabel(pm).toString()
            val isSystemApp = (info.activityInfo.applicationInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0

            apps.add(
                mapOf(
                    "packageName" to pkgName,
                    "appName" to appName,
                    "isSystemApp" to isSystemApp,
                    "isEssential" to isDefaultEssentialApp(pkgName)
                )
            )
        }

        return apps.sortedBy { it["appName"] as String }
    }

    /**
     * Identifies core emergency and communication utilities that should never be locked out by default.
     */
    private fun isDefaultEssentialApp(packageName: String): Boolean {
        val lower = packageName.lowercase()
        return lower.contains("dialer") ||
                lower.contains("telecom") ||
                lower.contains("phone") ||
                lower.contains("emergency") ||
                lower.contains("contacts") ||
                lower.contains("settings") ||
                lower.contains("systemui")
    }
}
