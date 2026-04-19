import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

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
      final res = await ApiClient.instance.get('stats/progress/weigh-ins');
      final list = (res.data as List).map((e) => WeighInEntry.fromJson(e)).toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _fetchWeighIns();
  }
}

final progressProvider = NotifierProvider<ProgressNotifier, AsyncValue<List<WeighInEntry>>>(() {
  return ProgressNotifier();
});
