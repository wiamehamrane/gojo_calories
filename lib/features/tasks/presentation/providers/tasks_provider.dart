import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tasks_storage.dart';
import '../../data/timer_session_storage.dart';
import '../../domain/models/task_item.dart';
import '../../domain/models/task_timer_state.dart';

final tasksStorageProvider = Provider<TasksStorage>((ref) => TasksStorage());

final timerSessionStorageProvider =
    Provider<TimerSessionStorage>((ref) => TimerSessionStorage());

class TasksNotifier extends Notifier<List<TaskItem>> {
  @override
  List<TaskItem> build() {
    Future.microtask(_load);
    return [];
  }

  Future<void> _load() async {
    final tasks = await ref.read(tasksStorageProvider).loadAll();
    state = tasks;
  }

  Future<void> _persist() async {
    await ref.read(tasksStorageProvider).saveAll(state);
  }

  Future<TaskItem?> addTask({
    required String title,
    required int durationSeconds,
    String? description,
    DateTime? day,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return null;

    final trimmedDescription = description?.trim();
    final task = TaskItem(
      id: '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(99999)}',
      title: trimmed,
      description: trimmedDescription != null && trimmedDescription.isNotEmpty
          ? trimmedDescription
          : null,
      durationSeconds: durationSeconds,
      completed: false,
      day: TaskItem.dateOnly(day ?? DateTime.now()),
      createdAt: DateTime.now(),
    );

    state = [...state, task];
    await _persist();
    return task;
  }

  Future<void> completeTask(String id) async {
    ref.read(taskTimerProvider.notifier).stopIfTask(id);
    state = [
      for (final task in state)
        if (task.id == id)
          task.copyWith(completed: true, completedAt: DateTime.now())
        else
          task,
    ];
    await _persist();
  }

  Future<void> toggleComplete(String id) async {
    final task = state.where((t) => t.id == id).firstOrNull;
    if (task != null && !task.completed) {
      ref.read(taskTimerProvider.notifier).stopIfTask(id);
    }
    state = [
      for (final task in state)
        if (task.id == id)
          task.completed
              ? task.copyWith(completed: false, clearCompletedAt: true)
              : task.copyWith(completed: true, completedAt: DateTime.now())
        else
          task,
    ];
    await _persist();
  }

  Future<void> deleteTask(String id) async {
    ref.read(taskTimerProvider.notifier).stopIfTask(id);
    state = state.where((t) => t.id != id).toList();
    await _persist();
  }
}

final tasksProvider = NotifierProvider<TasksNotifier, List<TaskItem>>(
  TasksNotifier.new,
);

class DailyProgress {
  final int completed;
  final int total;

  const DailyProgress({required this.completed, required this.total});

  double get ratio => total == 0 ? 0 : completed / total;
}

final todayTasksProvider = Provider<List<TaskItem>>((ref) {
  final tasks = ref.watch(tasksProvider);
  final today = TaskItem.dateOnly(DateTime.now());
  final list = tasks.where((t) => t.isOnDay(today)).toList(growable: false);
  return [...list]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
});

final todayProgressProvider = Provider<DailyProgress>((ref) {
  final tasks = ref.watch(tasksProvider);
  final today = TaskItem.dateOnly(DateTime.now());
  var completed = 0;
  var total = 0;
  for (final task in tasks) {
    if (!task.isOnDay(today)) continue;
    total++;
    if (task.completed) completed++;
  }
  return DailyProgress(completed: completed, total: total);
});

class ActiveTaskEntry {
  final TaskItem task;
  final TaskTimerState timer;

  const ActiveTaskEntry({required this.task, required this.timer});
}

final activeTaskEntriesProvider = Provider<List<ActiveTaskEntry>>((ref) {
  final timers = ref.watch(taskTimerProvider);
  final tasks = ref.watch(tasksProvider);
  final entries = <ActiveTaskEntry>[];

  for (final timer in timers.values) {
    if (!timer.isActive) continue;
    final task = tasks.where((t) => t.id == timer.taskId).firstOrNull;
    if (task == null || task.completed) continue;
    entries.add(ActiveTaskEntry(task: task, timer: timer));
  }

  entries.sort((a, b) => a.task.createdAt.compareTo(b.task.createdAt));
  return entries;
});

final taskTimerForProvider =
    Provider.family<TaskTimerState?, String>((ref, taskId) {
  return ref.watch(taskTimerProvider)[taskId];
});

class TaskTimerNotifier extends Notifier<Map<String, TaskTimerState>> {
  Timer? _timer;

  @override
  Map<String, TaskTimerState> build() {
    Future.microtask(_restore);
    ref.onDispose(_cancelTicker);
    return const {};
  }

  TaskTimerState? timerFor(String taskId) => state[taskId];

  void _cancelTicker() {
    _timer?.cancel();
    _timer = null;
  }

  bool _hasRunningTimers() {
    return state.values.any((timer) => timer.isRunning);
  }

  void _ensureTicker() {
    if (_hasRunningTimers()) {
      _timer ??= Timer.periodic(
        const Duration(seconds: 1),
        (_) => _syncFromClock(),
      );
    } else {
      _cancelTicker();
    }
  }

  Future<void> _restore() async {
    final saved = await ref.read(timerSessionStorageProvider).loadAll();
    if (saved.isEmpty) return;

    final restored = <String, TaskTimerState>{};
    for (final entry in saved.entries) {
      var timer = entry.value;
      if (timer.isRunning && timer.endsAt != null) {
        final remaining = timer.effectiveRemaining;
        if (remaining <= 0) {
          timer = timer.copyWith(
            remainingSeconds: 0,
            isRunning: false,
            timedOut: true,
            clearEndsAt: true,
          );
        } else {
          timer = timer.copyWith(remainingSeconds: remaining);
        }
      }
      if (timer.isActive || timer.timedOut) {
        restored[entry.key] = timer;
      }
    }

    state = restored;
    _ensureTicker();
    await _persistSessions();
  }

  Future<void> _persistSessions() async {
    await ref.read(timerSessionStorageProvider).saveAll(state);
  }

  void _syncFromClock() {
    if (state.isEmpty) {
      _cancelTicker();
      return;
    }

    var changed = false;
    final updated = <String, TaskTimerState>{};

    for (final entry in state.entries) {
      var timer = entry.value;

      if (timer.isRunning && timer.endsAt != null) {
        final remaining = timer.effectiveRemaining;
        if (remaining <= 0) {
          timer = timer.copyWith(
            remainingSeconds: 0,
            isRunning: false,
            timedOut: true,
            clearEndsAt: true,
          );
        } else {
          timer = timer.copyWith(remainingSeconds: remaining);
        }
        changed = true;
      }

      if (timer.isActive || timer.timedOut) {
        updated[entry.key] = timer;
      }
    }

    if (changed || updated.length != state.length) {
      state = updated;
      _persistSessions();
    }

    _ensureTicker();
  }

  Future<void> start(TaskItem task) async {
    final existing = state[task.id];
    if (existing != null) {
      if (existing.timedOut) return;
      if (existing.effectiveRemaining > 0) {
        resumeExisting(task.id);
        return;
      }
    }

    final total = task.durationSeconds;
    state = {
      ...state,
      task.id: TaskTimerState(
        taskId: task.id,
        totalSeconds: total,
        remainingSeconds: total,
        isRunning: true,
        endsAt: DateTime.now().add(Duration(seconds: total)),
      ),
    };
    _ensureTicker();
    await _persistSessions();
  }

  Future<void> restart(TaskItem task) async {
    final total = task.durationSeconds;
    state = {
      ...state,
      task.id: TaskTimerState(
        taskId: task.id,
        totalSeconds: total,
        remainingSeconds: total,
        isRunning: true,
        timedOut: false,
        endsAt: DateTime.now().add(Duration(seconds: total)),
      ),
    };
    _ensureTicker();
    await _persistSessions();
  }

  void resumeExisting(String taskId) {
    final timer = state[taskId];
    if (timer == null) return;

    if (timer.isRunning) {
      _ensureTicker();
      _syncFromClock();
    }
  }

  Future<void> togglePause(String taskId) async {
    final timer = state[taskId];
    if (timer == null || timer.timedOut) return;

    TaskTimerState updated;
    if (timer.isRunning) {
      final remaining = timer.effectiveRemaining;
      updated = timer.copyWith(
        remainingSeconds: remaining,
        isRunning: false,
        clearEndsAt: true,
      );
    } else if (timer.remainingSeconds > 0) {
      updated = timer.copyWith(
        isRunning: true,
        endsAt: DateTime.now().add(
          Duration(seconds: timer.remainingSeconds),
        ),
      );
    } else {
      return;
    }

    state = {...state, taskId: updated};
    _ensureTicker();
    await _persistSessions();
  }

  Future<void> stopIfTask(String taskId) async {
    if (!state.containsKey(taskId)) return;

    final updated = Map<String, TaskTimerState>.from(state)..remove(taskId);
    state = updated;
    _ensureTicker();
    await _persistSessions();
  }

  Future<void> clearAll() async {
    _cancelTicker();
    state = const {};
    await ref.read(timerSessionStorageProvider).clear();
  }
}

final taskTimerProvider =
    NotifierProvider<TaskTimerNotifier, Map<String, TaskTimerState>>(
  TaskTimerNotifier.new,
);
