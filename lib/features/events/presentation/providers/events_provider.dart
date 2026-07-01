import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/repository_providers.dart';
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
      final data = await ref.read(eventsRepositoryProvider).getEvents(
            search: search,
            eventType: type,
          );
      state = AsyncValue.data(data.map((e) => Event.fromJson(e)).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Event?> getEvent(String eventId) async {
    try {
      final data = await ref.read(eventsRepositoryProvider).getEvent(eventId);
      return Event.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  Future<Event?> createEvent(Map<String, dynamic> eventData) async {
    try {
      final data =
          await ref.read(eventsRepositoryProvider).createEvent(eventData);
      await fetchEvents();
      return Event.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  Future<bool> uploadEventImage(String eventId, File imageFile) async {
    try {
      await ref.read(eventsRepositoryProvider).uploadEventImage(
            eventId,
            imageFile,
          );
      await fetchEvents();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> joinEvent(String eventId) async {
    try {
      await ref.read(eventsRepositoryProvider).joinEvent(eventId);
      await fetchEvents();
      return true;
    } catch (e) {
      return false;
    }
  }
}

final eventsProvider = NotifierProvider<EventsNotifier, AsyncValue<List<Event>>>(
  EventsNotifier.new,
);
