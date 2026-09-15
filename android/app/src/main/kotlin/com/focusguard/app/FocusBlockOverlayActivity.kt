package com.focusguard.app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.view.Gravity
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

/**
 * Full-screen blocking barrier presented when a restricted application is opened during an active focus session.
 */
class FocusBlockOverlayActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val packageNameBlocked = intent.getStringExtra("BLOCKED_PACKAGE") ?: "Application"
        val remainingSeconds = intent.getLongExtra("REMAINING_SECONDS", 0L)
        val profileName = intent.getStringExtra("PROFILE_NAME") ?: "Focus Session"

        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setBackgroundColor(0xFF0D1117.toInt())
            setPadding(48, 64, 48, 64)
        }

        val badge = TextView(this).apply {
            text = "🛡️ $profileName"
            setTextColor(0xFF6366F1.toInt())
            textSize = 14f
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 16)
        }
        layout.addView(badge)

        val title = TextView(this).apply {
            text = "Focus Active"
            setTextColor(0xFFF3F4F6.toInt())
            textSize = 28f
            paint.isFakeBoldText = true
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 16)
        }
        layout.addView(title)

        val explanation = TextView(this).apply {
            text = "Access to $packageNameBlocked is restricted to protect your attention."
            setTextColor(0xFF9CA3AF.toInt())
            textSize = 15f
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 24)
        }
        layout.addView(explanation)

        val hours = remainingSeconds / 3600
        val minutes = (remainingSeconds % 3600) / 60
        val seconds = remainingSeconds % 60
        val timeFormatted = if (hours > 0) {
            String.format("%02d:%02d:%02d remaining", hours, minutes, seconds)
        } else {
            String.format("%02d:%02d remaining", minutes, seconds)
        }

        val timerView = TextView(this).apply {
            text = timeFormatted
            setTextColor(0xFF10B981.toInt())
            textSize = 22f
            paint.isFakeBoldText = true
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 48)
        }
        layout.addView(timerView)

        // Return to FocusGuard
        val returnButton = Button(this).apply {
            text = "Open FocusGuard"
            setBackgroundColor(0xFF6366F1.toInt())
            setTextColor(0xFFFFFFFF.toInt())
            setOnClickListener {
                val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
                if (launchIntent != null) {
                    launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    startActivity(launchIntent)
                }
                finish()
            }
        }
        layout.addView(returnButton)

        // Go to Home screen
        val homeButton = Button(this).apply {
            text = "Go to Home Screen"
            setBackgroundColor(0xFF1F2937.toInt())
            setTextColor(0xFFE5E7EB.toInt())
            setOnClickListener {
                val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                    addCategory(Intent.CATEGORY_HOME)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(homeIntent)
                finish()
            }
        }
        val homeParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            setMargins(0, 24, 0, 0)
        }
        layout.addView(homeButton, homeParams)

        // Permanent Unblockable Emergency Dialer Button
        val emergencyButton = Button(this).apply {
            text = "🚨 Emergency Dialer"
            setBackgroundColor(0xFF7F1D1D.toInt())
            setTextColor(0xFFFEE2E2.toInt())
            setOnClickListener {
                val dialIntent = Intent(Intent.ACTION_DIAL).apply {
                    data = Uri.parse("tel:")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(dialIntent)
                finish()
            }
        }
        val emergencyParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            setMargins(0, 40, 0, 0)
        }
        layout.addView(emergencyButton, emergencyParams)

        setContentView(layout)
    }

    override fun onBackPressed() {
        // Redirect back to Home rather than returning to the blocked application
        val homeIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(homeIntent)
        finish()
    }
}
