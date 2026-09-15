import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../persistence/settings_repository.dart';

/// Screen for managing application preferences, themes, data backup/restore, and privacy deletion.
class SettingsScreen extends StatefulWidget {
  final SettingsRepository settingsRepository;
  final ValueChanged<ThemeMode> onThemeChanged;

  const SettingsScreen({
    super.key,
    required this.settingsRepository,
    required this.onThemeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _themeMode = 'dark';
  bool _haptics = true;
  bool _notifications = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final theme = await widget.settingsRepository.getThemeMode();
    final haptics = await widget.settingsRepository.areHapticsEnabled();
    final notifs = await widget.settingsRepository.areNotificationsEnabled();

    setState(() {
      _themeMode = theme;
      _haptics = haptics;
      _notifications = notifs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Privacy'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Theme Section
          const Text('Appearance',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                RadioListTile<String>(
                  value: 'dark',
                  groupValue: _themeMode,
                  activeColor: AppConstants.primary,
                  title: const Text('Obsidian Dark (Default)',
                      style: TextStyle(color: Colors.white)),
                  subtitle: const Text(
                      'Tailored for OLED panels and deep focus',
                      style: TextStyle(
                          color: AppConstants.textSecondaryDark, fontSize: 12)),
                  onChanged: (val) async {
                    if (val != null) {
                      await widget.settingsRepository.setThemeMode(val);
                      widget.onThemeChanged(ThemeMode.dark);
                      setState(() => _themeMode = val);
                    }
                  },
                ),
                const Divider(height: 1, color: AppConstants.darkBorder),
                RadioListTile<String>(
                  value: 'light',
                  groupValue: _themeMode,
                  activeColor: AppConstants.primary,
                  title: const Text('Crisp Light',
                      style: TextStyle(color: Colors.white)),
                  subtitle: const Text('High-contrast daytime presentation',
                      style: TextStyle(
                          color: AppConstants.textSecondaryDark, fontSize: 12)),
                  onChanged: (val) async {
                    if (val != null) {
                      await widget.settingsRepository.setThemeMode(val);
                      widget.onThemeChanged(ThemeMode.light);
                      setState(() => _themeMode = val);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Feedback Section
          const Text('Feedback & Alerts',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: _notifications,
                  activeColor: AppConstants.primary,
                  title: const Text('Session Notifications',
                      style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Live countdown in notification bar',
                      style: TextStyle(
                          color: AppConstants.textSecondaryDark, fontSize: 12)),
                  onChanged: (val) async {
                    await widget.settingsRepository
                        .setNotificationsEnabled(val);
                    setState(() => _notifications = val);
                  },
                ),
                const Divider(height: 1, color: AppConstants.darkBorder),
                SwitchListTile(
                  value: _haptics,
                  activeColor: AppConstants.primary,
                  title: const Text('Haptic Feedback',
                      style: TextStyle(color: Colors.white)),
                  subtitle: const Text(
                      'Subtle vibrations when starting or ending focus',
                      style: TextStyle(
                          color: AppConstants.textSecondaryDark, fontSize: 12)),
                  onChanged: (val) async {
                    await widget.settingsRepository.setHapticsEnabled(val);
                    setState(() => _haptics = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Data Management
          const Text('Data & Backups',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.download,
                      color: AppConstants.primaryLight),
                  title: const Text('Export Configuration',
                      style: TextStyle(color: Colors.white)),
                  subtitle: const Text(
                      'Copy JSON backup of profiles and schedules to clipboard',
                      style: TextStyle(
                          color: AppConstants.textSecondaryDark, fontSize: 12)),
                  onTap: () async {
                    final json =
                        await widget.settingsRepository.exportBackupJson();
                    await Clipboard.setData(ClipboardData(text: json));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Configuration copied to clipboard!')),
                      );
                    }
                  },
                ),
                const Divider(height: 1, color: AppConstants.darkBorder),
                ListTile(
                  leading: const Icon(Icons.upload, color: AppConstants.accent),
                  title: const Text('Import Backup',
                      style: TextStyle(color: Colors.white)),
                  subtitle: const Text('Restore profiles from clipboard JSON',
                      style: TextStyle(
                          color: AppConstants.textSecondaryDark, fontSize: 12)),
                  onTap: () => _showImportDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Privacy & Reset
          const Text('Privacy & Reset',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading:
                  const Icon(Icons.delete_forever, color: AppConstants.error),
              title: const Text('Clear All User Data',
                  style: TextStyle(
                      color: AppConstants.error, fontWeight: FontWeight.w600)),
              subtitle: const Text(
                  'Permanently wipes local database, audit logs, and custom PINs',
                  style: TextStyle(
                      color: AppConstants.textSecondaryDark, fontSize: 12)),
              onTap: () => _confirmResetData(context),
            ),
          ),
          const SizedBox(height: 32),

          // App Info
          const Center(
            child: Column(
              children: [
                Text(
                  '${AppConstants.appName} v${AppConstants.appVersion}',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 13),
                ),
                SizedBox(height: 4),
                Text(
                  'Privacy-first • Zero network analytics • 100% Offline',
                  style: TextStyle(
                      color: AppConstants.textSecondaryDark, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.darkCard,
        title: const Text('Import JSON Backup',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration:
              const InputDecoration(hintText: 'Paste backup JSON here...'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final ok = await widget.settingsRepository
                  .importBackupJson(controller.text.trim());
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(ok
                          ? 'Backup restored successfully!'
                          : 'Invalid backup JSON format.')),
                );
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _confirmResetData(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.darkCard,
        title: const Text('Wipe All Data?',
            style: TextStyle(color: AppConstants.error)),
        content: const Text(
          'This action permanently clears all stored sessions, profiles, schedules, daily limits, and PINs. It cannot be undone.',
          style: TextStyle(color: AppConstants.textSecondaryDark),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppConstants.error),
            onPressed: () async {
              await widget.settingsRepository.clearAllUserData();
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('All data has been reset to defaults.')),
                );
              }
            },
            child: const Text('Wipe All Data'),
          ),
        ],
      ),
    );
  }
}
