import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/task_timer_state.dart';

class TimerSessionStorage {
  static const _keyV2 = 'active_task_timers_v2';
  static const _keyV1 = 'active_task_timer_v1';

  TaskTimerState? _decodeSession(Map<String, dynamic> map) {
    final taskId = map['task_id'] as String?;
    if (taskId == null || taskId.isEmpty) return null;

    return TaskTimerState(
      taskId: taskId,
      totalSeconds: map['total_seconds'] as int? ?? 0,
      remainingSeconds: map['remaining_seconds'] as int? ?? 0,
      isRunning: map['is_running'] as bool? ?? false,
      timedOut: map['timed_out'] as bool? ?? false,
      endsAt: map['ends_at'] != null
          ? DateTime.parse(map['ends_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> _encodeSession(TaskTimerState state) => {
        'task_id': state.taskId,
        'total_seconds': state.totalSeconds,
        'remaining_seconds': state.remainingSeconds,
        'is_running': state.isRunning,
        'timed_out': state.timedOut,
        'ends_at': state.endsAt?.toIso8601String(),
      };

  Future<Map<String, TaskTimerState>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();

    final rawV2 = prefs.getString(_keyV2);
    if (rawV2 != null && rawV2.isNotEmpty) {
      final list = jsonDecode(rawV2) as List<dynamic>;
      final sessions = <String, TaskTimerState>{};
      for (final item in list) {
        final session = _decodeSession(
          Map<String, dynamic>.from(item as Map),
        );
        if (session?.taskId != null) {
          sessions[session!.taskId!] = session;
        }
      }
      return sessions;
    }

    final rawV1 = prefs.getString(_keyV1);
    if (rawV1 == null || rawV1.isEmpty) return {};

    final session = _decodeSession(
      Map<String, dynamic>.from(jsonDecode(rawV1) as Map),
    );
    if (session?.taskId == null) return {};

    return {session!.taskId!: session};
  }

  Future<void> saveAll(Map<String, TaskTimerState> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    if (sessions.isEmpty) {
      await prefs.remove(_keyV2);
      await prefs.remove(_keyV1);
      return;
    }

    final encoded = sessions.values.map(_encodeSession).toList();
    await prefs.setString(_keyV2, jsonEncode(encoded));
    await prefs.remove(_keyV1);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyV2);
    await prefs.remove(_keyV1);
  }
}
