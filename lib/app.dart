import 'package:flutter/material.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'domain/models/app_info.dart';
import 'domain/models/focus_profile.dart';
import 'engine/daily_limit_tracker.dart';
import 'engine/focus_engine.dart';
import 'persistence/audit_repository.dart';
import 'persistence/profile_repository.dart';
import 'persistence/schedule_repository.dart';
import 'persistence/session_repository.dart';
import 'persistence/settings_repository.dart';
import 'platform/platform_bridge.dart';
import 'presentation/screens/app_selection_screen.dart';
import 'presentation/screens/daily_limits_screen.dart';
import 'presentation/screens/help_emergency_screen.dart';
import 'presentation/screens/history_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/override_config_screen.dart';
import 'presentation/screens/permissions_screen.dart';
import 'presentation/screens/profiles_screen.dart';
import 'presentation/screens/schedules_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/start_focus_screen.dart';
import 'presentation/screens/usage_insights_screen.dart';
import 'presentation/widgets/adaptive_scaffold.dart';

/// Root FocusGuard Application Widget.
class FocusGuardApp extends StatefulWidget {
  final FocusEngine focusEngine;
  final SessionRepository sessionRepository;
  final ProfileRepository profileRepository;
  final ScheduleRepository scheduleRepository;
  final AuditRepository auditRepository;
  final SettingsRepository settingsRepository;
  final DailyLimitTracker dailyLimitTracker;
  final PlatformBridge platformBridge;

  const FocusGuardApp({
    super.key,
    required this.focusEngine,
    required this.sessionRepository,
    required this.profileRepository,
    required this.scheduleRepository,
    required this.auditRepository,
    required this.settingsRepository,
    required this.dailyLimitTracker,
    required this.platformBridge,
  });

  @override
  State<FocusGuardApp> createState() => _FocusGuardAppState();
}

class _FocusGuardAppState extends State<FocusGuardApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  int _currentIndex = 0;
  List<FocusProfile> _cachedProfiles = [];
  List<AppInfo> _cachedApps = [];

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // Listen to audit stream and persist all events automatically
    widget.focusEngine.auditStream.listen((entry) {
      widget.auditRepository.logEvent(entry);
    });

    final themeStr = await widget.settingsRepository.getThemeMode();
    final profiles = await widget.profileRepository.getAllProfiles();
    final apps = await widget.platformBridge.getInstalledApps();

    setState(() {
      _themeMode = themeStr == 'light' ? ThemeMode.light : ThemeMode.dark;
      _cachedProfiles = profiles;
      _cachedApps = apps;
    });
  }

  void _onThemeChanged(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FocusGuard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: _buildHomeShell(context),
    );
  }

  Widget _buildHomeShell(BuildContext context) {
    final screens = [
      HomeScreen(
        focusEngine: widget.focusEngine,
        onNavigateToStart: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => StartFocusScreen(
                focusEngine: widget.focusEngine,
                profiles: _cachedProfiles,
              ),
            ),
          );
        },
        onNavigateToProfiles: () => setState(() => _currentIndex = 1),
        onNavigateToSchedules: () => setState(() => _currentIndex = 2),
        onNavigateToEmergency: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  HelpEmergencyScreen(focusEngine: widget.focusEngine),
            ),
          );
        },
      ),
      ProfilesScreen(profileRepository: widget.profileRepository),
      SchedulesScreen(scheduleRepository: widget.scheduleRepository),
      DailyLimitsScreen(limitTracker: widget.dailyLimitTracker),
      const UsageInsightsScreen(),
      _buildMoreMenuScreen(context),
    ];

    const destinations = [
      AdaptiveDestination(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        label: 'Home',
      ),
      AdaptiveDestination(
        icon: Icons.shield_outlined,
        selectedIcon: Icons.shield,
        label: 'Profiles',
      ),
      AdaptiveDestination(
        icon: Icons.schedule_outlined,
        selectedIcon: Icons.schedule,
        label: 'Schedules',
      ),
      AdaptiveDestination(
        icon: Icons.hourglass_bottom_outlined,
        selectedIcon: Icons.hourglass_bottom,
        label: 'Limits',
      ),
      AdaptiveDestination(
        icon: Icons.insights_outlined,
        selectedIcon: Icons.insights,
        label: 'Insights',
      ),
      AdaptiveDestination(
        icon: Icons.menu_outlined,
        selectedIcon: Icons.menu,
        label: 'More',
      ),
    ];

    return AdaptiveScaffold(
      selectedIndex: _currentIndex,
      onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
      destinations: destinations,
      body: screens[_currentIndex],
    );
  }

  Widget _buildMoreMenuScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tools & Management')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildMenuCard(
            title: 'Select Blocked Applications',
            subtitle:
                'Choose specific apps to restrict under your focus profiles',
            icon: Icons.apps,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AppSelectionScreen(
                    installedApps: _cachedApps,
                    initialBlockedPackages: _cachedProfiles.isNotEmpty
                        ? _cachedProfiles.first.blockedPackageNames.toSet()
                        : {},
                    onSaveBlockedPackages: (newSet) async {
                      if (_cachedProfiles.isNotEmpty) {
                        final updated = _cachedProfiles.first.copyWith(
                          blockedPackageNames: newSet.toList(),
                        );
                        await widget.profileRepository.updateProfile(updated);
                        final profiles =
                            await widget.profileRepository.getAllProfiles();
                        setState(() => _cachedProfiles = profiles);
                      }
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            title: 'Override & Safety Policy',
            subtitle:
                'Configure delayed cooldowns, recovery phrases, and security PINs',
            icon: Icons.lock_outline,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OverrideConfigScreen(
                    focusEngine: widget.focusEngine,
                    settingsRepository: widget.settingsRepository,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            title: 'Session History & Audit Log',
            subtitle:
                'Review completed sessions, override records, and tamper alerts',
            icon: Icons.history,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      HistoryScreen(auditRepository: widget.auditRepository),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            title: 'Permissions & Diagnostics',
            subtitle:
                'Inspect system capabilities, grant access, and view capability matrix',
            icon: Icons.verified_user_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      PermissionsScreen(platformBridge: widget.platformBridge),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            title: 'Settings & Privacy',
            subtitle:
                'Themes, notifications, local JSON backups, and data deletion',
            icon: Icons.settings_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    settingsRepository: widget.settingsRepository,
                    onThemeChanged: _onThemeChanged,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            title: 'Emergency Safety Exit',
            subtitle: 'Instant dialer bypass and lockout prevention procedures',
            icon: Icons.emergency_outlined,
            iconColor: AppConstants.emergency,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      HelpEmergencyScreen(focusEngine: widget.focusEngine),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (iconColor ?? AppConstants.primary).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon,
              color: iconColor ?? AppConstants.primaryLight, size: 22),
        ),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontSize: 15)),
        subtitle: Text(subtitle,
            style: const TextStyle(
                color: AppConstants.textSecondaryDark, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right,
            color: AppConstants.textSecondaryDark),
        onTap: onTap,
      ),
    );
  }
}
