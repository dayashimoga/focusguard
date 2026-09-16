import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/domain_exceptions.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/override_policy.dart';
import '../../engine/focus_engine.dart';

/// Dynamically generated, inline-validated dialog governing Focus Session exit.
/// Exposes strictly the configured friction criteria and provides clear inline guidance
/// without exposing any internal state errors or unformatted stack traces.
class ExitFocusDialog extends StatefulWidget {
  final FocusEngine focusEngine;
  final VoidCallback? onExitSuccess;

  const ExitFocusDialog({
    super.key,
    required this.focusEngine,
    this.onExitSuccess,
  });

  @override
  State<ExitFocusDialog> createState() => _ExitFocusDialogState();
}

class _ExitFocusDialogState extends State<ExitFocusDialog> {
  final TextEditingController _phraseController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  late final OverridePolicy _policy;
  bool _isProcessing = false;
  String? _errorMessage;
  String? _copiedNotice;

  // Delayed cooldown timer tracking
  int _remainingCooldownSeconds = 0;
  Timer? _cooldownTimer;
  Timer? _copyNoticeTimer;

  @override
  void initState() {
    super.initState();
    _policy = widget.focusEngine.overrideCoordinator.policy;
    if (_requiresCooldown) {
      _remainingCooldownSeconds = _policy.cooldownSeconds;
      _startCooldown();
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _copyNoticeTimer?.cancel();
    _phraseController.dispose();
    _reasonController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingCooldownSeconds > 0) {
        setState(() {
          _remainingCooldownSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  // --- Dynamic Friction Derivation ---
  bool get _requiresPhrase =>
      _policy.enabledOverrideTypes.contains(OverrideType.confirmationPhrase);

  bool get _requiresReason =>
      _policy.requireReason ||
      _policy.enabledOverrideTypes.contains(OverrideType.typedReason);

  bool get _requiresPin =>
      _policy.isPinRequired ||
      _policy.enabledOverrideTypes.contains(OverrideType.pinProtected);

  bool get _requiresCooldown =>
      _policy.enabledOverrideTypes.contains(OverrideType.delayedCooldown) &&
      _policy.cooldownSeconds > 0;

  bool get _isImmediateOnly =>
      !_requiresPhrase &&
      !_requiresReason &&
      !_requiresPin &&
      !_requiresCooldown;

  // --- Inline Validation Checks ---
  bool get _isPhraseValid {
    if (!_requiresPhrase) return true;
    final typed = _phraseController.text.trim();
    final expected = _policy.confirmationPhrase.trim();
    return typed == expected;
  }

  bool get _isReasonValid {
    if (!_requiresReason) return true;
    return _reasonController.text.trim().length >= 5;
  }

  bool get _isPinValid {
    if (!_requiresPin) return true;
    return _pinController.text.trim().isNotEmpty;
  }

  bool get _isCooldownComplete {
    if (!_requiresCooldown) return true;
    return _remainingCooldownSeconds <= 0;
  }

  bool get _canSubmit =>
      !_isProcessing &&
      _isPhraseValid &&
      _isReasonValid &&
      _isPinValid &&
      _isCooldownComplete;

  Future<void> _handleCopyPhrase() async {
    await Clipboard.setData(ClipboardData(text: _policy.confirmationPhrase));
    if (!mounted) return;
    setState(() {
      _copiedNotice = 'Phrase copied to clipboard';
    });
    _copyNoticeTimer?.cancel();
    _copyNoticeTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copiedNotice = null;
        });
      }
    });
  }

  Future<void> _confirmAndEndSession() async {
    if (!_canSubmit) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Determine primary override type requested
      OverrideType targetType = OverrideType.immediate;
      if (_requiresPhrase) {
        targetType = OverrideType.confirmationPhrase;
      } else if (_requiresPin) {
        targetType = OverrideType.pinProtected;
      } else if (_requiresCooldown) {
        targetType = OverrideType.delayedCooldown;
      } else if (_requiresReason) {
        targetType = OverrideType.typedReason;
      }

      final success = await widget.focusEngine.endSessionWithOverride(
        type: targetType,
        typedPhrase: _phraseController.text.trim(),
        typedReason: _requiresReason ? _reasonController.text.trim() : null,
        pin: _requiresPin ? _pinController.text.trim() : null,
      );

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop();
        widget.onExitSuccess?.call();
      } else {
        setState(() {
          _errorMessage = 'Exit is already in progress.';
          _isProcessing = false;
        });
      }
    } on DomainException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.userMessage;
        _isProcessing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to end focus session. Please verify criteria.';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppConstants.darkCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.shield_outlined, color: AppConstants.warning, size: 24),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Exit Focus Session',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Requirements Checklist Header
              const Text(
                'To end this session you need:',
                style: TextStyle(
                  color: AppConstants.textSecondaryDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              // Checklist Items
              if (_requiresPhrase)
                _buildChecklistItem(
                  label: 'Confirmation phrase',
                  isSatisfied: _isPhraseValid,
                ),
              if (_requiresReason)
                _buildChecklistItem(
                  label: 'Reason (at least 5 characters)',
                  isSatisfied: _isReasonValid,
                ),
              if (_requiresPin)
                _buildChecklistItem(
                  label: 'Security PIN',
                  isSatisfied: _isPinValid,
                ),
              if (_requiresCooldown)
                _buildChecklistItem(
                  label: _remainingCooldownSeconds > 0
                      ? '$_remainingCooldownSeconds-second safety cooldown'
                      : 'Cooldown completed',
                  isSatisfied: _isCooldownComplete,
                ),
              if (_isImmediateOnly)
                _buildChecklistItem(
                  label: 'Immediate exit confirmation',
                  isSatisfied: true,
                ),

              const SizedBox(height: 16),

              // Section: Confirmation Phrase
              if (_requiresPhrase) ...[
                const Text(
                  'Type the confirmation phrase to deliberately interrupt focus:',
                  style: TextStyle(
                    color: AppConstants.textSecondaryDark,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppConstants.darkSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppConstants.darkBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          _policy.confirmationPhrase,
                          style: const TextStyle(
                            color: AppConstants.primaryLight,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        color: AppConstants.primaryLight,
                        tooltip: 'Copy phrase',
                        onPressed: _handleCopyPhrase,
                      ),
                    ],
                  ),
                ),
                if (_copiedNotice != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _copiedNotice!,
                    style: const TextStyle(
                      color: AppConstants.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                TextField(
                  controller: _phraseController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Type phrase here',
                    hintStyle:
                        const TextStyle(color: AppConstants.textSecondaryDark),
                    errorText: _phraseController.text.isNotEmpty &&
                            !_isPhraseValid
                        ? 'Phrase doesn\'t match. Type the confirmation phrase exactly.'
                        : null,
                    errorMaxLines: 2,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),
              ],

              // Section: Typed Reason
              if (_requiresReason) ...[
                const Text(
                  'Reason for early exit:',
                  style: TextStyle(
                    color: AppConstants.textSecondaryDark,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _reasonController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Why do you need to break focus?',
                    hintStyle:
                        const TextStyle(color: AppConstants.textSecondaryDark),
                    errorText:
                        _reasonController.text.isNotEmpty && !_isReasonValid
                            ? 'Please provide at least 5 characters.'
                            : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),
              ],

              // Section: PIN
              if (_requiresPin) ...[
                const Text(
                  'Security PIN:',
                  style: TextStyle(
                    color: AppConstants.textSecondaryDark,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Enter 4-digit PIN',
                    hintStyle: TextStyle(color: AppConstants.textSecondaryDark),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),
              ],

              // Error Banner (Never raw StateErrors or stack traces)
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppConstants.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppConstants.error),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppConstants.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppConstants.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          child: const Text('Keep Focusing'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _canSubmit ? AppConstants.error : Colors.grey.shade800,
            foregroundColor: Colors.white,
          ),
          onPressed: _canSubmit ? _confirmAndEndSession : null,
          child: _isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Confirm & End Session'),
        ),
      ],
    );
  }

  Widget _buildChecklistItem({
    required String label,
    required bool isSatisfied,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            isSatisfied ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isSatisfied
                ? AppConstants.success
                : AppConstants.textSecondaryDark,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isSatisfied ? '✓ $label' : '○ $label',
              style: TextStyle(
                color:
                    isSatisfied ? Colors.white : AppConstants.textSecondaryDark,
                fontSize: 13,
                fontWeight: isSatisfied ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
