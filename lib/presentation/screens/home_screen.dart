import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/focus_profile.dart';
import '../../domain/models/focus_session.dart';
import '../../engine/focus_engine.dart';
import '../widgets/circular_timer_ring.dart';
import 'active_session_screen.dart';

/// Primary Dashboard Screen.
/// Enables starting a focus session within 2 taps and displays live status, streak, and daily focus statistics.
class HomeScreen extends StatelessWidget {
  final FocusEngine focusEngine;
  final VoidCallback onNavigateToStart;
  final VoidCallback onNavigateToProfiles;
  final VoidCallback onNavigateToSchedules;
  final VoidCallback onNavigateToEmergency;

  const HomeScreen({
    super.key,
    required this.focusEngine,
    required this.onNavigateToStart,
    required this.onNavigateToProfiles,
    required this.onNavigateToSchedules,
    required this.onNavigateToEmergency,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FocusSession?>(
      stream: focusEngine.sessionStream,
      initialData: focusEngine.currentSession,
      builder: (context, snapshot) {
        final session = snapshot.data;
        final hasActiveSession = session != null &&
            (session.state == SessionState.active ||
                session.state == SessionState.gracePeriod ||
                session.state == SessionState.onBreak);

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppConstants.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.shield_outlined,
                      color: AppConstants.primary, size: 22),
                ),
                const SizedBox(width: 10),
                const Text(AppConstants.appName),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.sos, color: AppConstants.emergency),
                tooltip: 'Emergency Safety Exit',
                onPressed: onNavigateToEmergency,
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasActiveSession) ...[
                  _buildActiveSessionBanner(context, session),
                  const SizedBox(height: 24),
                ],

                // Quick Start Card (1-Tap Focus Presets)
                _buildQuickStartSection(context),
                const SizedBox(height: 24),

                // Daily Progress & Streak Summary
                _buildDailyProgressSection(context),
                const SizedBox(height: 24),

                // Quick Tools
                _buildQuickNavigationGrid(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveSessionBanner(BuildContext context, FocusSession session) {
    final remainingSeconds =
        session.getRemainingSeconds(focusEngine.getMonotonicNowMs());

    return Card(
      color: AppConstants.primaryDark.withOpacity(0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppConstants.primary, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConstants.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    session.state == SessionState.gracePeriod
                        ? 'GRACE PERIOD'
                        : session.state == SessionState.onBreak
                            ? 'ON BREAK'
                            : 'FOCUS ACTIVE',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  session.profileName,
                  style: const TextStyle(
                      color: AppConstants.textSecondaryDark, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CircularTimerRing(
              totalDurationSeconds: session.totalDurationSeconds,
              remainingSeconds: remainingSeconds,
              size: 180,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        ActiveSessionScreen(focusEngine: focusEngine),
                  ),
                );
              },
              icon: const Icon(Icons.open_in_full, size: 18),
              label: const Text('View Active Session'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStartSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quick Focus',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
            TextButton(
              onPressed: onNavigateToStart,
              child: const Text('Custom Duration →'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children:
              AppConstants.quickSessionMinutes.sublist(0, 6).map((minutes) {
            return InkWell(
              onTap: () async {
                final defaultProfile = FocusProfile.defaultPresets.first;
                await focusEngine.startSession(
                  profile: defaultProfile,
                  durationMinutes: minutes,
                );
                if (context.mounted) {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ActiveSessionScreen(focusEngine: focusEngine),
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppConstants.darkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppConstants.darkBorder.withOpacity(0.8)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$minutes',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      'min',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppConstants.textSecondaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDailyProgressSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.insights,
                    color: AppConstants.accent, size: 22),
                const SizedBox(width: 10),
                const Text(
                  'Today\'s Wellbeing',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppConstants.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Goal: 2h 00m',
                    style: TextStyle(
                        color: AppConstants.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                    'Focused Today', '1h 15m', Icons.timer_outlined),
                Container(width: 1, height: 40, color: AppConstants.darkBorder),
                _buildStatColumn('Distractions Blocked', '14', Icons.block),
                Container(width: 1, height: 40, color: AppConstants.darkBorder),
                _buildStatColumn(
                    'Current Streak', '4 Days', Icons.local_fire_department),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppConstants.textSecondaryDark),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
              fontSize: 11, color: AppConstants.textSecondaryDark),
        ),
      ],
    );
  }

  Widget _buildQuickNavigationGrid(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onNavigateToProfiles,
            icon: const Icon(Icons.tune, size: 18),
            label: const Text('Profiles'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onNavigateToSchedules,
            icon: const Icon(Icons.schedule, size: 18),
            label: const Text('Schedules'),
          ),
        ),
      ],
    );
  }
}
