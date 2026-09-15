import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/models/audit_entry.dart';
import '../../persistence/audit_repository.dart';

/// Screen presenting the immutable audit journal of past sessions, breaks, overrides, and security alerts.
class HistoryScreen extends StatefulWidget {
  final AuditRepository auditRepository;

  const HistoryScreen({super.key, required this.auditRepository});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<AuditEntry> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final list = await widget.auditRepository.getAllLogs();
    setState(() {
      _logs = list;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session History & Audit Log'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? const Center(
                  child: Text(
                    'No session history recorded yet.',
                    style: TextStyle(color: AppConstants.textSecondaryDark),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    final dateFormatted =
                        DateFormat('MMM d, h:mm a').format(log.timestamp);
                    final isTamper = log.eventType == 'tamper_alert';
                    final isOverride = log.eventType == 'override';
                    final isComplete = log.eventType == 'session_complete';

                    final iconColor = isTamper
                        ? AppConstants.error
                        : isOverride
                            ? AppConstants.warning
                            : isComplete
                                ? AppConstants.accent
                                : AppConstants.primary;

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: iconColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isTamper
                                    ? Icons.security_update_warning
                                    : isOverride
                                        ? Icons.lock_open
                                        : isComplete
                                            ? Icons.check_circle_outline
                                            : Icons.event_note,
                                color: iconColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        log.eventType
                                            .toUpperCase()
                                            .replaceAll('_', ' '),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: iconColor,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        dateFormatted,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color:
                                                AppConstants.textSecondaryDark),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    log.description,
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
