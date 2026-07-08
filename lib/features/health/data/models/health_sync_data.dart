class HealthSyncData {
  final bool isConnected;
  final int? stepsToday;
  final int? activeCaloriesToday;
  final double? weightKg;
  final DateTime? lastSyncAt;

  const HealthSyncData({
    this.isConnected = false,
    this.stepsToday,
    this.activeCaloriesToday,
    this.weightKg,
    this.lastSyncAt,
  });

  HealthSyncData copyWith({
    bool? isConnected,
    int? stepsToday,
    int? activeCaloriesToday,
    double? weightKg,
    DateTime? lastSyncAt,
    bool clearSteps = false,
    bool clearActiveCalories = false,
    bool clearWeight = false,
    bool clearLastSync = false,
  }) {
    return HealthSyncData(
      isConnected: isConnected ?? this.isConnected,
      stepsToday: clearSteps ? null : (stepsToday ?? this.stepsToday),
      activeCaloriesToday: clearActiveCalories
          ? null
          : (activeCaloriesToday ?? this.activeCaloriesToday),
      weightKg: clearWeight ? null : (weightKg ?? this.weightKg),
      lastSyncAt: clearLastSync ? null : (lastSyncAt ?? this.lastSyncAt),
    );
  }
}
