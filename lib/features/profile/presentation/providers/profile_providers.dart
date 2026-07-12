import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../../../../core/di/repository_providers.dart';

class ProfileNotifier extends Notifier<AsyncValue<Map<String, dynamic>>> {
  @override
  AsyncValue<Map<String, dynamic>> build() {
    loadProfile();
    return const AsyncValue.loading();
  }

  Future<void> loadProfile() async {
    try {
      final data = await ref.read(profileRepositoryProvider).getMe();
      state = AsyncValue.data(data);
      _syncPushIdentity(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Links this device to the user in OneSignal and tags their gender so
  /// the backend can send gender-aware smart notifications.
  Future<void> _syncPushIdentity(Map<String, dynamic> data) async {
    try {
      final userId = data['user_id']?.toString();
      if (userId == null || userId.isEmpty) return;
      await OneSignal.login(userId);
      final gender = data['gender']?.toString().toLowerCase();
      if (gender == 'male' || gender == 'female') {
        await OneSignal.User.addTagWithKey('gender', gender);
      }
    } catch (_) {
      // Push identity sync is best-effort; never block profile loading.
    }
  }

  Future<void> resendVerification() async {
    await ref.read(profileRepositoryProvider).resendVerification();
  }

  Future<void> deleteAccount() async {
    await ref.read(profileRepositoryProvider).deleteAccount();
    await ref.read(authRepositoryProvider).clearSession();
  }

  Future<void> uploadMemoryCaption(Map<String, dynamic> data) async {
    await ref.read(profileRepositoryProvider).updateProfile(data);
  }
}

final profileProvider =
    NotifierProvider<ProfileNotifier, AsyncValue<Map<String, dynamic>>>(
  ProfileNotifier.new,
);

class PersonalDetailsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> saveProfile(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(profileRepositoryProvider).updatePersonalDetails(data);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> saveWeight(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(profileRepositoryProvider).updateWeight(data);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final personalDetailsProvider =
    NotifierProvider<PersonalDetailsNotifier, AsyncValue<void>>(
  PersonalDetailsNotifier.new,
);

class NutritionGoalsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> saveGoals(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(profileRepositoryProvider).updateNutritionGoals(data);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final nutritionGoalsProvider =
    NotifierProvider<NutritionGoalsNotifier, AsyncValue<void>>(
  NutritionGoalsNotifier.new,
);
