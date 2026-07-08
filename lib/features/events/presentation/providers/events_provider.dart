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

  /// AI-powered search: the query can be a keyword, a sport name, or a
  /// prompt describing the event the user wants.
  Future<void> aiSearch(String query) async {
    state = const AsyncValue.loading();
    try {
      final data = await ref.read(eventsRepositoryProvider).aiSearchEvents(query);
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
    final data =
        await ref.read(eventsRepositoryProvider).createEvent(eventData);
    await fetchEvents();
    return Event.fromJson(data);
  }

  Future<String> uploadEventImage(String eventId, File imageFile) async {
    final url =
        await ref.read(eventsRepositoryProvider).uploadEventImage(
              eventId,
              imageFile,
            );
    await fetchEvents();
    ref.read(myEventsProvider.notifier).fetchMyEvents();
    return url;
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

/// Events created by the current user, managed from the profile's
/// "My Events" section.
class MyEventsNotifier extends Notifier<AsyncValue<List<Event>>> {
  @override
  AsyncValue<List<Event>> build() {
    fetchMyEvents();
    return const AsyncValue.loading();
  }

  Future<void> fetchMyEvents() async {
    state = const AsyncValue.loading();
    try {
      final data = await ref.read(eventsRepositoryProvider).getMyEvents();
      state = AsyncValue.data(data.map((e) => Event.fromJson(e)).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Rethrows on failure so callers can show the error message.
  Future<Event> updateEvent(String eventId, Map<String, dynamic> updates) async {
    final data =
        await ref.read(eventsRepositoryProvider).updateEvent(eventId, updates);
    final updated = Event.fromJson(data);
    state = state.whenData(
      (events) => [for (final e in events) e.id == eventId ? updated : e],
    );
    ref.read(eventsProvider.notifier).fetchEvents();
    return updated;
  }

  /// Rethrows on failure so callers can show the error message.
  Future<void> deleteEvent(String eventId) async {
    await ref.read(eventsRepositoryProvider).deleteEvent(eventId);
    state = state.whenData(
      (events) => events.where((e) => e.id != eventId).toList(),
    );
    ref.read(eventsProvider.notifier).fetchEvents();
  }
}

final myEventsProvider =
    NotifierProvider<MyEventsNotifier, AsyncValue<List<Event>>>(
  MyEventsNotifier.new,
);
