import 'dart:io';

import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class EventsRepository {
  final Dio _dio = ApiClient.instance;

  Future<List<dynamic>> getEvents({
    String? search,
    String? eventType,
  }) async {
    final queryParams = <String, dynamic>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (eventType != null && eventType.isNotEmpty) {
      queryParams['event_type'] = eventType;
    }
    final res = await _dio.get('events', queryParameters: queryParams);
    return res.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getEvent(String eventId) async {
    final res = await _dio.get('events/$eventId');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createEvent(Map<String, dynamic> eventData) async {
    final res = await _dio.post('events', data: eventData);
    return res.data as Map<String, dynamic>;
  }

  Future<void> uploadEventImage(String eventId, File imageFile) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        imageFile.path,
        filename: 'event_image.jpg',
      ),
    });
    await _dio.post('events/$eventId/image', data: formData);
  }

  Future<void> joinEvent(String eventId) async {
    await _dio.post('events/$eventId/join');
  }
}
