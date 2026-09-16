import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/focus_profile.dart';
import '../../engine/focus_engine.dart';
import 'active_session_screen.dart';

/// Screen allowing configuration and initiation of custom focus sessions.
class StartFocusScreen extends StatefulWidget {
  final FocusEngine focusEngine;
  final List<FocusProfile> profiles;

  const StartFocusScreen({
    super.key,
    required this.focusEngine,
    required this.profiles,
  });

  @override
  State<StartFocusScreen> createState() => _StartFocusScreenState();
}

class _StartFocusScreenState extends State<StartFocusScreen> {
  int _selectedMinutes = 60;
  late FocusProfile _selectedProfile;
  late RestrictionStrength _selectedStrength;

  @override
  void initState() {
    super.initState();
    _selectedProfile = widget.profiles.isNotEmpty
        ? widget.profiles.first
        : FocusProfile.defaultPresets.first;
    _selectedStrength = _selectedProfile.restrictionStrength;
  }

  void _calculateUntilTomorrowMorning() {
    final now = DateTime.now();
    DateTime target =
        DateTime(now.year, now.month, now.day + 1, 7, 0); // 7:00 AM tomorrow
    final diff = target.difference(now);
    final minutes = diff.inMinutes.clamp(15, 720);
    setState(() {
      _selectedMinutes = minutes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Start Focus Session'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Duration selector
            const Text(
              'Session Duration',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                _formatDurationDisplay(_selectedMinutes),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppConstants.primary,
                ),
              ),
            ),
            Slider(
              value: _selectedMinutes.toDouble(),
              min: 5,
              max: 240,
              divisions: 47,
              onChanged: (val) {
                setState(() {
                  _selectedMinutes = val.toInt();
                });
              },
            ),
            const SizedBox(height: 12),

            // Quick Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...AppConstants.quickSessionMinutes.map((m) {
                  final isSelected = _selectedMinutes == m;
                  return ChoiceChip(
                    label: Text('${m}m'),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedMinutes = m;
                      });
                    },
                  );
                }),
                ActionChip(
                  avatar: const Icon(Icons.wb_sunny_outlined, size: 16),
                  label: const Text('Until 7:00 AM'),
                  onPressed: _calculateUntilTomorrowMorning,
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Profile Selector
            const Text(
              'Focus Profile',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppConstants.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppConstants.darkBorder),
              ),
              child: Column(
                children: widget.profiles.map((p) {
                  final isSelected = _selectedProfile.id == p.id;
                  return RadioListTile<String>(
                    value: p.id,
                    groupValue: _selectedProfile.id,
                    onChanged: (val) {
                      setState(() {
                        _selectedProfile = widget.profiles
                            .firstWhere((item) => item.id == val);
                        _selectedStrength =
                            _selectedProfile.restrictionStrength;
                      });
                    },
                    title: Text(
                      p.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    subtitle: Text(
                      p.description,
                      style: const TextStyle(
                          fontSize: 12, color: AppConstants.textSecondaryDark),
                    ),
                    secondary: Icon(
                      isSelected ? Icons.shield : Icons.shield_outlined,
                      color: isSelected
                          ? AppConstants.primary
                          : AppConstants.textSecondaryDark,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 28),

            // Restriction Strength
            const Text(
              'Enforcement Strength',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<RestrictionStrength>(
              value: _selectedStrength,
              isExpanded: true,
              decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: RestrictionStrength.values.map((strength) {
                return DropdownMenuItem(
                  value: strength,
                  child: Text(
                    _formatStrengthName(strength),
                    style: const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedStrength = val;
                  });
                }
              },
            ),
            const SizedBox(height: 32),

            // Start Button
            ElevatedButton(
              onPressed: () async {
                final configuredProfile = _selectedProfile.copyWith(
                  restrictionStrength: _selectedStrength,
                );
                await widget.focusEngine.startSession(
                  profile: configuredProfile,
                  durationMinutes: _selectedMinutes,
                );
                if (context.mounted) {
                  await Navigator.of(context).pushReplacement<void, void>(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ActiveSessionScreen(focusEngine: widget.focusEngine),
                    ),
                  );
                }
              },
              child: Text(
                'Start Focus (${_formatDurationDisplay(_selectedMinutes)})',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                '10-second grace period allows you to cancel without penalty.',
                style: TextStyle(
                    fontSize: 12, color: AppConstants.textSecondaryDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDurationDisplay(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '$h Hour${h > 1 ? "s" : ""}';
    return '$m Minutes';
  }

  String _formatStrengthName(RestrictionStrength strength) {
    switch (strength) {
      case RestrictionStrength.gentle:
        return '1. Gentle (Soft reminders)';
      case RestrictionStrength.focus:
        return '2. Focus (Blocked apps intercepted)';
      case RestrictionStrength.strict:
        return '3. Strict (Whitelist only mode)';
      case RestrictionStrength.deepFocus:
        return '4. Deep Focus (Maximum friction barrier)';
      case RestrictionStrength.managedKiosk:
        return '5. Managed/Kiosk Mode (Device Owner)';
    }
  }
}
