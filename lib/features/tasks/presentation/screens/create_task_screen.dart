import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/duration_parser.dart';
import '../providers/tasks_provider.dart';

class CreateTaskScreen extends ConsumerStatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  Duration _customDuration = const Duration(minutes: 1);

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final lang = ref.read(localeProvider);
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Translations.t(lang, 'tasks_title_required'))),
      );
      return;
    }

    final durationSeconds = _customDuration.inSeconds;
    if (durationSeconds < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Translations.t(lang, 'tasks_duration_invalid'))),
      );
      return;
    }

    final task = await ref.read(tasksProvider.notifier).addTask(
          title: title,
          description: _descriptionController.text.trim(),
          durationSeconds: durationSeconds,
        );

    if (!mounted || task == null) return;
    context.pop();
    context.push(RoutePaths.taskTimer, extra: task.id);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final durationLabel = formatTaskDuration(_customDuration.inSeconds);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Translations.t(lang, 'tasks_create'),
                          style: AppTextStyles.screenTitle.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          Translations.t(lang, 'tasks_subtitle'),
                          style: AppTextStyles.bodyRegular.copyWith(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(
                      LucideIcons.x,
                      size: 22,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  24,
                  AppSpacing.screenPadding,
                  16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FormCard(
                      child: Column(
                        children: [
                          TextField(
                            controller: _titleController,
                            autofocus: true,
                            textCapitalization: TextCapitalization.sentences,
                            style: AppTextStyles.bodyBold.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: Translations.t(lang, 'tasks_name_hint'),
                              hintStyle: AppTextStyles.bodyRegular.copyWith(
                                color: AppColors.textPlaceholder,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.border,
                          ),
                          TextField(
                            controller: _descriptionController,
                            textCapitalization: TextCapitalization.sentences,
                            maxLines: 3,
                            minLines: 2,
                            style: AppTextStyles.bodyRegular.copyWith(
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: Translations.t(
                                lang,
                                'tasks_description_hint',
                              ),
                              hintStyle: AppTextStyles.bodyRegular.copyWith(
                                color: AppColors.textPlaceholder,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _FormCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    LucideIcons.timer,
                                    size: 18,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        Translations.t(
                                          lang,
                                          'tasks_custom_duration_label',
                                        ),
                                        style: AppTextStyles.cardHeading
                                            .copyWith(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        durationLabel,
                                        style: AppTextStyles.cardValue.copyWith(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          height: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(AppRadius.card),
                            ),
                            child: SizedBox(
                              height: 168,
                              child: CupertinoTheme(
                                data: CupertinoTheme.of(context).copyWith(
                                  primaryColor: AppColors.primaryDark,
                                  textTheme: CupertinoTextThemeData(
                                    pickerTextStyle: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary
                                          .withValues(alpha: 0.35),
                                    ),
                                    dateTimePickerTextStyle: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                child: CupertinoTimerPicker(
                                  mode: CupertinoTimerPickerMode.hms,
                                  initialTimerDuration: _customDuration,
                                  alignment: Alignment.center,
                                  backgroundColor: AppColors.surface,
                                  onTimerDurationChanged: (duration) {
                                    HapticFeedback.selectionClick();
                                    setState(() => _customDuration = duration);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                0,
                AppSpacing.screenPadding,
                16,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                  child: Text(
                    Translations.t(lang, 'tasks_start'),
                    style: AppTextStyles.buttonLabel.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final Widget child;

  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
