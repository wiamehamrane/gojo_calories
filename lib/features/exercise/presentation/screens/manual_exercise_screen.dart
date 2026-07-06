import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../stats/presentation/providers/dashboard_provider.dart';

class ManualExerciseScreen extends ConsumerStatefulWidget {
  const ManualExerciseScreen({super.key});

  @override
  ConsumerState<ManualExerciseScreen> createState() =>
      _ManualExerciseScreenState();
}

class _ManualExerciseScreenState extends ConsumerState<ManualExerciseScreen> {
  final _nameController = TextEditingController();
  final _durationController = TextEditingController();
  final _caloriesController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final lang = ref.read(localeProvider);
    String t(String k) => Translations.t(lang, k);
    final name = _nameController.text.trim();
    final duration = int.tryParse(_durationController.text.trim()) ?? 0;
    final calories = int.tryParse(_caloriesController.text.trim()) ?? 0;

    if (name.isEmpty || duration <= 0 || calories <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('please_fill_valid_fields')),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(dashboardProvider.notifier).logExercise(
            name: name,
            durationMinutes: duration,
            caloriesBurned: calories,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t('logged_kcal_burned').replaceAll('{calories}', '$calories'),
          ),
          backgroundColor: AppColors.primaryDark,
        ),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('failed_save_exercise')),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    String t(String k) => Translations.t(lang, k);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(t('manual_entry'), style: AppTextStyles.sectionHeader),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildField(t('exercise_name'), t('exercise_name_hint'), _nameController),
            const SizedBox(height: 16),
            _buildField(
              t('duration_minutes'),
              '45',
              _durationController,
              isNumber: true,
            ),
            const SizedBox(height: 16),
            _buildField(
              t('calories_burned'),
              '320',
              _caloriesController,
              isNumber: true,
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      t('save_entry'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    String hint,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textPlaceholder),
            ),
          ),
        ),
      ],
    );
  }
}
