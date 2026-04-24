import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/network/api_client.dart';
import '../../../dashboard/providers/dashboard_provider.dart';

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
    final stats = ref.read(dashboardProvider);
    _caloriesCtrl = TextEditingController(text: stats.calorieBudget.toString());
    _proteinCtrl = TextEditingController(text: stats.proteinTarget.toString());
    _carbsCtrl = TextEditingController(text: stats.carbsTarget.toString());
    _fatsCtrl = TextEditingController(text: stats.fatTarget.toString());
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
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient.instance.put(
        'auth/me/profile', // Reusing profile update or a specific macro endpoint if exists
        data: {
          'daily_calories': int.tryParse(_caloriesCtrl.text),
          'protein_target': int.tryParse(_proteinCtrl.text),
          'carbs_target': int.tryParse(_carbsCtrl.text),
          'fat_target': int.tryParse(_fatsCtrl.text),
        },
      );
      
      if (res.statusCode == 200) {
        // Refresh dashboard to show new targets
        ref.invalidate(dashboardProvider);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nutrition goals updated!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save targets')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Edit Nutrition Goals',
          style: AppTextStyles.sectionHeader,
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          _buildGoalField("Daily Calorie Budget", _caloriesCtrl, "kcal"),
          const SizedBox(height: 16),
          _buildGoalField("Protein Target", _proteinCtrl, "g"),
          const SizedBox(height: 16),
          _buildGoalField("Carbs Target", _carbsCtrl, "g"),
          const SizedBox(height: 16),
          _buildGoalField("Fats Target", _fatsCtrl, "g"),
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
              : const Text('Save Targets', style: AppTextStyles.buttonLabel),
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
          labelStyle: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
