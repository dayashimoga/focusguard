import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../engine/focus_engine.dart';

/// Screen providing emergency access, recovery procedures, and safety documentation.
class HelpEmergencyScreen extends StatelessWidget {
  final FocusEngine focusEngine;

  const HelpEmergencyScreen({super.key, required this.focusEngine});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency & Safety'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Emergency Access Card
          Card(
            color: AppConstants.emergency.withOpacity(0.15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppConstants.emergency, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.emergency_outlined,
                      color: AppConstants.emergency, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'Emergency Dialer Access',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You are never locked out of emergency services. Tapping below immediately exits any active restriction and opens your system phone dialer.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.emergency,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      await focusEngine.emergencyExit();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Emergency exit completed. Focus restrictions lifted.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.phone_in_talk),
                    label: const Text('Open Emergency Dialer & Unlock'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text('Safety Architecture',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 12),

          _buildInfoTile(
            'Anti-Lockout Invariant',
            'FocusGuard strictly prohibits permanent or irreversible lockouts. System dialers, emergency numbers (911, 112, 999), and safety settings remain permanently accessible.',
            Icons.verified_user_outlined,
          ),
          const SizedBox(height: 10),

          _buildInfoTile(
            'PIN Recovery Procedure',
            'If you configure a PIN and forget it, you can bypass the PIN lock by waiting through the 60-second safety cooldown and typing the confirmation phrase.',
            Icons.key_outlined,
          ),
          const SizedBox(height: 10),

          _buildInfoTile(
            'Honest Platform Capabilities',
            'Android enforces barriers via UsageStats and System Alert Window overlay. Apple iOS enforces barriers via official Screen Time ManagedSettings shields. We never simulate unavailable functionality.',
            Icons.info_outline,
          ),
          const SizedBox(height: 10),

          _buildInfoTile(
            'Zero-Data / Local-First Privacy',
            'Your device usage patterns, blocked apps, and focus duration are never uploaded to any cloud server. There are no advertising trackers or telemetry SDKs.',
            Icons.privacy_tip_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String title, String description, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppConstants.primaryLight, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(description,
                      style: const TextStyle(
                          color: AppConstants.textSecondaryDark, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
