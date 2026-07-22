import '../../../../core/network/api_client.dart';

class ShareRepository {
  Future<Map<String, dynamic>> getMyShares() async {
    final res = await ApiClient.instance.get('shares/me');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> invite({
    String? email,
    required List<String> scopes,
  }) async {
    final res = await ApiClient.instance.post(
      'shares/invite',
      data: {
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        'scopes': scopes,
      },
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> preview(String token) async {
    final res = await ApiClient.instance.get(
      'shares/preview',
      queryParameters: {'token': token},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> accept(String token) async {
    final res = await ApiClient.instance.post(
      'shares/accept',
      data: {'token': token},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> decline(String token) async {
    await ApiClient.instance.post('shares/decline', data: {'token': token});
  }

  Future<void> revoke(String shareId) async {
    await ApiClient.instance.delete('shares/$shareId');
  }

  Future<Map<String, dynamic>> getClientStats(
    String ownerId, {
    required String date,
    required int tzOffset,
  }) async {
    final res = await ApiClient.instance.get(
      'shares/$ownerId/stats',
      queryParameters: {'date': date, 'tz_offset': tzOffset},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<List<Map<String, dynamic>>> getClientHistory(
    String ownerId, {
    required String date,
    required int tzOffset,
  }) async {
    final res = await ApiClient.instance.get(
      'shares/$ownerId/history',
      queryParameters: {'date': date, 'tz_offset': tzOffset},
    );
    return (res.data as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getClientExercises(
    String ownerId, {
    required String date,
    required int tzOffset,
  }) async {
    final res = await ApiClient.instance.get(
      'shares/$ownerId/exercises',
      queryParameters: {'date': date, 'tz_offset': tzOffset},
    );
    return (res.data as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getClientProgressPhotos(
    String ownerId, {
    String? date,
  }) async {
    final res = await ApiClient.instance.get(
      'shares/$ownerId/progress-photos',
      queryParameters: {
        if (date != null && date.isNotEmpty) 'date': date,
      },
    );
    return (res.data as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> getClientHealth(
    String ownerId, {
    required String date,
  }) async {
    final res = await ApiClient.instance.get(
      'shares/$ownerId/health',
      queryParameters: {'date': date},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }
}
