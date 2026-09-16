import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/models/daily_limit.dart';
import '../../engine/daily_limit_tracker.dart';

/// Screen for configuring and monitoring daily application and device usage limits.
class DailyLimitsScreen extends StatefulWidget {
  final DailyLimitTracker limitTracker;

  const DailyLimitsScreen({super.key, required this.limitTracker});

  @override
  State<DailyLimitsScreen> createState() => _DailyLimitsScreenState();
}

class _DailyLimitsScreenState extends State<DailyLimitsScreen> {
  late List<DailyLimit> _limits;

  @override
  void initState() {
    super.initState();
    _loadSampleLimitsIfEmpty();
  }

  void _loadSampleLimitsIfEmpty() {
    _limits = widget.limitTracker.limits;
    if (_limits.isEmpty) {
      final samples = [
        const DailyLimit(
          id: 'limit_1',
          packageName: 'com.instagram.android',
          appName: 'Instagram',
          limitMinutes: 45,
          usedMinutes: 32,
        ),
        const DailyLimit(
          id: 'limit_2',
          packageName: 'com.google.android.youtube',
          appName: 'YouTube',
          limitMinutes: 60,
          usedMinutes: 58,
        ),
        const DailyLimit(
          id: 'limit_3',
          packageName: 'com.zhiliaoapp.musically',
          appName: 'TikTok',
          limitMinutes: 30,
          usedMinutes: 30,
        ),
      ];
      widget.limitTracker.setLimits(samples);
      _limits = samples;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily App Limits'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppConstants.primary,
        onPressed: () => _showAddLimitDialog(context),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Limit',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Device-wide Screen Time Card
          Card(
            color: AppConstants.primaryDark.withOpacity(0.25),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppConstants.primary, width: 1.2),
            ),
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.pie_chart_outline,
                          color: AppConstants.accent, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Total Device Screen Time Limit',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: 0.65,
                    backgroundColor: AppConstants.darkCard,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppConstants.accent),
                    minHeight: 8,
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Used: 2h 36m',
                          style: TextStyle(
                              color: AppConstants.textSecondaryDark,
                              fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Limit: 4h 00m',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'App Limits',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 12),

          ..._limits.map((limit) {
            final isExhausted = limit.isExhausted;
            final isWarning = !isExhausted && limit.progressFraction >= 0.8;
            final color = isExhausted
                ? AppConstants.error
                : isWarning
                    ? AppConstants.warning
                    : AppConstants.accent;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              limit.appName,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isExhausted
                                    ? 'LIMIT REACHED'
                                    : '${limit.remainingMinutes}m left',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: color),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: limit.progressFraction,
                          backgroundColor: AppConstants.darkBorder,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${limit.usedMinutes} of ${limit.limitMinutes} min used today',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppConstants.textSecondaryDark),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(limit.progressFraction * 100).toInt()}%',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: color),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showAddLimitDialog(BuildContext context) {
    final nameController = TextEditingController();
    int minutes = 30;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppConstants.darkCard,
            title: const Text('Set Application Limit',
                style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                      labelText: 'App Name', hintText: 'e.g. Reddit'),
                ),
                const SizedBox(height: 16),
                Text('Daily Allowance: $minutes min',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                Slider(
                  value: minutes.toDouble(),
                  min: 5,
                  max: 180,
                  divisions: 35,
                  onChanged: (val) =>
                      setDialogState(() => minutes = val.toInt()),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isNotEmpty) {
                    final newLimit = DailyLimit(
                      id: 'limit_${DateTime.now().millisecondsSinceEpoch}',
                      packageName:
                          'custom.${nameController.text.trim().toLowerCase()}',
                      appName: nameController.text.trim(),
                      limitMinutes: minutes,
                    );
                    setState(() {
                      _limits.add(newLimit);
                      widget.limitTracker.setLimits(_limits);
                    });
                    Navigator.of(ctx).pop();
                  }
                },
                child: const Text('Save Limit'),
              ),
            ],
          );
        },
      ),
    );
  }
}
