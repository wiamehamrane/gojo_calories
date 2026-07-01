import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


void main() {
  test('DashboardProvider initial state is correctly padded', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(dashboardProvider);

    expect(state.calorieBudget, 2200);
    expect(state.proteinTarget, 150);
  });

  test(
    'DashboardProvider logFood updates state syncronously before API resolves',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(dashboardProvider.notifier)
          .logFood(calories: 500, protein: 50, carbs: 40, fat: 10);

      final state = container.read(dashboardProvider);

      expect(state.caloriesConsumed, 500);
      expect(state.proteinConsumed, 50);
    },
  );
}
