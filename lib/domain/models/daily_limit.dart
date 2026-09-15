/// Per-application or total device daily usage quota.
class DailyLimit {
  final String id;
  final String packageName;
  final String appName;
  final int limitMinutes;
  final int usedMinutes;
  final bool isDeviceWide;
  final bool isEnabled;

  const DailyLimit({
    required this.id,
    required this.packageName,
    required this.appName,
    required this.limitMinutes,
    this.usedMinutes = 0,
    this.isDeviceWide = false,
    this.isEnabled = true,
  });

  bool get isExhausted => isEnabled && usedMinutes >= limitMinutes;

  int get remainingMinutes =>
      (limitMinutes - usedMinutes).clamp(0, limitMinutes);

  double get progressFraction =>
      limitMinutes > 0 ? (usedMinutes / limitMinutes).clamp(0.0, 1.0) : 0.0;

  DailyLimit copyWith({
    String? id,
    String? packageName,
    String? appName,
    int? limitMinutes,
    int? usedMinutes,
    bool? isDeviceWide,
    bool? isEnabled,
  }) {
    return DailyLimit(
      id: id ?? this.id,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      limitMinutes: limitMinutes ?? this.limitMinutes,
      usedMinutes: usedMinutes ?? this.usedMinutes,
      isDeviceWide: isDeviceWide ?? this.isDeviceWide,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'packageName': packageName,
      'appName': appName,
      'limitMinutes': limitMinutes,
      'usedMinutes': usedMinutes,
      'isDeviceWide': isDeviceWide ? 1 : 0,
      'isEnabled': isEnabled ? 1 : 0,
    };
  }

  factory DailyLimit.fromMap(Map<String, dynamic> map) {
    return DailyLimit(
      id: map['id'] as String,
      packageName: map['packageName'] as String,
      appName: map['appName'] as String,
      limitMinutes: (map['limitMinutes'] as num).toInt(),
      usedMinutes: (map['usedMinutes'] as num?)?.toInt() ?? 0,
      isDeviceWide: (map['isDeviceWide'] as int? ?? 0) == 1,
      isEnabled: (map['isEnabled'] as int? ?? 1) == 1,
    );
  }
}
