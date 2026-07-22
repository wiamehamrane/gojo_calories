import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/health_repository.dart';
import '../../data/health_service.dart';
import '../../data/health_storage.dart';
import '../../data/models/health_sync_data.dart';

class HealthSyncState {
  final HealthSyncData data;
  final bool isLoading;
  final bool isAvailable;
  final String? error;

  const HealthSyncState({
    required this.data,
    this.isLoading = false,
    this.isAvailable = true,
    this.error,
  });

  bool get isConnected => data.isConnected;

  HealthSyncState copyWith({
    HealthSyncData? data,
    bool? isLoading,
    bool? isAvailable,
    String? error,
    bool clearError = false,
  }) {
    return HealthSyncState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      isAvailable: isAvailable ?? this.isAvailable,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class HealthSyncNotifier extends Notifier<HealthSyncState> {
  late final HealthService _service;
  late final HealthStorage _storage;
  late final HealthRepository _repository;

  @override
  HealthSyncState build() {
    _service = HealthService();
    _storage = HealthStorage();
    _repository = HealthRepository();
    _bootstrap();
    return HealthSyncState(data: const HealthSyncData());
  }

  Future<void> _pushToServer(HealthSyncData data) async {
    try {
      await _repository.uploadToday(data);
    } catch (_) {
      // Local health sync still works if upload fails.
    }
  }

  Future<void> _bootstrap() async {
    final cached = await _storage.load();
    final available = await _service.isPlatformAvailable();

    state = state.copyWith(
      data: cached,
      isAvailable: available,
      clearError: true,
    );

    if (cached.isConnected && available) {
      await refresh();
    }
  }

  Future<void> connectAppleHealth() async {
    if (!_service.isAppleHealthPlatform) {
      state = state.copyWith(
        error: 'Apple Health is only available on iPhone.',
      );
      return;
    }
    await _connect();
  }

  Future<void> connectHealthConnect() async {
    if (!_service.isHealthConnectPlatform) {
      state = state.copyWith(
        error: 'Health Connect is only available on Android.',
      );
      return;
    }

    final available = await _service.isPlatformAvailable();
    if (!available) {
      state = state.copyWith(
        isAvailable: false,
        error:
            'Health Connect is not installed. Tap again after installing from the Play Store.',
      );
      await _service.promptInstallHealthConnect();
      return;
    }

    await _connect();
  }

  Future<void> _connect() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.connect();
      final synced = await _service.syncToday();
      await _storage.save(synced);
      await _pushToServer(synced);
      state = state.copyWith(
        data: synced,
        isLoading: false,
        isAvailable: true,
        clearError: true,
      );
    } on HealthServiceException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Could not connect health data. Please try again.',
      );
    }
  }

  Future<void> refresh() async {
    if (!state.data.isConnected) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final synced = await _service.syncToday();
      await _storage.save(synced);
      await _pushToServer(synced);
      state = state.copyWith(
        data: synced,
        isLoading: false,
        clearError: true,
      );
    } on HealthServiceException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Could not refresh health data.',
      );
    }
  }

  Future<void> disconnect() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _service.disconnect();
      await _storage.clear();
      state = HealthSyncState(
        data: const HealthSyncData(),
        isAvailable: state.isAvailable,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Could not disconnect health data.',
      );
    }
  }
}

final healthSyncProvider =
    NotifierProvider<HealthSyncNotifier, HealthSyncState>(
  HealthSyncNotifier.new,
);
