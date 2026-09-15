import 'dart:async';
import '../domain/models/daily_limit.dart';

/// Event payload when an app approaches or reaches its daily limit.
class DailyLimitAlertEvent {
  final DailyLimit limit;
  final bool isExhausted;
  final bool isWarning;

  const DailyLimitAlertEvent({
    required this.limit,
    required this.isExhausted,
    required this.isWarning,
  });
}

/// Tracks per-app and device-wide daily screen time limits.
class DailyLimitTracker {
  final Map<String, DailyLimit> _limits = {};
  final StreamController<DailyLimitAlertEvent> _alertController =
      StreamController<DailyLimitAlertEvent>.broadcast();

  Stream<DailyLimitAlertEvent> get onLimitAlert => _alertController.stream;

  List<DailyLimit> get limits => _limits.values.toList();

  void setLimits(List<DailyLimit> limitsList) {
    _limits.clear();
    for (final l in limitsList) {
      _limits[l.packageName] = l;
    }
  }

  void updateUsage(String packageName, int usedMinutes) {
    final current = _limits[packageName];
    if (current == null || !current.isEnabled) return;

    final wasExhausted = current.isExhausted;
    final updated = current.copyWith(usedMinutes: usedMinutes);
    _limits[packageName] = updated;

    final isNowExhausted = updated.isExhausted;
    final isWarning = !isNowExhausted && (updated.progressFraction >= 0.8);

    if (isNowExhausted && !wasExhausted) {
      _alertController.add(
        DailyLimitAlertEvent(
            limit: updated, isExhausted: true, isWarning: false),
      );
    } else if (isWarning) {
      _alertController.add(
        DailyLimitAlertEvent(
            limit: updated, isExhausted: false, isWarning: true),
      );
    }
  }

  DailyLimit? getLimitForPackage(String packageName) => _limits[packageName];

  void resetDailyUsage() {
    for (final entry in _limits.entries) {
      _limits[entry.key] = entry.value.copyWith(usedMinutes: 0);
    }
  }

  void dispose() {
    _alertController.close();
  }
}
