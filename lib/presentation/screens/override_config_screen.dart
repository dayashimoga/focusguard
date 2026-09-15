import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/override_policy.dart';
import '../../engine/focus_engine.dart';
import '../../persistence/settings_repository.dart';

/// Screen allowing configuration of override friction, emergency policies, and security PINs.
class OverrideConfigScreen extends StatefulWidget {
  final FocusEngine focusEngine;
  final SettingsRepository settingsRepository;

  const OverrideConfigScreen({
    super.key,
    required this.focusEngine,
    required this.settingsRepository,
  });

  @override
  State<OverrideConfigScreen> createState() => _OverrideConfigScreenState();
}

class _OverrideConfigScreenState extends State<OverrideConfigScreen> {
  late OverridePolicy _policy;
  bool _hasPin = false;

  @override
  void initState() {
    super.initState();
    _policy = widget.focusEngine.overrideCoordinator.policy;
    _checkPinStatus();
  }

  Future<void> _checkPinStatus() async {
    final hasPin = await widget.settingsRepository.hasPinConfigured();
    setState(() {
      _hasPin = hasPin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Override & Safety Policy'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Safety Note
          Card(
            color: AppConstants.emergency.withOpacity(0.15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppConstants.emergency, width: 1.2),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined,
                      color: AppConstants.emergency, size: 28),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Emergency bypass is permanently enabled and unblockable by law and safety architecture.',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Friction Mechanisms',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 12),

          // Cooldown Toggle
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: _policy.enabledOverrideTypes
                      .contains(OverrideType.delayedCooldown),
                  activeColor: AppConstants.primary,
                  title: const Text('Delayed Cooldown Timer',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: Colors.white)),
                  subtitle: Text(
                    'Requires waiting ${_policy.cooldownSeconds} seconds before session unlocks.',
                    style: const TextStyle(
                        color: AppConstants.textSecondaryDark, fontSize: 12),
                  ),
                  onChanged: (val) {
                    final updatedTypes =
                        List<OverrideType>.from(_policy.enabledOverrideTypes);
                    if (val) {
                      updatedTypes.add(OverrideType.delayedCooldown);
                    } else {
                      updatedTypes.remove(OverrideType.delayedCooldown);
                    }
                    _updatePolicy(
                        _policy.copyWith(enabledOverrideTypes: updatedTypes));
                  },
                ),
                const Divider(height: 1, color: AppConstants.darkBorder),
                SwitchListTile(
                  value: _policy.enabledOverrideTypes
                      .contains(OverrideType.confirmationPhrase),
                  activeColor: AppConstants.primary,
                  title: const Text('Typed Confirmation Phrase',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: Colors.white)),
                  subtitle: const Text(
                    'Requires typing the deliberate safety confirmation phrase.',
                    style: TextStyle(
                        color: AppConstants.textSecondaryDark, fontSize: 12),
                  ),
                  onChanged: (val) {
                    final updatedTypes =
                        List<OverrideType>.from(_policy.enabledOverrideTypes);
                    if (val) {
                      updatedTypes.add(OverrideType.confirmationPhrase);
                    } else {
                      updatedTypes.remove(OverrideType.confirmationPhrase);
                    }
                    _updatePolicy(
                        _policy.copyWith(enabledOverrideTypes: updatedTypes));
                  },
                ),
                const Divider(height: 1, color: AppConstants.darkBorder),
                SwitchListTile(
                  value: _policy.requireReason,
                  activeColor: AppConstants.primary,
                  title: const Text('Mandatory Typed Reason',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: Colors.white)),
                  subtitle: const Text(
                    'Requires documenting why you are interrupting focus.',
                    style: TextStyle(
                        color: AppConstants.textSecondaryDark, fontSize: 12),
                  ),
                  onChanged: (val) {
                    _updatePolicy(_policy.copyWith(requireReason: val));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // PIN Protection
          const Text(
            'Security PIN',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    _hasPin ? Icons.lock : Icons.lock_open,
                    color: _hasPin
                        ? AppConstants.accent
                        : AppConstants.textSecondaryDark,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _hasPin
                              ? 'PIN Protection Active'
                              : 'No PIN Configured',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                        Text(
                          _hasPin
                              ? 'Salted SHA-256 hash stored locally'
                              : 'Lock override behind a 4-8 digit numeric PIN',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppConstants.textSecondaryDark),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(80, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    onPressed: () => _showPinDialog(context),
                    child: Text(_hasPin ? 'Change' : 'Set PIN'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Daily Override Quota
          const Text(
            'Daily Override Quota',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Maximum overrides allowed per day:',
                      style: TextStyle(color: Colors.white)),
                  DropdownButton<int>(
                    value: _policy.maxOverridesPerDay,
                    dropdownColor: AppConstants.darkCard,
                    items: [1, 2, 3, 5, 10].map((count) {
                      return DropdownMenuItem(
                        value: count,
                        child: Text('$count overrides',
                            style: const TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        _updatePolicy(
                            _policy.copyWith(maxOverridesPerDay: val));
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updatePolicy(OverridePolicy newPolicy) {
    setState(() {
      _policy = newPolicy;
    });
    widget.focusEngine.updateOverridePolicy(newPolicy);
  }

  void _showPinDialog(BuildContext context) {
    final pinController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.darkCard,
        title: const Text('Set 4-8 Digit PIN',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 8,
          decoration:
              const InputDecoration(labelText: 'Numeric PIN', hintText: '1234'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final pin = pinController.text.trim();
              if (pin.length >= 4) {
                await widget.settingsRepository.setPin(pin);
                final hash = await widget.settingsRepository.getPinHash();
                final salt = await widget.settingsRepository.getPinSalt();
                final updatedPolicy = _policy.copyWith(isPinRequired: true);
                widget.focusEngine.updateOverridePolicy(updatedPolicy,
                    pinHash: hash, pinSalt: salt);
                await _checkPinStatus();
                if (ctx.mounted) Navigator.of(ctx).pop();
              }
            },
            child: const Text('Save PIN'),
          ),
        ],
      ),
    );
  }
}
