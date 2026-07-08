class TaskTimerState {
  final String? taskId;
  final int totalSeconds;
  final int remainingSeconds;
  final bool isRunning;
  final bool timedOut;
  final DateTime? endsAt;

  const TaskTimerState({
    this.taskId,
    this.totalSeconds = 0,
    this.remainingSeconds = 0,
    this.isRunning = false,
    this.timedOut = false,
    this.endsAt,
  });

  int get effectiveRemaining {
    if (timedOut) return 0;
    if (!isRunning || endsAt == null) return remainingSeconds;
    final seconds = endsAt!.difference(DateTime.now()).inSeconds;
    return seconds.clamp(0, totalSeconds);
  }

  bool get isActive =>
      taskId != null && !timedOut && effectiveRemaining > 0;

  bool get isFinished =>
      timedOut || (taskId != null && effectiveRemaining <= 0 && !isRunning);

  double get progress {
    if (totalSeconds == 0) return timedOut ? 1.0 : 0;
    if (timedOut) return 1.0;
    return 1 - (effectiveRemaining / totalSeconds);
  }

  TaskTimerState copyWith({
    String? taskId,
    int? totalSeconds,
    int? remainingSeconds,
    bool? isRunning,
    bool? timedOut,
    DateTime? endsAt,
    bool clearTask = false,
    bool clearEndsAt = false,
  }) {
    return TaskTimerState(
      taskId: clearTask ? null : (taskId ?? this.taskId),
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      timedOut: timedOut ?? this.timedOut,
      endsAt: clearEndsAt ? null : (endsAt ?? this.endsAt),
    );
  }
}
