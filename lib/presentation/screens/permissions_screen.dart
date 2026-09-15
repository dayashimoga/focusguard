import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/models/capability_matrix_entry.dart';
import '../../domain/models/enums.dart';
import '../../platform/capability_matrix.dart';
import '../../platform/platform_bridge.dart';

/// Screen displaying permission diagnostics, OS settings shortcuts, and the official capability matrix.
class PermissionsScreen extends StatefulWidget {
  final PlatformBridge platformBridge;

  const PermissionsScreen({super.key, required this.platformBridge});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  Map<String, dynamic> _capabilities = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshDiagnostics();
  }

  Future<void> _refreshDiagnostics() async {
    final caps = await widget.platformBridge.getCapabilities();
    setState(() {
      _capabilities = caps;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasUsage = _capabilities['hasUsageStatsPermission'] as bool? ?? false;
    final hasOverlay = _capabilities['hasOverlayPermission'] as bool? ?? false;
    final hasDnd = _capabilities['hasDndPermission'] as bool? ?? false;
    final hasAccessibility =
        _capabilities['hasAccessibilityPermission'] as bool? ?? false;
    final isDeviceOwner = _capabilities['isDeviceOwner'] as bool? ?? false;

    final matrix = CapabilityMatrix.getMatrix(
      isAndroid: _capabilities['platform'] != 'ios',
      hasUsageAccess: hasUsage,
      hasOverlay: hasOverlay,
      hasAccessibility: hasAccessibility,
      isDeviceOwner: isDeviceOwner,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions & Diagnostics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Diagnostics',
            onPressed: _refreshDiagnostics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Diagnostic Header Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.health_and_safety,
                                color: AppConstants.accent, size: 24),
                            SizedBox(width: 10),
                            Text('Enforcement Health',
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hasUsage && hasOverlay
                              ? 'Core enforcement is fully operational.'
                              : 'Action required: Grant necessary permissions below to enable app restriction.',
                          style: TextStyle(
                            fontSize: 13,
                            color: hasUsage && hasOverlay
                                ? AppConstants.accent
                                : AppConstants.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                const Text('Required Permissions',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 12),

                _buildPermissionTile(
                  title: 'Usage Access (Foreground Detection)',
                  subtitle:
                      'Permits FocusGuard to identify when restricted apps are launched.',
                  isGranted: hasUsage,
                  isRequired: true,
                  onFixPressed: () async {
                    await widget.platformBridge.requestUsageStatsPermission();
                  },
                ),
                const SizedBox(height: 10),

                _buildPermissionTile(
                  title: 'Display Over Other Apps (Overlay)',
                  subtitle:
                      'Allows displaying the fullscreen focus barrier over restricted applications.',
                  isGranted: hasOverlay,
                  isRequired: true,
                  onFixPressed: () async {
                    await widget.platformBridge.requestOverlayPermission();
                  },
                ),
                const SizedBox(height: 24),

                const Text('Optional Enhancements',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 12),

                _buildPermissionTile(
                  title: 'Do Not Disturb Policy Access',
                  subtitle:
                      'Mutes distracting notifications during Strict and Deep Focus sessions.',
                  isGranted: hasDnd,
                  isRequired: false,
                  onFixPressed: () async {
                    await widget.platformBridge.requestDndPermission();
                  },
                ),
                const SizedBox(height: 10),

                _buildPermissionTile(
                  title: 'Accessibility Service (Zero-Latency)',
                  subtitle:
                      'Optional pre-render interception for Deep Focus mode.',
                  isGranted: hasAccessibility,
                  isRequired: false,
                  onFixPressed: () async {
                    await widget.platformBridge.requestAccessibilitySettings();
                  },
                ),
                const SizedBox(height: 28),

                // Capability Matrix Section
                const Text('Platform Capability Matrix',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 12),

                ...matrix.map((entry) => _buildMatrixCard(entry)),
              ],
            ),
    );
  }

  Widget _buildPermissionTile({
    required String title,
    required String subtitle,
    required bool isGranted,
    required bool isRequired,
    required VoidCallback onFixPressed,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isGranted ? Icons.check_circle : Icons.error_outline,
              color: isGranted
                  ? AppConstants.accent
                  : (isRequired ? AppConstants.error : AppConstants.warning),
              size: 24,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppConstants.textSecondaryDark, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (!isGranted)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(60, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onPressed: onFixPressed,
                child: const Text('Grant', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatrixCard(CapabilityMatrixEntry entry) {
    Color statusColor;
    switch (entry.verified) {
      case VerificationClassification.VERIFIED:
      case VerificationClassification.DEVICE_VERIFIED:
      case VerificationClassification.EMULATOR_VERIFIED:
        statusColor = AppConstants.accent;
        break;
      case VerificationClassification.HARDWARE_REQUIRED:
        statusColor = AppConstants.warning;
        break;
      case VerificationClassification.PLATFORM_UNSUPPORTED:
      case VerificationClassification.FAILED:
        statusColor = AppConstants.error;
        break;
      case VerificationClassification.IMPLEMENTED_UNVERIFIED:
        statusColor = AppConstants.primaryLight;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.feature,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontSize: 14),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    entry.verified.name,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Android: ${entry.androidSupport}',
              style: const TextStyle(
                  fontSize: 12, color: AppConstants.textSecondaryDark),
            ),
            Text(
              'iOS: ${entry.iosSupport}',
              style: const TextStyle(
                  fontSize: 12, color: AppConstants.textSecondaryDark),
            ),
            const SizedBox(height: 4),
            Text(
              'Enforcement: ${entry.enforcementLevel}',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.primaryLight),
            ),
          ],
        ),
      ),
    );
  }
}
