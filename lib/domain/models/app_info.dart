import 'enums.dart';

/// Metadata representing an installed application on the device.
class AppInfo {
  final String packageName;
  final String appName;
  final AppCategory category;
  final bool isSystemApp;
  final bool isEssential;
  final int usageTodaySeconds;
  final int? dailyLimitSeconds;

  const AppInfo({
    required this.packageName,
    required this.appName,
    required this.category,
    this.isSystemApp = false,
    this.isEssential = false,
    this.usageTodaySeconds = 0,
    this.dailyLimitSeconds,
  });

  bool get hasLimit => dailyLimitSeconds != null && dailyLimitSeconds! > 0;

  bool get isLimitExhausted =>
      hasLimit && usageTodaySeconds >= dailyLimitSeconds!;

  double get limitProgress =>
      hasLimit ? (usageTodaySeconds / dailyLimitSeconds!).clamp(0.0, 1.0) : 0.0;

  AppInfo copyWith({
    String? packageName,
    String? appName,
    AppCategory? category,
    bool? isSystemApp,
    bool? isEssential,
    int? usageTodaySeconds,
    int? dailyLimitSeconds,
  }) {
    return AppInfo(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      category: category ?? this.category,
      isSystemApp: isSystemApp ?? this.isSystemApp,
      isEssential: isEssential ?? this.isEssential,
      usageTodaySeconds: usageTodaySeconds ?? this.usageTodaySeconds,
      dailyLimitSeconds: dailyLimitSeconds ?? this.dailyLimitSeconds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'appName': appName,
      'category': category.name,
      'isSystemApp': isSystemApp ? 1 : 0,
      'isEssential': isEssential ? 1 : 0,
      'usageTodaySeconds': usageTodaySeconds,
      'dailyLimitSeconds': dailyLimitSeconds,
    };
  }

  factory AppInfo.fromMap(Map<String, dynamic> map) {
    return AppInfo(
      packageName: map['packageName'] as String,
      appName: map['appName'] as String,
      category: AppCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => AppCategory.utility,
      ),
      isSystemApp: (map['isSystemApp'] as int? ?? 0) == 1,
      isEssential: (map['isEssential'] as int? ?? 0) == 1,
      usageTodaySeconds: (map['usageTodaySeconds'] as num?)?.toInt() ?? 0,
      dailyLimitSeconds: (map['dailyLimitSeconds'] as num?)?.toInt(),
    );
  }
}
