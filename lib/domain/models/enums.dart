// Core domain enumerations for FocusGuard.

/// Restriction enforcement strength levels.
enum RestrictionStrength {
  /// Gentle: Soft banners and polite reminders; dismissible after a short interval.
  gentle,

  /// Focus: Selected blocked apps are intercepted and redirected away from distractions.
  focus,

  /// Strict: Whitelist-only mode. Everything except explicit essentials is blocked.
  strict,

  /// Deep Focus: Maximum friction. Strongest supported barrier with multi-step override.
  deepFocus,

  /// Managed/Kiosk: Hardware-pinned LockTask mode via DevicePolicyManager (MDM/Device Owner only).
  managedKiosk,
}

/// Lifecycle states of a Focus Session state machine.
enum SessionState {
  /// No active focus session running.
  idle,

  /// Brief grace period before hard enforcement begins (allows user to cancel unintended start).
  gracePeriod,

  /// Active enforcement with monotonic countdown running.
  active,

  /// Temporary pause/break with separate break countdown running.
  onBreak,

  /// User successfully unlocked session via configured override policy.
  overridden,

  /// Focus session completed its full duration naturally.
  completed,

  /// Session explicitly terminated by user before activation.
  cancelled,
}

/// Override and safety exit mechanisms.
enum OverrideType {
  /// Immediate exit without delay.
  immediate,

  /// Delayed exit enforcing a mandatory countdown cooldown (e.g. 30 seconds).
  delayedCooldown,

  /// Requires typing a deliberate reason for breaking focus.
  typedReason,

  /// Requires typing a specific safety confirmation phrase.
  confirmationPhrase,

  /// Requires authenticating with a secure hashed PIN.
  pinProtected,

  /// Instant unblockable emergency exit for calls/dialer.
  emergency,
}

/// App category taxonomy.
enum AppCategory {
  social,
  entertainment,
  gaming,
  shopping,
  news,
  communication,
  productivity,
  education,
  utility,
  system,
}

/// Verification classification mandated by specification.
enum VerificationClassification {
  VERIFIED,
  EMULATOR_VERIFIED,
  DEVICE_VERIFIED,
  IMPLEMENTED_UNVERIFIED,
  HARDWARE_REQUIRED,
  PLATFORM_UNSUPPORTED,
  FAILED,
}
