import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/di/repository_providers.dart';
import '../../domain/models/coach.dart';

class CoachDiscoverState {
  final List<Coach> items;
  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final int page;
  final String? error;
  final double? latitude;
  final double? longitude;
  final String? locationLabel;
  final double radiusKm;
  final String? specialty;
  final String? gender;

  const CoachDiscoverState({
    this.items = const [],
    this.loading = false,
    this.loadingMore = false,
    this.hasMore = false,
    this.page = 1,
    this.error,
    this.latitude,
    this.longitude,
    this.locationLabel,
    this.radiusKm = 25,
    this.specialty,
    this.gender,
  });

  bool get hasLocation => latitude != null && longitude != null;

  CoachDiscoverState copyWith({
    List<Coach>? items,
    bool? loading,
    bool? loadingMore,
    bool? hasMore,
    int? page,
    String? error,
    bool clearError = false,
    double? latitude,
    double? longitude,
    String? locationLabel,
    double? radiusKm,
    String? specialty,
    bool clearSpecialty = false,
    String? gender,
    bool clearGender = false,
  }) {
    return CoachDiscoverState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: clearError ? null : (error ?? this.error),
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationLabel: locationLabel ?? this.locationLabel,
      radiusKm: radiusKm ?? this.radiusKm,
      specialty: clearSpecialty ? null : (specialty ?? this.specialty),
      gender: clearGender ? null : (gender ?? this.gender),
    );
  }
}

class CoachDiscoverNotifier extends Notifier<CoachDiscoverState> {
  static const pageSize = 5;

  @override
  CoachDiscoverState build() => const CoachDiscoverState();

  Future<void> useCurrentLocation() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          loading: false,
          error: 'location_services_disabled',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          loading: false,
          error: 'location_permission_denied_forever',
        );
        return;
      }

      if (permission == LocationPermission.denied) {
        state = state.copyWith(
          loading: false,
          error: 'location_permission_required',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      state = state.copyWith(
        latitude: position.latitude,
        longitude: position.longitude,
        locationLabel: 'current_location',
        loading: false,
        clearError: true,
      );
      await search(reset: true);
    } catch (_) {
      state = state.copyWith(loading: false, error: 'location_failed');
    }
  }

  Future<bool> openLocationSettings() {
    return Geolocator.openAppSettings();
  }

  void setManualLocation({
    required double latitude,
    required double longitude,
    required String label,
  }) {
    state = state.copyWith(
      latitude: latitude,
      longitude: longitude,
      locationLabel: label,
      clearError: true,
    );
  }

  void setRadiusKm(double value) {
    state = state.copyWith(radiusKm: value);
  }

  void setSpecialty(String? specialty) {
    if (specialty == null || specialty.isEmpty) {
      state = state.copyWith(clearSpecialty: true);
    } else {
      state = state.copyWith(specialty: specialty);
    }
  }

  void setGender(String? gender) {
    if (gender == null || gender.isEmpty) {
      state = state.copyWith(clearGender: true);
    } else {
      state = state.copyWith(gender: gender);
    }
  }

  Future<void> search({bool reset = true}) async {
    if (!state.hasLocation) {
      state = state.copyWith(error: 'location_required');
      return;
    }

    final nextPage = reset ? 1 : state.page + 1;
    state = state.copyWith(
      loading: reset,
      loadingMore: !reset,
      clearError: true,
      items: reset ? const [] : state.items,
      page: reset ? 1 : state.page,
    );

    try {
      final page = await ref.read(coachesRepositoryProvider).search(
            lat: state.latitude!,
            lng: state.longitude!,
            radiusKm: state.radiusKm,
            specialty: state.specialty,
            gender: state.gender,
            page: nextPage,
            pageSize: pageSize,
          );
      state = state.copyWith(
        items: reset ? page.items : [...state.items, ...page.items],
        page: page.page,
        hasMore: page.hasMore,
        loading: false,
        loadingMore: false,
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        loading: false,
        loadingMore: false,
        error: 'coaches_search_failed',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore) return;
    await search(reset: false);
  }
}

final coachDiscoverProvider =
    NotifierProvider<CoachDiscoverNotifier, CoachDiscoverState>(
  CoachDiscoverNotifier.new,
);
