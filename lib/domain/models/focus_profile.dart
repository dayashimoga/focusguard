import 'enums.dart';

/// Reusable Focus Profile defining app restrictions, strength, and categorization.
class FocusProfile {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final RestrictionStrength restrictionStrength;
  final List<String> blockedPackageNames;
  final List<String> allowedPackageNames;
  final List<AppCategory> blockedCategories;
  final bool isPreset;
  final bool isDefault;

  const FocusProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.restrictionStrength,
    this.blockedPackageNames = const [],
    this.allowedPackageNames = const [],
    this.blockedCategories = const [],
    this.isPreset = false,
    this.isDefault = false,
  });

  /// Built-in profile presets
  static List<FocusProfile> get defaultPresets => [
        const FocusProfile(
          id: 'preset_deep_work',
          name: 'Deep Work',
          description:
              'High-friction distraction blocking for intensive programming, writing, and analytical work.',
          iconName: 'psychology',
          restrictionStrength: RestrictionStrength.deepFocus,
          blockedCategories: [
            AppCategory.social,
            AppCategory.entertainment,
            AppCategory.gaming,
            AppCategory.shopping,
            AppCategory.news,
          ],
          allowedPackageNames: [
            'com.android.dialer',
            'com.google.android.dialer',
            'com.apple.mobilephone',
            'com.android.calculator2',
          ],
          isPreset: true,
          isDefault: true,
        ),
        const FocusProfile(
          id: 'preset_study',
          name: 'Study & Learning',
          description:
              'Blocks social feeds and video streaming while allowing educational and utility tools.',
          iconName: 'school',
          restrictionStrength: RestrictionStrength.focus,
          blockedCategories: [
            AppCategory.social,
            AppCategory.entertainment,
            AppCategory.gaming,
          ],
          isPreset: true,
        ),
        const FocusProfile(
          id: 'preset_bedtime',
          name: 'Bedtime & Wind Down',
          description:
              'Blocks late-night screen scrolling; only essential communication and emergency calls allowed.',
          iconName: 'bedtime',
          restrictionStrength: RestrictionStrength.strict,
          blockedCategories: [
            AppCategory.social,
            AppCategory.entertainment,
            AppCategory.gaming,
            AppCategory.shopping,
            AppCategory.news,
          ],
          isPreset: true,
        ),
        const FocusProfile(
          id: 'preset_digital_detox',
          name: 'Digital Detox',
          description:
              'Maximum disconnection from smartphone apps during weekends and family time.',
          iconName: 'forest',
          restrictionStrength: RestrictionStrength.deepFocus,
          blockedCategories: [
            AppCategory.social,
            AppCategory.entertainment,
            AppCategory.gaming,
            AppCategory.shopping,
            AppCategory.news,
            AppCategory.productivity,
          ],
          isPreset: true,
        ),
        const FocusProfile(
          id: 'preset_gentle',
          name: 'Gentle Awareness',
          description:
              'Subtle awareness reminders without hard blocking. Ideal for light focus sessions.',
          iconName: 'spa',
          restrictionStrength: RestrictionStrength.gentle,
          blockedCategories: [
            AppCategory.social,
          ],
          isPreset: true,
        ),
      ];

  FocusProfile copyWith({
    String? id,
    String? name,
    String? description,
    String? iconName,
    RestrictionStrength? restrictionStrength,
    List<String>? blockedPackageNames,
    List<String>? allowedPackageNames,
    List<AppCategory>? blockedCategories,
    bool? isPreset,
    bool? isDefault,
  }) {
    return FocusProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      restrictionStrength: restrictionStrength ?? this.restrictionStrength,
      blockedPackageNames: blockedPackageNames ?? this.blockedPackageNames,
      allowedPackageNames: allowedPackageNames ?? this.allowedPackageNames,
      blockedCategories: blockedCategories ?? this.blockedCategories,
      isPreset: isPreset ?? this.isPreset,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconName': iconName,
      'restrictionStrength': restrictionStrength.name,
      'blockedPackageNames': blockedPackageNames.join(','),
      'allowedPackageNames': allowedPackageNames.join(','),
      'blockedCategories': blockedCategories.map((c) => c.name).join(','),
      'isPreset': isPreset ? 1 : 0,
      'isDefault': isDefault ? 1 : 0,
    };
  }

  factory FocusProfile.fromMap(Map<String, dynamic> map) {
    final blockedPkgStr = map['blockedPackageNames'] as String? ?? '';
    final allowedPkgStr = map['allowedPackageNames'] as String? ?? '';
    final blockedCatStr = map['blockedCategories'] as String? ?? '';

    return FocusProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      iconName: map['iconName'] as String? ?? 'shield',
      restrictionStrength: RestrictionStrength.values.firstWhere(
        (e) => e.name == map['restrictionStrength'],
        orElse: () => RestrictionStrength.focus,
      ),
      blockedPackageNames:
          blockedPkgStr.isEmpty ? [] : blockedPkgStr.split(','),
      allowedPackageNames:
          allowedPkgStr.isEmpty ? [] : allowedPkgStr.split(','),
      blockedCategories: blockedCatStr.isEmpty
          ? []
          : blockedCatStr
              .split(',')
              .map((c) => AppCategory.values.firstWhere(
                    (cat) => cat.name == c,
                    orElse: () => AppCategory.utility,
                  ))
              .toList(),
      isPreset: (map['isPreset'] as int? ?? 0) == 1,
      isDefault: (map['isDefault'] as int? ?? 0) == 1,
    );
  }
}
