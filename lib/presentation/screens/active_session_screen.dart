import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/focus_session.dart';
import '../../engine/focus_engine.dart';
import '../widgets/circular_timer_ring.dart';

/// Screen displayed during an ongoing focus session.
/// Displays monotonic countdown, distraction stats, break controls, and safety override flows.
class ActiveSessionScreen extends StatefulWidget {
  final FocusEngine focusEngine;

  const ActiveSessionScreen({super.key, required this.focusEngine});

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FocusSession?>(
      stream: widget.focusEngine.sessionStream,
      initialData: widget.focusEngine.currentSession,
      builder: (context, snapshot) {
        final session = snapshot.data;

        if (session == null ||
            session.state == SessionState.completed ||
            session.state == SessionState.overridden ||
            session.state == SessionState.cancelled) {
          return _buildSessionEndedView(context, session);
        }

        final remainingSeconds =
            session.getRemainingSeconds(widget.focusEngine.getMonotonicNowMs());
        final isGracePeriod = session.state == SessionState.gracePeriod;
        final isOnBreak = session.state == SessionState.onBreak;

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(session.profileName),
            actions: [
              IconButton(
                icon: const Icon(Icons.emergency_outlined,
                    color: AppConstants.emergency),
                tooltip: 'Emergency Bypass',
                onPressed: () => _confirmEmergencyExit(context),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                // Status Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isGracePeriod
                        ? AppConstants.warning.withOpacity(0.2)
                        : isOnBreak
                            ? AppConstants.accent.withOpacity(0.2)
                            : AppConstants.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isGracePeriod
                          ? AppConstants.warning
                          : isOnBreak
                              ? AppConstants.accent
                              : AppConstants.primary,
                    ),
                  ),
                  child: Text(
                    isGracePeriod
                        ? 'GRACE PERIOD (TAP TO CANCEL)'
                        : isOnBreak
                            ? 'TEMPORARY BREAK ACTIVE'
                            : 'ENFORCEMENT ACTIVE • ${session.restrictionStrength.name.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isGracePeriod
                          ? AppConstants.warning
                          : isOnBreak
                              ? AppConstants.accent
                              : AppConstants.primaryLight,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Monotonic Timer Ring
                CircularTimerRing(
                  totalDurationSeconds: session.totalDurationSeconds,
                  remainingSeconds: remainingSeconds,
                  size: 250,
                  primaryColor:
                      isOnBreak ? AppConstants.accent : AppConstants.primary,
                  subtitle: isOnBreak
                      ? 'Break in progress'
                      : '${session.distractionAttempts} distractions deflected',
                ),
                const SizedBox(height: 36),

                // Grace Period Cancel Button
                if (isGracePeriod) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.warning,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () async {
                      await widget.focusEngine.cancelDuringGracePeriod();
                    },
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel During Grace Period'),
                  ),
                  const SizedBox(height: 16),
                ],

                // Break Controls
                if (!isGracePeriod && !isOnBreak) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              session.breaksTaken < session.maxBreaksAllowed
                                  ? () => _showBreakOptionsSheet(context)
                                  : null,
                          icon: const Icon(Icons.pause_circle_outline),
                          label: Text(
                            'Take Break (${session.maxBreaksAllowed - session.breaksTaken} left)',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                if (isOnBreak) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.accent),
                    onPressed: () async {
                      await widget.focusEngine.resumeFromBreak();
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Resume Focus Now'),
                  ),
                  const SizedBox(height: 12),
                ],

                // Unlock / Override Button
                if (!isGracePeriod)
                  TextButton.icon(
                    onPressed: () => _showOverrideDialog(context),
                    icon: const Icon(Icons.lock_open,
                        size: 18, color: AppConstants.textSecondaryDark),
                    label: const Text(
                      'Exit Focus Session',
                      style: TextStyle(color: AppConstants.textSecondaryDark),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSessionEndedView(BuildContext context, FocusSession? session) {
    final wasCompleted = session?.state == SessionState.completed;
    final wasOverridden = session?.state == SessionState.overridden;

    return Scaffold(
      appBar: AppBar(title: const Text('Session Finished')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                wasCompleted
                    ? Icons.check_circle_outline
                    : wasOverridden
                        ? Icons.lock_open
                        : Icons.info_outline,
                size: 72,
                color:
                    wasCompleted ? AppConstants.accent : AppConstants.warning,
              ),
              const SizedBox(height: 20),
              Text(
                wasCompleted
                    ? 'Goal Accomplished!'
                    : wasOverridden
                        ? 'Session Overridden'
                        : 'Session Ended',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                wasCompleted
                    ? 'Congratulations on preserving your focus for the entire duration.'
                    : 'Session exit logged. Reflect on your goals and try again when ready.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppConstants.textSecondaryDark),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Return to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBreakOptionsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppConstants.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Break Duration',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enforcement will automatically resume once your break window concludes.',
                  style: TextStyle(
                      color: AppConstants.textSecondaryDark, fontSize: 13),
                ),
                const SizedBox(height: 20),
                ...AppConstants.breakDurationMinutes.map((minutes) {
                  return ListTile(
                    leading: const Icon(Icons.timer_outlined,
                        color: AppConstants.accent),
                    title: Text('$minutes Minutes Break',
                        style: const TextStyle(color: Colors.white)),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await widget.focusEngine.startBreak(minutes);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmEmergencyExit(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppConstants.darkCard,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppConstants.emergency),
            SizedBox(width: 8),
            Text('Emergency Exit', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Emergency access is unblockable by design. Are you experiencing an emergency?',
          style: TextStyle(color: AppConstants.textSecondaryDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.emergency),
            onPressed: () async {
              Navigator.of(context).pop();
              await widget.focusEngine.emergencyExit();
            },
            child: const Text('Immediate Emergency Exit'),
          ),
        ],
      ),
    );
  }

  void _showOverrideDialog(BuildContext context) {
    final phraseController = TextEditingController();
    final reasonController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppConstants.darkCard,
        title: const Text('Exit Focus Session',
            style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Type the confirmation phrase to deliberately interrupt focus:',
                style: TextStyle(
                    color: AppConstants.textSecondaryDark, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppConstants.darkSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  AppConstants.defaultSafetyPhrase,
                  style: TextStyle(
                      color: AppConstants.primaryLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phraseController,
                decoration: const InputDecoration(hintText: 'Type phrase here'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Reason for early exit:',
                style: TextStyle(
                    color: AppConstants.textSecondaryDark, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                    hintText: 'Why do you need to break focus?'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep Focusing'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppConstants.error),
            onPressed: () async {
              try {
                await widget.focusEngine.overrideSession(
                  type: OverrideType.confirmationPhrase,
                  typedPhrase: phraseController.text,
                  typedReason: reasonController.text,
                );
                if (context.mounted) Navigator.of(context).pop();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }
}
