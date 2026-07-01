import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/repository_providers.dart';

class WeighInEntry {
  final double weight;
  final DateTime date;

  WeighInEntry({required this.weight, required this.date});

  factory WeighInEntry.fromJson(Map<String, dynamic> json) {
    return WeighInEntry(
      weight: (json['weight'] as num).toDouble(),
      date: DateTime.parse(json['date']),
    );
  }
}

class ProgressNotifier extends Notifier<AsyncValue<List<WeighInEntry>>> {
  @override
  AsyncValue<List<WeighInEntry>> build() {
    _fetchWeighIns();
    return const AsyncValue.loading();
  }

  Future<void> _fetchWeighIns() async {
    try {
      final list = await ref.read(statsRepositoryProvider).getWeighIns();
      state = AsyncValue.data(
        list.map((e) => WeighInEntry.fromJson(e as Map<String, dynamic>)).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _fetchWeighIns();
  }
}

final progressProvider =
    NotifierProvider<ProgressNotifier, AsyncValue<List<WeighInEntry>>>(
  ProgressNotifier.new,
);
