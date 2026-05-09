import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gojocalories/core/network/api_client.dart';
import 'package:dio/dio.dart';
import '../../domain/models/event.dart';

class EventsNotifier extends Notifier<AsyncValue<List<Event>>> {
  @override
  AsyncValue<List<Event>> build() {
    fetchEvents();
    return const AsyncValue.loading();
  }

  Future<void> fetchEvents({String? search, String? type}) async {
    state = const AsyncValue.loading();
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (type != null && type.isNotEmpty) queryParams['event_type'] = type;

      final response = await ApiClient.instance.get(
        'events',
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data;
      final events = data.map((e) => Event.fromJson(e)).toList();
      state = AsyncValue.data(events);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Event?> getEvent(String eventId) async {
    try {
      final response = await ApiClient.instance.get('events/$eventId');
      return Event.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<Event?> createEvent(Map<String, dynamic> eventData) async {
    try {
      final response = await ApiClient.instance.post('events', data: eventData);
      await fetchEvents();
      return Event.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  Future<bool> uploadEventImage(String eventId, File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'event_image.jpg',
        ),
      });
      await ApiClient.instance.post('events/$eventId/image', data: formData);
      await fetchEvents();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> joinEvent(String eventId) async {
    try {
      await ApiClient.instance.post('events/$eventId/join');
      await fetchEvents();
      return true;
    } catch (e) {
      return false;
    }
  }
}

final eventsProvider = NotifierProvider<EventsNotifier, AsyncValue<List<Event>>>(() {
  return EventsNotifier();
});
