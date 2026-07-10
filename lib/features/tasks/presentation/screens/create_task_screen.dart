import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/routing/route_paths.dart';
import '../providers/tasks_provider.dart';

const _kBackground = Colors.white;
const _kCard = Color(0xFFF2F2F7);
const _kPrimaryText = Color(0xFF000000);
const _kSecondaryText = Color(0xFF8E8E93);
const _kCancelButton = Color(0xFFE5E5EA);
const _kCancelText = Color(0xFF8E8E93);
const _kStartButton = Color(0xFFDDF8E4);
const _kStartText = Color(0xFF248A3D);
const _kPickerHeight = 216.0;

class CreateTaskScreen extends ConsumerStatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  Duration _duration = const Duration(hours: 1, minutes: 30);
  String _taskName = '';

  String _defaultTaskName(String lang) =>
      Translations.t(lang, 'tasks_default_name');

  String _displayTaskName(String lang) {
    final trimmed = _taskName.trim();
    if (trimmed.isEmpty) return _defaultTaskName(lang);
    return trimmed;
  }

  Future<void> _editTaskName() async {
    final lang = ref.read(localeProvider);
    final controller = TextEditingController(text: _displayTaskName(lang));

    final result = await showCupertinoDialog<String>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(Translations.t(lang, 'tasks_row_label')),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            placeholder: Translations.t(lang, 'tasks_name_hint'),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text(Translations.t(lang, 'cancel')),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(Translations.t(lang, 'save')),
          ),
        ],
      ),
    );

    controller.dispose();
    if (result == null || !mounted) return;
    setState(() => _taskName = result);
  }

  Future<void> _startTask() async {
    final lang = ref.read(localeProvider);
    final durationSeconds = _duration.inSeconds;

    if (durationSeconds < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Translations.t(lang, 'tasks_duration_invalid'))),
      );
      return;
    }

    final title = _taskName.trim().isEmpty
        ? _defaultTaskName(lang)
        : _taskName.trim();

    final task = await ref.read(tasksProvider.notifier).addTask(
          title: title,
          durationSeconds: durationSeconds,
        );

    if (!mounted || task == null) return;
    context.pop();
    context.push(RoutePaths.taskTimer, extra: task.id);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _kBackground,
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: Text(
                      Translations.t(lang, 'tasks_screen_title'),
                      style: const TextStyle(
                        color: _kPrimaryText,
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        height: 1.1,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Spacer(),
                        SizedBox(
                          height: _kPickerHeight,
                          width: constraints.maxWidth,
                          child: CupertinoTheme(
                            data: const CupertinoThemeData(
                              brightness: Brightness.light,
                              primaryColor: _kStartText,
                              textTheme: CupertinoTextThemeData(
                                pickerTextStyle: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFFAEAEB2),
                                ),
                                dateTimePickerTextStyle: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w400,
                                  color: _kPrimaryText,
                                ),
                              ),
                            ),
                            child: CupertinoTimerPicker(
                              key: const ValueKey('task_duration_picker'),
                              mode: CupertinoTimerPickerMode.hms,
                              initialTimerDuration: _duration,
                              backgroundColor: Colors.transparent,
                              onTimerDurationChanged: (duration) {
                                _duration = duration;
                                HapticFeedback.selectionClick();
                              },
                            ),
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 36),
                          child: Row(
                            children: [
                              Expanded(
                                child: _CircleActionButton(
                                  label: Translations.t(lang, 'cancel'),
                                  backgroundColor: _kCancelButton,
                                  foregroundColor: _kCancelText,
                                  onTap: () => context.pop(),
                                ),
                              ),
                              const SizedBox(width: 32),
                              Expanded(
                                child: _CircleActionButton(
                                  label: Translations.t(lang, 'tasks_start_short'),
                                  backgroundColor: _kStartButton,
                                  foregroundColor: _kStartText,
                                  onTap: _startTask,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _SettingsGroup(
                      children: [
                        _SettingsRow(
                          label: Translations.t(lang, 'tasks_row_label'),
                          value: _displayTaskName(lang),
                          onTap: _editTaskName,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: MediaQuery.paddingOf(context).bottom + 16),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  const _CircleActionButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth.clamp(0.0, 148.0);
        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: Material(
              color: backgroundColor,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 0.5,
                color: Colors.black.withValues(alpha: 0.08),
                indent: 16,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _kPrimaryText,
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: _kSecondaryText,
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                CupertinoIcons.chevron_forward,
                size: 16,
                color: _kSecondaryText.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
