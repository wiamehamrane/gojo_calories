import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/repository_providers.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../stats/presentation/providers/dashboard_provider.dart';

class _ExerciseEntry {
  String name;
  final List<_SetEntry> sets;
  bool expanded;
  File? imageFile;
  String? imageKey;
  String? setsSummary;
  int? calories;
  int? durationMinutes;
  bool analyzing;
  /// True after the user edits the name (so re-estimate can use it as a hint).
  bool nameEditedByUser;
  final TextEditingController nameCtrl;

  _ExerciseEntry({
    required this.name,
    required this.sets,
    required this.expanded,
    this.imageFile,
    this.imageKey,
    this.setsSummary,
    this.calories,
    this.durationMinutes,
    this.analyzing = false,
    this.nameEditedByUser = false,
  }) : nameCtrl = TextEditingController(text: name);

  String get setsOverlay {
    if (setsSummary != null && setsSummary!.isNotEmpty) return setsSummary!;
    final reps = sets.map((s) => '${s.reps}').join(', ');
    return '${sets.length} sets · $reps reps';
  }

  void dispose() {
    nameCtrl.dispose();
  }

  void applyAiName(String aiName) {
    name = aiName;
    if (!nameEditedByUser) {
      nameCtrl.text = aiName;
    }
  }
}

class _SetEntry {
  int reps;
  double weight;
  bool done;

  _SetEntry({this.reps = 10, this.weight = 20.0, required this.done});
}

class WeightLiftingScreen extends ConsumerStatefulWidget {
  const WeightLiftingScreen({super.key});

  @override
  ConsumerState<WeightLiftingScreen> createState() =>
      _WeightLiftingScreenState();
}

class _WeightLiftingScreenState extends ConsumerState<WeightLiftingScreen> {
  final List<_ExerciseEntry> _exercises = [];
  bool _saving = false;

  @override
  void dispose() {
    for (final e in _exercises) {
      e.dispose();
    }
    super.dispose();
  }

  Future<void> _addExerciseFromCamera() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (img == null || !mounted) return;
    HapticFeedback.selectionClick();
    setState(() {
      _exercises.add(
        _ExerciseEntry(
          name: '',
          expanded: true,
          imageFile: File(img.path),
          sets: [_SetEntry(done: false)],
        ),
      );
    });
  }

  void _removeExercise(int idx) {
    setState(() {
      _exercises[idx].dispose();
      _exercises.removeAt(idx);
    });
  }

  void _addSet(int exerciseIdx) {
    setState(() {
      final lastSet = _exercises[exerciseIdx].sets.last;
      _exercises[exerciseIdx].sets.add(
        _SetEntry(reps: lastSet.reps, weight: lastSet.weight, done: false),
      );
      _exercises[exerciseIdx].calories = null;
    });
  }

  void _removeSet(int exerciseIdx, int setIdx) {
    setState(() {
      if (_exercises[exerciseIdx].sets.length > 1) {
        _exercises[exerciseIdx].sets.removeAt(setIdx);
        _exercises[exerciseIdx].calories = null;
      }
    });
  }

  Future<void> _pickPhoto(int index, ImageSource source) async {
    final picker = ImagePicker();
    final img = await picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (img == null || !mounted) return;
    setState(() {
      _exercises[index].imageFile = File(img.path);
      _exercises[index].imageKey = null;
      _exercises[index].calories = null;
    });
  }

  Future<void> _showPhotoSheet(int index) async {
    final lang = ref.read(localeProvider);
    String t(String k) => Translations.t(lang, k);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(LucideIcons.camera, color: AppColors.primary),
                title: Text(t('wl_take_photo')),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(index, ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(LucideIcons.image, color: AppColors.primary),
                title: Text(t('wl_choose_gallery')),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(index, ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _analyzeExercise(int index) async {
    final entry = _exercises[index];
    final lang = ref.read(localeProvider);
    String t(String k) => Translations.t(lang, k);

    if (entry.imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('wl_photo_required'))),
      );
      return;
    }
    if (entry.sets.every((s) => s.reps < 1)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('wl_reps_required'))),
      );
      return;
    }

    setState(() => entry.analyzing = true);
    HapticFeedback.selectionClick();
    try {
      // Only send a name hint if the user corrected/typed one.
      final typed = entry.nameCtrl.text.trim();
      final hint = entry.nameEditedByUser && typed.isNotEmpty
          ? typed
          : (typed.isNotEmpty && entry.calories != null ? typed : null);

      final result =
          await ref.read(exerciseRepositoryProvider).analyzeMachineWorkout(
                image: entry.imageFile!,
                nameHint: hint,
                sets: entry.sets
                    .map((s) => {
                          'reps': s.reps,
                          'weight_kg': s.weight,
                        })
                    .toList(),
              );
      if (!mounted) return;
      final aiName = (result['name'] as String?)?.trim() ?? '';
      setState(() {
        if (aiName.isNotEmpty) {
          entry.applyAiName(aiName);
        } else if (entry.nameCtrl.text.trim().isEmpty) {
          entry.applyAiName(t('wl_unnamed'));
        }
        entry.calories = (result['calories_burned'] as num?)?.toInt();
        entry.durationMinutes =
            (result['duration_minutes'] as num?)?.toInt() ??
                (entry.sets.length * 2).clamp(1, 999);
        entry.setsSummary = result['sets_summary'] as String?;
        entry.imageKey = result['image_url'] as String?;
        entry.analyzing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => entry.analyzing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('wl_analyze_failed')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _saveWorkout() async {
    final lang = ref.read(localeProvider);
    String t(String k) => Translations.t(lang, k);
    if (_saving || _exercises.isEmpty) return;

    for (var i = 0; i < _exercises.length; i++) {
      final e = _exercises[i];
      if (e.imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('wl_photo_required'))),
        );
        return;
      }
      if (e.calories == null) {
        await _analyzeExercise(i);
        if (_exercises[i].calories == null) return;
      }
    }

    setState(() => _saving = true);
    try {
      for (final e in _exercises) {
        final name = e.nameCtrl.text.trim().isNotEmpty
            ? e.nameCtrl.text.trim()
            : (e.name.trim().isNotEmpty ? e.name.trim() : 'Weight training');
        await ref.read(dashboardProvider.notifier).logExercise(
              name: name,
              durationMinutes: e.durationMinutes ?? (e.sets.length * 2),
              caloriesBurned: e.calories!,
              imageUrl: e.imageKey,
              setsSummary: e.setsOverlay,
            );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('failed_save_workout')),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!mounted) return;
    final totalCal =
        _exercises.fold<int>(0, (s, e) => s + (e.calories ?? 0));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${t('calories_burned')}: $totalCal kcal'),
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    String t(String k) => Translations.t(lang, k);
    final totalCal =
        _exercises.fold<int>(0, (s, e) => s + (e.calories ?? 0));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          t('weight_lifting'),
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (_exercises.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _saving ? null : _saveWorkout,
                child: Text(
                  _saving ? '…' : t('save'),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_exercises.isNotEmpty && totalCal > 0)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.flame, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '~$totalCal kcal',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _exercises.isEmpty
                ? _EmptyState(t: t, onScan: _addExerciseFromCamera)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: _exercises.length,
                    itemBuilder: (ctx, i) => _ExerciseCard(
                      entry: _exercises[i],
                      t: t,
                      onRemove: () => _removeExercise(i),
                      onAddSet: () => _addSet(i),
                      onRemoveSet: (si) => _removeSet(i, si),
                      onChanged: () => setState(() {
                        _exercises[i].calories = null;
                      }),
                      onPickPhoto: () => _showPhotoSheet(i),
                      onAnalyze: () => _analyzeExercise(i),
                      onNameEdited: () {
                        setState(() {
                          _exercises[i].nameEditedByUser = true;
                          _exercises[i].name =
                              _exercises[i].nameCtrl.text.trim();
                        });
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.camera, size: 20),
        label: Text(
          t('wl_add_exercise'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: _addExerciseFromCamera,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String Function(String) t;
  final VoidCallback onScan;

  const _EmptyState({required this.t, required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onScan,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.camera,
                  size: 44,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              t('weight_lifting'),
              style: AppTextStyles.screenTitle.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 10),
            Text(
              t('wl_empty_body'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatefulWidget {
  final _ExerciseEntry entry;
  final String Function(String) t;
  final VoidCallback onRemove;
  final VoidCallback onAddSet;
  final void Function(int setIdx) onRemoveSet;
  final VoidCallback onChanged;
  final VoidCallback onPickPhoto;
  final VoidCallback onAnalyze;
  final VoidCallback onNameEdited;

  const _ExerciseCard({
    required this.entry,
    required this.t,
    required this.onRemove,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onChanged,
    required this.onPickPhoto,
    required this.onAnalyze,
    required this.onNameEdited,
  });

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _exp;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _exp = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    if (widget.entry.expanded) _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final t = widget.t;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: entry.nameCtrl,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: t('wl_name_hint'),
                          hintStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPlaceholder,
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                        textCapitalization: TextCapitalization.words,
                        onChanged: (_) => widget.onNameEdited(),
                      ),
                      Text(
                        t('wl_name_edit_hint'),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    LucideIcons.trash2,
                    size: 18,
                    color: AppColors.inactive,
                  ),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
          ),

          // Name is above — machine photo with sets/reps/kcal overlay
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (entry.imageFile != null)
                      Image.file(entry.imageFile!, fit: BoxFit.cover)
                    else
                      ColoredBox(
                        color: AppColors.surfaceMuted,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.camera,
                              size: 36,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              t('wl_photo_hint'),
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(12, 28, 12, 12),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black87],
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                entry.setsOverlay,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            if (entry.calories != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryDark,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${entry.calories} kcal',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (entry.analyzing)
                      ColoredBox(
                        color: Colors.black45,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(
                                color: Colors.white,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                t('wl_analyzing'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: entry.analyzing ? null : widget.onPickPhoto,
                    icon: const Icon(LucideIcons.camera, size: 16),
                    label: Text(t('wl_photo')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: entry.analyzing ? null : widget.onAnalyze,
                    icon: entry.analyzing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(LucideIcons.sparkles, size: 16),
                    label: Text(t('wl_estimate')),
                  ),
                ),
              ],
            ),
          ),

          InkWell(
            onTap: () {
              setState(() => entry.expanded = !entry.expanded);
              entry.expanded ? _ctrl.forward() : _ctrl.reverse();
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Text(
                    t('wl_edit_sets'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: entry.expanded ? 0 : -0.25,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(
                      LucideIcons.chevronDown,
                      size: 18,
                      color: AppColors.inactive,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizeTransition(
            sizeFactor: _exp,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 32,
                        child: Text(
                          'Set',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inactive,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'kg',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inactive,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Reps',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inactive,
                          ),
                        ),
                      ),
                      const SizedBox(width: 52),
                    ],
                  ),
                ),
                ...entry.sets.asMap().entries.map((e) {
                  final si = e.key;
                  final set = e.value;
                  return _SetRow(
                    setIndex: si,
                    set: set,
                    onRemove: entry.sets.length > 1
                        ? () => widget.onRemoveSet(si)
                        : null,
                    onChanged: () {
                      widget.onChanged();
                      setState(() {});
                    },
                  );
                }),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                  child: GestureDetector(
                    onTap: widget.onAddSet,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.plus,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            t('wl_add_set'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SetRow extends StatefulWidget {
  final int setIndex;
  final _SetEntry set;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;

  const _SetRow({
    required this.setIndex,
    required this.set,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _repsCtrl;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(
      text: widget.set.weight.toStringAsFixed(1),
    );
    _repsCtrl = TextEditingController(text: '${widget.set.reps}');
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final set = widget.set;
    final isDone = set.done;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      decoration: BoxDecoration(
        color: isDone
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: isDone
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '${widget.setIndex + 1}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDone ? AppColors.primary : AppColors.inactive,
              ),
            ),
          ),
          Expanded(
            child: _InlineField(
              controller: _weightCtrl,
              suffix: 'kg',
              done: isDone,
              onChanged: (v) {
                set.weight = double.tryParse(v) ?? set.weight;
                widget.onChanged();
              },
            ),
          ),
          Expanded(
            child: _InlineField(
              controller: _repsCtrl,
              suffix: 'x',
              done: isDone,
              onChanged: (v) {
                set.reps = int.tryParse(v) ?? set.reps;
                widget.onChanged();
              },
            ),
          ),
          SizedBox(
            width: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() => set.done = !set.done);
                    widget.onChanged();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: isDone ? AppColors.primary : Colors.transparent,
                      border: Border.all(
                        color: isDone ? AppColors.primary : AppColors.inactive,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: isDone
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ),
                if (widget.onRemove != null) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: widget.onRemove,
                    child: Icon(
                      LucideIcons.x,
                      size: 14,
                      color: AppColors.inactive,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineField extends StatelessWidget {
  final TextEditingController controller;
  final String suffix;
  final bool done;
  final void Function(String) onChanged;

  const _InlineField({
    required this.controller,
    required this.suffix,
    required this.done,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: done ? AppColors.primary : AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          suffixText: suffix,
          suffixStyle: TextStyle(
            fontSize: 13,
            color: done ? AppColors.primary : AppColors.inactive,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
