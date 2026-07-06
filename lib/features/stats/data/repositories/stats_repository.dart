import '../../../../core/network/api_client.dart';

class StatsRepository {
  final _dio = ApiClient.instance;

  Future<List<dynamic>> getDailyStats({
    required String date,
    required int tzOffset,
  }) async {
    final res = await _dio.get(
      'stats/',
      queryParameters: {'date': date, 'tz_offset': tzOffset},
    );
    return res.data as List<dynamic>? ?? [];
  }

  Future<int> getStreak({required int tzOffset}) async {
    final res = await _dio.get(
      'stats/streak',
      queryParameters: {'tz_offset': tzOffset},
    );
    if (res.statusCode == 200) {
      return res.data['streak'] as int? ?? 0;
    }
    return 0;
  }

  Future<List<dynamic>> getHistory({
    required String date,
    required int tzOffset,
  }) async {
    final res = await _dio.get(
      'stats/history',
      queryParameters: {'date': date, 'tz_offset': tzOffset},
    );
    return res.data as List<dynamic>? ?? [];
  }

  Future<List<dynamic>> getWeeklyStats({
    required String localToday,
    required int tzOffset,
  }) async {
    final res = await _dio.get(
      'stats/weekly',
      queryParameters: {'local_today': localToday, 'tz_offset': tzOffset},
    );
    return res.data as List<dynamic>? ?? [];
  }

  Future<List<dynamic>> getCalendarProgress({
    required String endDate,
    required int days,
    required int tzOffset,
  }) async {
    final res = await _dio.get(
      'stats/calendar-progress',
      queryParameters: {
        'end_date': endDate,
        'days': days,
        'tz_offset': tzOffset,
      },
    );
    return res.data as List<dynamic>? ?? [];
  }

  Future<List<dynamic>> getWeighIns() async {
    final res = await _dio.get('stats/progress/weigh-ins');
    return res.data as List<dynamic>? ?? [];
  }
}
