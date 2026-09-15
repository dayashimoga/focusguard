import 'enums.dart';

/// Configuration governing exit friction and unlock security policies during focus sessions.
class OverridePolicy {
  final List<OverrideType> enabledOverrideTypes;
  final int cooldownSeconds;
  final String confirmationPhrase;
  final bool isPinRequired;
  final bool requireReason;
  final int maxOverridesPerDay;
  final int usedOverridesToday;

  const OverridePolicy({
    this.enabledOverrideTypes = const [
      OverrideType.emergency,
      OverrideType.delayedCooldown,
      OverrideType.confirmationPhrase,
    ],
    this.cooldownSeconds = 30,
    this.confirmationPhrase = 'I deliberately choose to exit focus',
    this.isPinRequired = false,
    this.requireReason = true,
    this.maxOverridesPerDay = 3,
    this.usedOverridesToday = 0,
  });

  bool get isQuotaExhausted => usedOverridesToday >= maxOverridesPerDay;

  int get remainingOverridesToday =>
      (maxOverridesPerDay - usedOverridesToday).clamp(0, maxOverridesPerDay);

  OverridePolicy copyWith({
    List<OverrideType>? enabledOverrideTypes,
    int? cooldownSeconds,
    String? confirmationPhrase,
    bool? isPinRequired,
    bool? requireReason,
    int? maxOverridesPerDay,
    int? usedOverridesToday,
  }) {
    return OverridePolicy(
      enabledOverrideTypes: enabledOverrideTypes ?? this.enabledOverrideTypes,
      cooldownSeconds: cooldownSeconds ?? this.cooldownSeconds,
      confirmationPhrase: confirmationPhrase ?? this.confirmationPhrase,
      isPinRequired: isPinRequired ?? this.isPinRequired,
      requireReason: requireReason ?? this.requireReason,
      maxOverridesPerDay: maxOverridesPerDay ?? this.maxOverridesPerDay,
      usedOverridesToday: usedOverridesToday ?? this.usedOverridesToday,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabledOverrideTypes': enabledOverrideTypes.map((t) => t.name).join(','),
      'cooldownSeconds': cooldownSeconds,
      'confirmationPhrase': confirmationPhrase,
      'isPinRequired': isPinRequired ? 1 : 0,
      'requireReason': requireReason ? 1 : 0,
      'maxOverridesPerDay': maxOverridesPerDay,
      'usedOverridesToday': usedOverridesToday,
    };
  }

  factory OverridePolicy.fromMap(Map<String, dynamic> map) {
    final typesStr = map['enabledOverrideTypes'] as String? ?? '';
    return OverridePolicy(
      enabledOverrideTypes: typesStr.isEmpty
          ? [OverrideType.emergency, OverrideType.delayedCooldown]
          : typesStr
              .split(',')
              .map((t) => OverrideType.values.firstWhere(
                    (type) => type.name == t,
                    orElse: () => OverrideType.emergency,
                  ))
              .toList(),
      cooldownSeconds: (map['cooldownSeconds'] as num?)?.toInt() ?? 30,
      confirmationPhrase: map['confirmationPhrase'] as String? ??
          'I deliberately choose to exit focus',
      isPinRequired: (map['isPinRequired'] as int? ?? 0) == 1,
      requireReason: (map['requireReason'] as int? ?? 1) == 1,
      maxOverridesPerDay: (map['maxOverridesPerDay'] as num?)?.toInt() ?? 3,
      usedOverridesToday: (map['usedOverridesToday'] as num?)?.toInt() ?? 0,
    );
  }
}
