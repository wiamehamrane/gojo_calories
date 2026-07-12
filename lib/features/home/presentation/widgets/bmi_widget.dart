import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/repository_providers.dart';

final bmiProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final data = await ref.read(authRepositoryProvider).getMe();
    double? weight = (data['current_weight'] as num?)?.toDouble();
    final height = (data['height'] as num?)?.toDouble();
    final weightUnit = (data['weight_unit'] as String?)?.toLowerCase();

    if (weight == null || height == null || weight <= 0 || height <= 0) {
      return {'bmi': null, 'category': ''};
    }

    if (weightUnit == 'lbs') {
      weight = weight * 0.453592;
    }

    final bmi = weight / ((height / 100) * (height / 100));
    final category = bmi < 18.5
        ? 'Underweight'
        : bmi < 25
            ? 'Normal'
            : bmi < 30
                ? 'Overweight'
                : 'Obese';
    return {'bmi': bmi, 'category': category, 'weight': weight, 'height': height};
  } catch (_) {
    return {'bmi': null, 'category': ''};
  }
});

class BmiWidget extends ConsumerWidget {
  const BmiWidget({super.key});

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'Underweight':
        return const Color(0xFF3B82F6); // blue
      case 'Normal':
        return AppColors.primary;
      case 'Overweight':
        return AppColors.fire;
      case 'Obese':
        return AppColors.danger;
      default:
        return AppColors.inactive;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bmiAsync = ref.watch(bmiProvider);
    return bmiAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      ),
      error: (e, s) => _BmiContent(bmiValue: null, category: '', onCategoryColor: _categoryColor),
      data: (data) {
        final bmi = (data['bmi'] as num?)?.toDouble();
        final category = data['category'] as String? ?? '';
        return _BmiContent(
          bmiValue: bmi,
          category: category,
          onCategoryColor: _categoryColor,
        );
      },
    );
  }
}

class _BmiContent extends StatelessWidget {
  final double? bmiValue;
  final String category;
  final Color Function(String) onCategoryColor;

  const _BmiContent({
    required this.bmiValue,
    required this.category,
    required this.onCategoryColor,
  });

  @override
  Widget build(BuildContext context) {
    final displayBmi = bmiValue != null ? bmiValue!.toStringAsFixed(1) : '--';
    final color = category.isNotEmpty ? onCategoryColor(category) : AppColors.inactive;
    // Clamp BMI on 0-1 progress scale from 10 to 40
    final progress = bmiValue != null ? ((bmiValue! - 10) / 30).clamp(0.0, 1.0) : 0.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Number
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    displayBmi,
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: color,
                      height: 1.0,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 5, left: 4),
                    child: Text(
                      'BMI',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (category.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                )
              else
                Text(
                  'Update profile weight & height',
                  style: TextStyle(fontSize: 10, color: AppColors.inactive),
                ),
              const SizedBox(height: 8),
              // Color spectrum bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(
                  children: [
                    // Full gradient
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF3B82F6),
                            AppColors.primary,
                            AppColors.fire,
                            AppColors.danger,
                          ],
                        ),
                      ),
                    ),
                    // Indicator
                    if (bmiValue != null)
                      Positioned(
                        left: progress * 80 - 4,
                        top: -1,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: color, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Ranges column
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _RangeLabel('< 18.5', 'Under', Color(0xFF3B82F6)),
            _RangeLabel('18.5–25', 'Normal', AppColors.primary),
            _RangeLabel('25–30', 'Over', AppColors.fire),
            _RangeLabel('> 30', 'Obese', AppColors.danger),
          ],
        ),
      ],
    );
  }
}

class _RangeLabel extends StatelessWidget {
  final String range;
  final String label;
  final Color color;
  const _RangeLabel(this.range, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
