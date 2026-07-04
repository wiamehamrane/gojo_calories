import 'dart:io';

import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

import 'models/health_sync_data.dart';

class HealthService {
  HealthService({Health? health}) : _health = health ?? Health();

  final Health _health;
  bool _configured = false;

  static const _readTypes = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.WEIGHT,
  ];

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  bool get isAppleHealthPlatform => Platform.isIOS;
  bool get isHealthConnectPlatform => Platform.isAndroid;

  Future<bool> isPlatformAvailable() async {
    if (Platform.isIOS) return true;
    await _ensureConfigured();
    return _health.isHealthConnectAvailable();
  }

  Future<void> promptInstallHealthConnect() async {
    await _ensureConfigured();
    await _health.installHealthConnect();
  }

  Future<bool> connect() async {
    await _ensureConfigured();

    if (Platform.isAndroid) {
      final available = await _health.isHealthConnectAvailable();
      if (!available) {
        throw HealthServiceException(
          'Health Connect is not installed. Install it from the Play Store and try again.',
        );
      }

      final activityStatus = await Permission.activityRecognition.request();
      if (!activityStatus.isGranted) {
        throw HealthServiceException(
          'Activity recognition permission is required to read steps.',
        );
      }
    }

    final authorized = await _health.requestAuthorization(
      _readTypes,
      permissions: List.filled(_readTypes.length, HealthDataAccess.READ),
    );

    if (!authorized) {
      throw HealthServiceException(
        Platform.isIOS
            ? 'Apple Health permissions were not granted.'
            : 'Health Connect permissions were not granted.',
      );
    }

    return true;
  }

  Future<void> disconnect() async {
    await _ensureConfigured();
    if (Platform.isAndroid) {
      await _health.revokePermissions();
    }
  }

  Future<HealthSyncData> syncToday() async {
    await _ensureConfigured();

    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    final steps = await _health.getTotalStepsInInterval(midnight, now);
    final points = await _health.getHealthDataFromTypes(
      types: const [
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.WEIGHT,
      ],
      startTime: midnight,
      endTime: now,
    );

    var activeCalories = 0;
    double? latestWeightKg;
    DateTime? latestWeightAt;

    for (final point in points) {
      if (point.type == HealthDataType.ACTIVE_ENERGY_BURNED) {
        activeCalories += _numericValue(point).round();
      } else if (point.type == HealthDataType.WEIGHT) {
        final weight = _numericValue(point);
        if (latestWeightAt == null || point.dateTo.isAfter(latestWeightAt)) {
          latestWeightKg = weight;
          latestWeightAt = point.dateTo;
        }
      }
    }

    if (latestWeightKg == null) {
      final weightPoints = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.WEIGHT],
        startTime: now.subtract(const Duration(days: 30)),
        endTime: now,
      );
      for (final point in weightPoints) {
        final weight = _numericValue(point);
        if (latestWeightAt == null || point.dateTo.isAfter(latestWeightAt)) {
          latestWeightKg = weight;
          latestWeightAt = point.dateTo;
        }
      }
    }

    return HealthSyncData(
      isConnected: true,
      stepsToday: steps ?? 0,
      activeCaloriesToday: activeCalories,
      weightKg: latestWeightKg,
      lastSyncAt: now,
    );
  }

  double _numericValue(HealthDataPoint point) {
    final value = point.value;
    if (value is NumericHealthValue) {
      return value.numericValue.toDouble();
    }
    return 0;
  }
}

class HealthServiceException implements Exception {
  HealthServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
