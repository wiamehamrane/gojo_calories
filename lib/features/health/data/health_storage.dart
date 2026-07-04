import 'package:shared_preferences/shared_preferences.dart';

import 'models/health_sync_data.dart';

class HealthStorage {
  static const _connectedKey = 'health_connected';
  static const _stepsKey = 'health_steps_today';
  static const _activeCaloriesKey = 'health_active_calories_today';
  static const _weightKey = 'health_weight_kg';
  static const _lastSyncKey = 'health_last_sync_at';

  Future<HealthSyncData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncRaw = prefs.getString(_lastSyncKey);

    return HealthSyncData(
      isConnected: prefs.getBool(_connectedKey) ?? false,
      stepsToday: prefs.getInt(_stepsKey),
      activeCaloriesToday: prefs.getInt(_activeCaloriesKey),
      weightKg: prefs.getDouble(_weightKey),
      lastSyncAt:
          lastSyncRaw == null ? null : DateTime.tryParse(lastSyncRaw),
    );
  }

  Future<void> save(HealthSyncData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_connectedKey, data.isConnected);

    if (data.stepsToday != null) {
      await prefs.setInt(_stepsKey, data.stepsToday!);
    } else {
      await prefs.remove(_stepsKey);
    }

    if (data.activeCaloriesToday != null) {
      await prefs.setInt(_activeCaloriesKey, data.activeCaloriesToday!);
    } else {
      await prefs.remove(_activeCaloriesKey);
    }

    if (data.weightKg != null) {
      await prefs.setDouble(_weightKey, data.weightKg!);
    } else {
      await prefs.remove(_weightKey);
    }

    if (data.lastSyncAt != null) {
      await prefs.setString(_lastSyncKey, data.lastSyncAt!.toIso8601String());
    } else {
      await prefs.remove(_lastSyncKey);
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_connectedKey);
    await prefs.remove(_stepsKey);
    await prefs.remove(_activeCaloriesKey);
    await prefs.remove(_weightKey);
    await prefs.remove(_lastSyncKey);
  }
}
