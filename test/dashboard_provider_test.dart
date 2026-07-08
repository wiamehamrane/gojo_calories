import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gojocalories/core/database/database.dart';
import 'package:gojocalories/core/database/database_provider.dart';
import 'package:gojocalories/core/di/repository_providers.dart';
import 'package:gojocalories/features/stats/data/repositories/stats_repository.dart';
import 'package:gojocalories/features/stats/presentation/providers/dashboard_provider.dart';
import 'package:gojocalories/features/stats/presentation/providers/selected_date_provider.dart';

class _FakeStatsRepository extends StatsRepository {
  _FakeStatsRepository(this._dailyStats);

  final List<dynamic> _dailyStats;

  @override
  Future<List<dynamic>> getDailyStats({
    required String date,
    required int tzOffset,
  }) async =>
      _dailyStats;
}

class _FixedDateNotifier extends SelectedDateNotifier {
  _FixedDateNotifier(this._date);

  final DateTime _date;

  @override
  DateTime build() => _date;
}

ProviderContainer _createContainer({
  required List<dynamic> dailyStats,
  DateTime? date,
}) {
  final selectedDate = date ?? DateTime(2026, 7, 6);
  return ProviderContainer(
    overrides: [
      statsRepositoryProvider.overrideWithValue(
        _FakeStatsRepository(dailyStats),
      ),
      databaseProvider.overrideWithValue(AppDatabase.forTesting()),
      selectedDateProvider.overrideWith(
        () => _FixedDateNotifier(selectedDate),
      ),
    ],
  );
}

void main() {
  setUpAll(() {
    dotenv.loadFromString(
      envString: 'API_URL=https://api.gojocalories.com/api/',
    );
  });

  test('DashboardProvider loads daily stats from the repository', () async {
    final container = _createContainer(
      dailyStats: [
        {
          'calorie_budget': 2200,
          'protein_target': 150,
          'carbs_target': 200,
          'fat_target': 70,
        },
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(dashboardProvider.future);

    expect(state.calorieBudget, 2200);
    expect(state.proteinTarget, 150);
  });

  test(
    'DashboardProvider logFood updates state synchronously before API resolves',
    () async {
      final container = _createContainer(
        dailyStats: [
          {
            'calorie_budget': 2200,
            'protein_target': 150,
            'carbs_target': 200,
            'fat_target': 70,
          },
        ],
      );
      addTearDown(container.dispose);

      await container.read(dashboardProvider.future);

      container.read(dashboardProvider.notifier).logFood(
            calories: 500,
            protein: 50,
            carbs: 40,
            fat: 10,
          );

      final state = container.read(dashboardProvider).requireValue;

      expect(state.caloriesConsumed, 500);
      expect(state.proteinConsumed, 50);
    },
  );
}
