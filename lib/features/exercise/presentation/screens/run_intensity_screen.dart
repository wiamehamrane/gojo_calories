import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../stats/presentation/providers/dashboard_provider.dart';

enum RunIntensity { high, medium, low }

int _estimateRunCalories(RunIntensity intensity, int minutes) {
  const double bodyWeightKg = 75.0;
  final double met = switch (intensity) {
    RunIntensity.high => 14.0,
    RunIntensity.medium => 9.8,
    RunIntensity.low => 3.5,
  };
  return (met * bodyWeightKg * (minutes / 60)).round();
}

class RunIntensityScreen extends ConsumerStatefulWidget {
  const RunIntensityScreen({super.key});

  @override
  ConsumerState<RunIntensityScreen> createState() => _RunIntensityScreenState();
}

class _RunIntensityScreenState extends ConsumerState<RunIntensityScreen> {
  RunIntensity? _selectedIntensity = RunIntensity.medium;
  final List<String> _durations = [
    "15 mins",
    "30 mins",
    "60 mins",
    "90 mins",
    "120 mins",
  ];
  int _selectedDurationIndex = 1;
  final _manualDurationController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _manualDurationController.dispose();
    super.dispose();
  }

  int get _durationMinutes {
    final manual = int.tryParse(_manualDurationController.text.trim());
    if (manual != null && manual > 0) return manual;
    return int.parse(_durations[_selectedDurationIndex].split(' ').first);
  }

  Future<void> _saveRun() async {
    final intensity = _selectedIntensity ?? RunIntensity.medium;
    final minutes = _durationMinutes;
    if (minutes <= 0) return;

    final calories = _estimateRunCalories(intensity, minutes);
    final intensityLabel = switch (intensity) {
      RunIntensity.high => 'High',
      RunIntensity.medium => 'Medium',
      RunIntensity.low => 'Low',
    };

    setState(() => _saving = true);
    try {
      await ref.read(dashboardProvider.notifier).logExercise(
            name: 'Run ($intensityLabel)',
            durationMinutes: minutes,
            caloriesBurned: calories,
          );
      if (!mounted) return;
      final lang = ref.read(localeProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Translations.t(lang, 'logged_kcal_burned')
                .replaceAll('{calories}', '$calories'),
          ),
          backgroundColor: AppColors.primaryDark,
        ),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      final lang = ref.read(localeProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Translations.t(lang, 'failed_save_run')),
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
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.footprints,
              size: 18,
              color: AppColors.textPrimary,
            ),
            Text(
              ' ${t('run')}',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section header
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.sparkles,
                        size: 18,
                        color: AppColors.inactive,
                      ),
                      const SizedBox(width: 6),
                      Text(t('set_intensity'), style: AppTextStyles.sectionHeader),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Intensity card
                  RadioGroup<RunIntensity>(
                    groupValue: _selectedIntensity,
                    onChanged: (val) =>
                        setState(() => _selectedIntensity = val),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _buildIntensityRow(
                            "High",
                            "Sprinting – 14 mph (4 minute miles)",
                            RunIntensity.high,
                          ),
                          const Divider(
                            color: AppColors.border,
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                          ),
                          _buildIntensityRow(
                            "Medium",
                            "Jogging – 6 mph (10 minute miles)",
                            RunIntensity.medium,
                          ),
                          const Divider(
                            color: AppColors.border,
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                          ),
                          _buildIntensityRow(
                            "Low",
                            "Chill walk – 3 mph (20 minute miles)",
                            RunIntensity.low,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Duration header
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.timer,
                        size: 18,
                        color: AppColors.inactive,
                      ),
                      const SizedBox(width: 6),
                      Text(t('duration'), style: AppTextStyles.sectionHeader),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_durations.length, (i) {
                        final bool selected = i == _selectedDurationIndex;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedDurationIndex = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.ease,
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primaryDark
                                  : AppColors.surface,
                              border: Border.all(
                                color: selected
                                    ? AppColors.primaryDark
                                    : AppColors.border,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _durations[i],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Manual input
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: TextField(
                      controller: _manualDurationController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Or enter manual time...",
                        hintStyle: TextStyle(
                          fontSize: 15,
                          color: AppColors.textPlaceholder,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 100), // spacer for fixed CTA
                ],
              ),
            ),
          ),

          // Fixed CTA
          Positioned(
            bottom: safeBottom > 0 ? safeBottom : 16,
            left: 16,
            right: 16,
            child: SizedBox(
              height: 56,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: _saving ? null : _saveRun,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(t('continue_btn'), style: AppTextStyles.buttonLabel),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntensityRow(String label, String desc, RunIntensity option) {
    final bool selected = _selectedIntensity == option;
    return ListTile(
      title: Text(
        label,
        style: selected
            ? const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )
            : const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
      ),
      subtitle: Text(
        desc,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
      trailing: Radio<RunIntensity>(
        value: option,
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryDark;
          }
          return AppColors.inactive;
        }),
      ),
      onTap: () => setState(() => _selectedIntensity = option),
    );
  }
}
