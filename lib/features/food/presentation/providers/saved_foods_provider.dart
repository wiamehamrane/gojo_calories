import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/repository_providers.dart';

final savedFoodsProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.read(foodRepositoryProvider).getSavedFoods();
});
