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
const _kActionButtonSize = 84.0;

class CreateTaskScreen extends ConsumerStatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  Duration _duration = const Duration(hours: 1, minutes: 30);
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _defaultTaskName(String lang) =>
      Translations.t(lang, 'tasks_default_name');

  Future<void> _startTask() async {
    final lang = ref.read(localeProvider);
    final durationSeconds = _duration.inSeconds;

    if (durationSeconds < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Translations.t(lang, 'tasks_duration_invalid'))),
      );
      return;
    }

    final title = _nameController.text.trim().isEmpty
        ? _defaultTaskName(lang)
        : _nameController.text.trim();

    final description = _descriptionController.text.trim();

    final task = await ref.read(tasksProvider.notifier).addTask(
          title: title,
          durationSeconds: durationSeconds,
          description: description.isEmpty ? null : description,
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
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          bottom: false,
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
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
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.viewInsetsOf(context).bottom,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 60,
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 24),
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
                            const SizedBox(height: 20),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 40),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _CircleActionButton(
                                    label: Translations.t(lang, 'cancel'),
                                    backgroundColor: _kCancelButton,
                                    foregroundColor: _kCancelText,
                                    onTap: () => context.pop(),
                                  ),
                                  _CircleActionButton(
                                    label: Translations.t(
                                      lang,
                                      'tasks_start_short',
                                    ),
                                    backgroundColor: _kStartButton,
                                    foregroundColor: _kStartText,
                                    onTap: _startTask,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: _SettingsGroup(
                                children: [
                                  _SettingsInputRow(
                                    label: Translations.t(
                                      lang,
                                      'tasks_row_label',
                                    ),
                                    controller: _nameController,
                                    placeholder: Translations.t(
                                      lang,
                                      'tasks_name_hint',
                                    ),
                                  ),
                                  _SettingsInputRow(
                                    label: Translations.t(
                                      lang,
                                      'tasks_description_label',
                                    ),
                                    controller: _descriptionController,
                                    placeholder: Translations.t(
                                      lang,
                                      'tasks_description_hint',
                                    ),
                                    maxLines: 2,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.paddingOf(context).bottom + 8),
                ],
              );
            },
            ),
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
    return SizedBox(
      width: _kActionButtonSize,
      height: _kActionButtonSize,
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

class _SettingsInputRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String placeholder;
  final int maxLines;

  const _SettingsInputRow({
    required this.label,
    required this.controller,
    required this.placeholder,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment:
            maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _kPrimaryText,
              fontSize: 17,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CupertinoTextField(
              controller: controller,
              placeholder: placeholder,
              maxLines: maxLines,
              textCapitalization: TextCapitalization.sentences,
              textAlign: TextAlign.right,
              decoration: const BoxDecoration(),
              padding: const EdgeInsets.symmetric(vertical: 6),
              style: const TextStyle(
                color: _kSecondaryText,
                fontSize: 17,
                fontWeight: FontWeight.w400,
              ),
              placeholderStyle: TextStyle(
                color: _kSecondaryText.withValues(alpha: 0.7),
                fontSize: 17,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
