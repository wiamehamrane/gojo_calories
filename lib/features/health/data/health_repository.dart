import '../../../core/network/api_client.dart';
import 'models/health_sync_data.dart';

class HealthRepository {
  Future<void> uploadToday(HealthSyncData data) async {
    if (!data.isConnected) return;
    final now = DateTime.now();
    final date =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    await ApiClient.instance.put(
      'stats/health',
      data: {
        'date': date,
        if (data.stepsToday != null) 'steps': data.stepsToday,
        if (data.activeCaloriesToday != null)
          'active_calories': data.activeCaloriesToday,
        if (data.weightKg != null) 'weight_kg': data.weightKg,
      },
    );
  }
}
