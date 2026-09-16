import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// Screen presenting focus time analytics, completion rates, and distraction attempts.
class UsageInsightsScreen extends StatelessWidget {
  const UsageInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usage Insights & Analytics'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Privacy Callout
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppConstants.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppConstants.accent.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline, color: AppConstants.accent, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '100% Local-First: Analytics are computed strictly on-device. No data ever leaves your hardware.',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Total Focus Time Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Focus Time',
                      style: TextStyle(
                          color: AppConstants.textSecondaryDark, fontSize: 13)),
                  const SizedBox(height: 8),
                  const Text('18h 45m',
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildMetricItem('This Week', '12h 10m')),
                      Expanded(
                          child: _buildMetricItem('Completion Rate', '92%')),
                      Expanded(child: _buildMetricItem('Overrides', '2 exits')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Distraction Attempts
          const Text(
            'Most Frequently Deflected Apps',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 12),

          _buildDeflectedAppRow('Instagram', '38 attempts blocked', 0.85,
              Icons.camera_alt_outlined),
          _buildDeflectedAppRow('YouTube', '24 attempts blocked', 0.60,
              Icons.play_circle_outline),
          _buildDeflectedAppRow(
              'X / Twitter', '15 attempts blocked', 0.40, Icons.chat_outlined),
          _buildDeflectedAppRow(
              'Reddit', '9 attempts blocked', 0.25, Icons.reddit),
          const SizedBox(height: 20),

          // Consistency / Streak
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppConstants.warning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.local_fire_department,
                        color: AppConstants.warning, size: 32),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('4-Day Consistency Streak',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        SizedBox(height: 4),
                        Text(
                          'You have maintained your scheduled focus goals every day this week without unnecessary lapses.',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppConstants.textSecondaryDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 11, color: AppConstants.textSecondaryDark),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppConstants.primaryLight),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _buildDeflectedAppRow(
      String appName, String subtitle, double fraction, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: AppConstants.primaryLight, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(appName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: AppConstants.textSecondaryDark)),
                ],
              ),
            ),
            SizedBox(
              width: 80,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: fraction,
                  backgroundColor: AppConstants.darkBorder,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppConstants.primary),
                  minHeight: 6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
