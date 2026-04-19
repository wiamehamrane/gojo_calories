import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/localization/translations.dart';

class LogExerciseScreen extends ConsumerWidget {
  const LogExerciseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    String t(String k) => Translations.t(lang, k);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(t('log_exercise'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(t('log_exercise'), style: AppTextStyles.screenTitle),
            const SizedBox(height: 20),

            _ExerciseOptionCard(
              icon: LucideIcons.footprints,
              name: t('run'),
              desc: 'Running, jogging, sprinting, etc.',
              onTap: () => context.push('/run_intensity'),
            ),
            const SizedBox(height: 10),
            _ExerciseOptionCard(
              icon: LucideIcons.dumbbell,
              name: t('weight_lifting'),
              desc: 'Machines, free weights, etc.',
              onTap: () => context.push('/weight_lifting'),
            ),
            const SizedBox(height: 10),
            _ExerciseOptionCard(
              icon: LucideIcons.pencil,
              name: t('describe'),
              desc: t('describe_hint'),
              onTap: () => context.push('/describe_exercise'),
            ),
            const SizedBox(height: 10),
            _ExerciseOptionCard(
              icon: LucideIcons.flame,
              name: t('manual'),
              desc: t('calories_burned'),
              onTap: () => context.push('/manual_exercise'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseOptionCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final String desc;
  final VoidCallback onTap;

  const _ExerciseOptionCard({required this.icon, required this.name, required this.desc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.textPrimary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(desc, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
