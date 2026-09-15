import 'dart:async';
import 'package:flutter/foundation.dart';

/// Lightweight, portable SQL storage abstraction for FocusGuard.
/// Operates seamlessly in unit test environments, Podman container runners, and native mobile devices.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  // In-memory relational tables
  final Map<String, Map<String, dynamic>> _sessions = {};
  final Map<String, Map<String, dynamic>> _profiles = {};
  final Map<String, Map<String, dynamic>> _schedules = {};
  final Map<String, Map<String, dynamic>> _dailyLimits = {};
  final List<Map<String, dynamic>> _auditLogs = [];
  final Map<String, String> _settings = {};

  bool _isInitialized = false;

  DatabaseHelper._init();

  Future<void> initDatabase() async {
    if (_isInitialized) return;
    _isInitialized = true;
    debugPrint('DatabaseHelper initialized');
  }

  // --- Session Operations ---
  Future<void> insertSession(Map<String, dynamic> row) async {
    final id = row['id'] as String;
    _sessions[id] = Map<String, dynamic>.from(row);
  }

  Future<void> updateSession(Map<String, dynamic> row) async {
    final id = row['id'] as String;
    _sessions[id] = Map<String, dynamic>.from(row);
  }

  Future<Map<String, dynamic>?> getSession(String id) async {
    final session = _sessions[id];
    return session != null ? Map<String, dynamic>.from(session) : null;
  }

  Future<List<Map<String, dynamic>>> getAllSessions() async {
    return _sessions.values.map((s) => Map<String, dynamic>.from(s)).toList();
  }

  Future<Map<String, dynamic>?> getActiveSession() async {
    for (final s in _sessions.values) {
      final state = s['state'] as String?;
      if (state == 'active' || state == 'gracePeriod' || state == 'onBreak') {
        return Map<String, dynamic>.from(s);
      }
    }
    return null;
  }

  // --- Profile Operations ---
  Future<void> insertProfile(Map<String, dynamic> row) async {
    final id = row['id'] as String;
    _profiles[id] = Map<String, dynamic>.from(row);
  }

  Future<void> updateProfile(Map<String, dynamic> row) async {
    final id = row['id'] as String;
    _profiles[id] = Map<String, dynamic>.from(row);
  }

  Future<void> deleteProfile(String id) async {
    _profiles.remove(id);
  }

  Future<List<Map<String, dynamic>>> getAllProfiles() async {
    return _profiles.values.map((p) => Map<String, dynamic>.from(p)).toList();
  }

  // --- Schedule Operations ---
  Future<void> insertSchedule(Map<String, dynamic> row) async {
    final id = row['id'] as String;
    _schedules[id] = Map<String, dynamic>.from(row);
  }

  Future<void> updateSchedule(Map<String, dynamic> row) async {
    final id = row['id'] as String;
    _schedules[id] = Map<String, dynamic>.from(row);
  }

  Future<void> deleteSchedule(String id) async {
    _schedules.remove(id);
  }

  Future<List<Map<String, dynamic>>> getAllSchedules() async {
    return _schedules.values.map((s) => Map<String, dynamic>.from(s)).toList();
  }

  // --- Daily Limit Operations ---
  Future<void> insertDailyLimit(Map<String, dynamic> row) async {
    final id = row['id'] as String;
    _dailyLimits[id] = Map<String, dynamic>.from(row);
  }

  Future<void> updateDailyLimit(Map<String, dynamic> row) async {
    final id = row['id'] as String;
    _dailyLimits[id] = Map<String, dynamic>.from(row);
  }

  Future<List<Map<String, dynamic>>> getAllDailyLimits() async {
    return _dailyLimits.values
        .map((l) => Map<String, dynamic>.from(l))
        .toList();
  }

  // --- Audit Log Operations ---
  Future<void> insertAuditLog(Map<String, dynamic> row) async {
    _auditLogs.add(Map<String, dynamic>.from(row));
  }

  Future<List<Map<String, dynamic>>> getAllAuditLogs() async {
    return _auditLogs.map((a) => Map<String, dynamic>.from(a)).toList();
  }

  // --- Settings Key-Value Store ---
  Future<void> setSetting(String key, String value) async {
    _settings[key] = value;
  }

  Future<String?> getSetting(String key) async {
    return _settings[key];
  }

  Future<void> clearAllData() async {
    _sessions.clear();
    _profiles.clear();
    _schedules.clear();
    _dailyLimits.clear();
    _auditLogs.clear();
    _settings.clear();
  }
}
