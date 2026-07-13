import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/di/repository_providers.dart';
import '../../../stats/presentation/providers/dashboard_provider.dart';

class DescribeExerciseScreen extends ConsumerStatefulWidget {
  const DescribeExerciseScreen({super.key});

  @override
  ConsumerState<DescribeExerciseScreen> createState() =>
      _DescribeExerciseScreenState();
}

class _DescribeExerciseScreenState extends ConsumerState<DescribeExerciseScreen> {
  final _descriptionController = TextEditingController();
  bool _analyzing = false;
  bool _saving = false;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _analyze(String lang) async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Translations.t(lang, 'describe_exercise_empty')),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _analyzing = true;
      _result = null;
    });

    try {
      final data = await ref
          .read(exerciseRepositoryProvider)
          .analyzeDescription(description);
      if (!mounted) return;
      setState(() => _result = data);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Translations.t(lang, 'error_generic')),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  Future<void> _logExercise(String lang) async {
    final result = _result;
    if (result == null) return;

    final name = result['name']?.toString() ?? 'Workout';
    final duration = int.tryParse(result['duration_minutes']?.toString() ?? '') ?? 0;
    final calories = int.tryParse(result['calories_burned']?.toString() ?? '') ?? 0;
    if (duration <= 0 || calories <= 0) return;

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
          content: Text(Translations.t(lang, 'exercise_logged')),
          backgroundColor: AppColors.primaryDark,
        ),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(Translations.t(lang, 'error_generic')),
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
        title: Text(t('describe_exercise'), style: AppTextStyles.sectionHeader),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _descriptionController,
                maxLines: 5,
                enabled: !_analyzing && !_saving,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: t('describe_exercise_hint'),
                  hintStyle: TextStyle(color: AppColors.textPlaceholder),
                ),
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 16),
              _ResultCard(result: _result!, lang: lang),
            ],
            const Spacer(),
            if (_result != null) ...[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                onPressed: _saving ? null : () => _logExercise(lang),
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
                        t('log_exercise'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
              ),
              const SizedBox(height: 12),
            ],
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _result != null
                    ? AppColors.surface
                    : AppColors.primaryDark,
                foregroundColor:
                    _result != null ? AppColors.textPrimary : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                  side: _result != null
                      ? BorderSide(color: AppColors.border)
                      : BorderSide.none,
                ),
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              onPressed: (_analyzing || _saving)
                  ? null
                  : () => _analyze(lang),
              child: _analyzing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.sparkles,
                          color: _result != null
                              ? AppColors.textPrimary
                              : Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _result != null
                              ? t('analyze_again')
                              : t('analyze_with_ai'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  final String lang;

  const _ResultCard({required this.result, required this.lang});

  @override
  Widget build(BuildContext context) {
    final name = result['name']?.toString() ?? 'Workout';
    final duration = result['duration_minutes']?.toString() ?? '0';
    final calories = result['calories_burned']?.toString() ?? '0';
    final durationLabel = Translations.t(lang, 'exercise_duration_mins')
        .replaceAll('{n}', duration);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  LucideIcons.flame,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                durationLabel,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                ' · ',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              Text(
                '-$calories kcal',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
