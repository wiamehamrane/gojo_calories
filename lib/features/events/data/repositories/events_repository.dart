import 'dart:io';

import 'package:dio/dio.dart';
import '../../../../core/config/env_config.dart';
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

  /// AI-powered search: sends a keyword, sport name, or free-form prompt
  /// to the backend, which ranks upcoming events via OpenAI.
  Future<List<dynamic>> aiSearchEvents(String query) async {
    final res = await _dio.post('events/search/ai', data: {'query': query});
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

  /// Events created by the current user (upcoming and past).
  Future<List<dynamic>> getMyEvents() async {
    final res = await _dio.get('events/mine');
    return res.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> updateEvent(
    String eventId,
    Map<String, dynamic> updates,
  ) async {
    final res = await _dio.patch('events/$eventId', data: updates);
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteEvent(String eventId) async {
    await _dio.delete('events/$eventId');
  }

  /// Uploads the event cover image. Returns the stored image URL.
  Future<String> uploadEventImage(String eventId, File imageFile) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        imageFile.path,
        filename: 'event_image.jpg',
      ),
    });
    final res = await _dio.post('events/$eventId/image', data: formData);
    final data = res.data as Map<String, dynamic>;
    final url = data['image_url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('Image upload did not return a URL');
    }
    return EnvConfig.resolveMediaUrl(url);
  }

  Future<void> joinEvent(String eventId) async {
    await _dio.post('events/$eventId/join');
  }
}
