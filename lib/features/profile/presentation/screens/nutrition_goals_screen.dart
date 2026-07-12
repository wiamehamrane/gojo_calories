import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../providers/profile_providers.dart';
import '../../../stats/presentation/providers/dashboard_provider.dart';

class NutritionGoalsScreen extends ConsumerStatefulWidget {
  const NutritionGoalsScreen({super.key});

  @override
  ConsumerState<NutritionGoalsScreen> createState() => _NutritionGoalsScreenState();
}

class _NutritionGoalsScreenState extends ConsumerState<NutritionGoalsScreen> {
  late TextEditingController _caloriesCtrl;
  late TextEditingController _proteinCtrl;
  late TextEditingController _carbsCtrl;
  late TextEditingController _fatsCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final stats = ref.read(dashboardProvider).value;
    _caloriesCtrl = TextEditingController(
      text: (stats?.calorieBudget ?? 2200).toString(),
    );
    _proteinCtrl = TextEditingController(
      text: (stats?.proteinTarget ?? 150).toString(),
    );
    _carbsCtrl = TextEditingController(
      text: (stats?.carbsTarget ?? 200).toString(),
    );
    _fatsCtrl = TextEditingController(
      text: (stats?.fatTarget ?? 65).toString(),
    );
  }

  @override
  void dispose() {
    _caloriesCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatsCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveTargets() async {
    final lang = ref.read(localeProvider);
    String t(String k) => Translations.t(lang, k);
    setState(() => _isLoading = true);
    try {
      await ref.read(nutritionGoalsProvider.notifier).saveGoals({
        'daily_calories': int.tryParse(_caloriesCtrl.text),
        'protein_target': int.tryParse(_proteinCtrl.text),
        'carbs_target': int.tryParse(_carbsCtrl.text),
        'fat_target': int.tryParse(_fatsCtrl.text),
      });

      ref.invalidate(dashboardProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('nutrition_goals_saved'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('failed_save_targets'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    String t(String k) => Translations.t(lang, k);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          t('edit_nutrition_goals'),
          style: AppTextStyles.sectionHeader,
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          _buildGoalField(t('daily_calorie_budget'), _caloriesCtrl, "kcal"),
          const SizedBox(height: 16),
          _buildGoalField(t('protein_target'), _proteinCtrl, "g"),
          const SizedBox(height: 16),
          _buildGoalField(t('carbs_target'), _carbsCtrl, "g"),
          const SizedBox(height: 16),
          _buildGoalField(t('fats_target'), _fatsCtrl, "g"),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: AppColors.primaryDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            onPressed: _isLoading ? null : _saveTargets,
            child: _isLoading 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(t('save_targets'), style: AppTextStyles.buttonLabel),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalField(String label, TextEditingController controller, String unit) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          suffixText: unit,
          border: InputBorder.none,
          labelStyle: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
