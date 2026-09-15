package com.focusguard.app

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Flutter MethodChannel plugin connecting Dart focus engine with native Android enforcement APIs.
 */
class NativeBridgePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var appTracker: AppUsageTracker

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        appTracker = AppUsageTracker(context)
        channel = MethodChannel(binding.binaryMessenger, "com.focusguard/enforcement")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getCapabilities" -> {
                val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                val hasDnd = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    notificationManager?.isNotificationPolicyAccessGranted ?: false
                } else {
                    true
                }

                val hasOverlay = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    Settings.canDrawOverlays(context)
                } else {
                    true
                }

                val capabilities = mapOf(
                    "platform" to "android",
                    "osVersion" to Build.VERSION.SDK_INT,
                    "hasUsageStatsPermission" to appTracker.hasUsageAccessPermission(),
                    "hasOverlayPermission" to hasOverlay,
                    "hasAccessibilityPermission" to FocusAccessibilityService.isEnabled,
                    "isDeviceAdminActive" to FocusDeviceAdminReceiver.isProfileOwner(context),
                    "isDeviceOwner" to FocusDeviceAdminReceiver.isDeviceOwner(context),
                    "hasDndPermission" to hasDnd,
                    "hasMonotonicClock" to true,
                    "isEnforcementRunning" to FocusEnforcementService.isRunning
                )
                result.success(capabilities)
            }

            "getMonotonicElapsedRealtime" -> {
                result.success(MonotonicClock.elapsedRealtime())
            }

            "getBootCount" -> {
                result.success(MonotonicClock.getBootCount(context))
            }

            "getInstalledApps" -> {
                val apps = appTracker.getInstalledApps()
                result.success(apps)
            }

            "getAppDailyUsage" -> {
                val packageName = call.argument<String>("packageName")
                if (packageName != null) {
                    result.success(appTracker.getDailyUsageSeconds(packageName))
                } else {
                    result.error("INVALID_ARGS", "Package name is required", null)
                }
            }

            "startEnforcement" -> {
                val blockedPackages = call.argument<List<String>>("blockedPackages") ?: emptyList()
                val allowedPackages = call.argument<List<String>>("allowedPackages") ?: emptyList()
                val restrictionLevel = call.argument<String>("restrictionLevel") ?: "focus"
                val targetElapsedRealtime = call.argument<Long>("targetElapsedRealtime") ?: 0L
                val targetWallClock = call.argument<Long>("targetWallClock") ?: 0L
                val profileName = call.argument<String>("profileName") ?: "Focus Session"

                // Persist session parameters for reboot restoration
                val prefs = context.getSharedPreferences("focusguard_session_prefs", Context.MODE_PRIVATE)
                prefs.edit()
                    .putBoolean("is_active", true)
                    .putLong("target_wall_clock", targetWallClock)
                    .putString("restriction_level", restrictionLevel)
                    .putString("profile_name", profileName)
                    .apply()

                // Update accessibility service cached packages
                FocusAccessibilityService.activeBlockedPackages = HashSet(blockedPackages)
                FocusAccessibilityService.activeAllowedPackages = HashSet(allowedPackages)
                FocusAccessibilityService.isStrictWhitelist = (restrictionLevel == "strict" || restrictionLevel == "deepFocus")

                val serviceIntent = Intent(context, FocusEnforcementService::class.java).apply {
                    action = FocusEnforcementService.ACTION_START
                    putStringArrayListExtra(FocusEnforcementService.EXTRA_BLOCKED_PACKAGES, ArrayList(blockedPackages))
                    putStringArrayListExtra(FocusEnforcementService.EXTRA_ALLOWED_PACKAGES, ArrayList(allowedPackages))
                    putExtra(FocusEnforcementService.EXTRA_RESTRICTION_LEVEL, restrictionLevel)
                    putExtra(FocusEnforcementService.EXTRA_TARGET_ELAPSED_REALTIME, targetElapsedRealtime)
                    putExtra(FocusEnforcementService.EXTRA_PROFILE_NAME, profileName)
                }

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }

                result.success(true)
            }

            "stopEnforcement" -> {
                val prefs = context.getSharedPreferences("focusguard_session_prefs", Context.MODE_PRIVATE)
                prefs.edit().putBoolean("is_active", false).apply()

                val serviceIntent = Intent(context, FocusEnforcementService::class.java).apply {
                    action = FocusEnforcementService.ACTION_STOP
                }
                context.stopService(serviceIntent)
                result.success(true)
            }

            "requestUsageStatsPermission" -> {
                val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                context.startActivity(intent)
                result.success(true)
            }

            "requestOverlayPermission" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    val intent = Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:${context.packageName}")
                    ).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    context.startActivity(intent)
                }
                result.success(true)
            }

            "requestDndPermission" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    context.startActivity(intent)
                }
                result.success(true)
            }

            "requestAccessibilitySettings" -> {
                val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                context.startActivity(intent)
                result.success(true)
            }

            "setDndFilter" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                    if (nm != null && nm.isNotificationPolicyAccessGranted) {
                        val filter = if (enabled) {
                            NotificationManager.INTERRUPTION_FILTER_PRIORITY
                        } else {
                            NotificationManager.INTERRUPTION_FILTER_ALL
                        }
                        nm.setInterruptionFilter(filter)
                    }
                }
                result.success(true)
            }

            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
