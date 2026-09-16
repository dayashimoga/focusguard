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

  /// Override transaction initiated by user.
  overrideRequested,

  /// Override friction / credentials being validated.
  overrideValidating,

  /// Restrictions being lifted, timers cancelled, and state persisted.
  ending,

  /// User successfully unlocked session via configured override policy (ended via override).
  overridden,

  /// Focus session completed its full duration naturally (ended normal).
  completed,

  /// Session explicitly terminated by user before activation.
  cancelled,

  /// Monotonic countdown reached target and natural completion initiated.
  expired;

  /// Whether the session is actively enforcing restrictions.
  bool get isEnforcing => this == SessionState.active;

  /// Whether the session is in a terminal ended state.
  bool get isTerminal =>
      this == SessionState.overridden ||
      this == SessionState.completed ||
      this == SessionState.cancelled;

  /// Whether the session is currently in an exit transition.
  bool get isTransitioningToExit =>
      this == SessionState.overrideRequested ||
      this == SessionState.overrideValidating ||
      this == SessionState.ending;
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
  /// Source and metadata structures are formally validated.
  METADATA_VALID,

  /// Validated with automated test evidence in clean container environment.
  VERIFIED,

  /// Validated with automated test evidence on Android Emulator.
  EMULATOR_VERIFIED,

  /// Validated with automated test evidence on physical target device.
  DEVICE_VERIFIED,

  /// Implemented in native/Dart code but awaiting platform runtime execution.
  IMPLEMENTED_UNVERIFIED,

  /// Requires physical device hardware features (e.g. OEM battery optimization, hardware clock benchmark).
  HARDWARE_REQUIRED,

  /// Requires external developer account, provisioning profile, or vendor entitlement (e.g. Apple FamilyControls).
  EXTERNAL_ENTITLEMENT_REQUIRED,

  /// OS sandbox or platform guidelines strictly prohibit this capability (e.g. iOS accessibility app switching).
  PLATFORM_UNSUPPORTED,

  /// Automated verification failed.
  FAILED,
}
