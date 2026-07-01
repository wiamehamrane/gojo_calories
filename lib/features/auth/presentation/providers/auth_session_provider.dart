import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/repository_providers.dart';

/// Current authenticated user profile from `GET auth/me`.
final currentUserProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  return repo.getMe();
});
