import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../stats/presentation/providers/dashboard_provider.dart';

// ────────────────────────────────────────────────────────────────────────────
// Data model for a single exercise entry in the session
// ────────────────────────────────────────────────────────────────────────────
class _ExerciseEntry {
  final String name;
  final List<_SetEntry> sets;
  bool expanded;

  _ExerciseEntry({
    required this.name,
    required this.sets,
    required this.expanded,
  });
}

class _SetEntry {
  int reps;
  double weight; // kg
  bool done;

  _SetEntry({this.reps = 10, this.weight = 20.0, required this.done});
}

// ────────────────────────────────────────────────────────────────────────────
// Preset exercise names
// ────────────────────────────────────────────────────────────────────────────
const _presetExercises = [
  'Bench Press',
  'Squat',
  'Deadlift',
  'Overhead Press',
  'Barbell Row',
  'Pull-Up',
  'Dumbbell Curl',
  'Tricep Dip',
  'Leg Press',
  'Lat Pulldown',
  'Cable Row',
  'Hip Thrust',
  'Romanian Deadlift',
  'Incline Bench Press',
  'Face Pull',
];

// ────────────────────────────────────────────────────────────────────────────
// MET-based calorie estimation: ~5.0 METs for moderate weightlifting
// Formula: Cal = MET × weight_kg × time_hours
// We estimate total set time as (total sets × avg work + rest × sets)
// ────────────────────────────────────────────────────────────────────────────
int _estimateCalories(List<_ExerciseEntry> exercises) {
  final totalSets = exercises.fold<int>(0, (s, e) => s + e.sets.length);
  if (totalSets == 0) return 0;
  const double bodyWeightKg = 75.0; // assumed
  const double metValue = 5.0;
  final double minutesTotal =
      totalSets * 2.5; // ~2.5 min per set including rest
  return (metValue * bodyWeightKg * (minutesTotal / 60)).round();
}

// ────────────────────────────────────────────────────────────────────────────
// Screen
// ────────────────────────────────────────────────────────────────────────────
class WeightLiftingScreen extends ConsumerStatefulWidget {
  const WeightLiftingScreen({super.key});

  @override
  ConsumerState<WeightLiftingScreen> createState() =>
      _WeightLiftingScreenState();
}

class _WeightLiftingScreenState extends ConsumerState<WeightLiftingScreen> {
  final List<_ExerciseEntry> _exercises = [];
  bool _saved = false;

  void _addExercise(String name) {
    setState(() {
      _exercises.add(
        _ExerciseEntry(
          name: name,
          expanded: true,
          sets: [_SetEntry(done: false)],
        ),
      );
    });
  }

  void _removeExercise(int idx) {
    setState(() => _exercises.removeAt(idx));
  }

  void _addSet(int exerciseIdx) {
    setState(() {
      final lastSet = _exercises[exerciseIdx].sets.last;
      _exercises[exerciseIdx].sets.add(
        _SetEntry(reps: lastSet.reps, weight: lastSet.weight, done: false),
      );
    });
  }

  void _removeSet(int exerciseIdx, int setIdx) {
    setState(() {
      if (_exercises[exerciseIdx].sets.length > 1) {
        _exercises[exerciseIdx].sets.removeAt(setIdx);
      }
    });
  }

  void _saveWorkout(String lang) {
    final calories = _estimateCalories(_exercises);
    if (calories == 0) return;

    ref
        .read(dashboardProvider.notifier)
        .logFood(
          calories: calories,
          protein: 0,
          carbs: 0,
          fat: 0,
          name: 'Weight Lifting (${_exercises.map((e) => e.name).join(', ')})',
        );

    setState(() => _saved = true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🏋️ ${Translations.t(lang, 'calories_burned')}: $calories kcal',
        ),
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _showExercisePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ExercisePickerSheet(
        onSelect: (name) {
          Navigator.pop(context);
          _addExercise(name);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    String t(String k) => Translations.t(lang, k);
    final estimatedCal = _estimateCalories(_exercises);
    final totalSets = _exercises.fold<int>(0, (s, e) => s + e.sets.length);
    final doneSets = _exercises.fold<int>(
      0,
      (s, e) => s + e.sets.where((st) => st.done).length,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          t('weight_lifting'),
          style: const TextStyle(
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
                onPressed: _saved ? null : () => _saveWorkout(lang),
                child: Text(
                  _saved ? '✓' : t('save'),
                  style: TextStyle(
                    color: _saved ? AppColors.inactive : AppColors.primary,
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
          // ── Summary Strip ──────────────────────────────────────────────────
          if (_exercises.isNotEmpty)
            _buildSummaryStrip(estimatedCal, totalSets, doneSets, lang),

          // ── Exercise List ─────────────────────────────────────────────────
          Expanded(
            child: _exercises.isEmpty
                ? _buildEmptyState(lang)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: _exercises.length,
                    itemBuilder: (ctx, i) => _ExerciseCard(
                      entry: _exercises[i],
                      index: i,
                      onRemove: () => _removeExercise(i),
                      onAddSet: () => _addSet(i),
                      onRemoveSet: (si) => _removeSet(i, si),
                      onSetChanged: () => setState(() {}),
                    ),
                  ),
          ),
        ],
      ),

      // ── FAB: Add Exercise ─────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        icon: const Icon(LucideIcons.plus, size: 20),
        label: Text(
          'Add Exercise',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: _showExercisePicker,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSummaryStrip(int cal, int total, int done, String lang) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StripStat(
            label: Translations.t(lang, 'calories_burned'),
            value: '~$cal kcal',
            icon: LucideIcons.flame,
          ),
          Container(width: 1, height: 32, color: Colors.white24),
          _StripStat(
            label: 'Sets',
            value: '$done/$total',
            icon: LucideIcons.check,
          ),
          Container(width: 1, height: 32, color: Colors.white24),
          _StripStat(
            label: 'Exercises',
            value: '${_exercises.length}',
            icon: LucideIcons.dumbbell,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.dumbbell,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              Translations.t(lang, 'weight_lifting'),
              style: AppTextStyles.screenTitle.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 10),
            Text(
              'Tap "Add Exercise" to build your session.\nTrack sets, reps, and weight — then log calories.',
              textAlign: TextAlign.center,
              style: const TextStyle(
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

// ────────────────────────────────────────────────────────────────────────────
// Summary strip stat widget
// ────────────────────────────────────────────────────────────────────────────
class _StripStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StripStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.white),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Exercise Card (expandable, with set rows)
// ────────────────────────────────────────────────────────────────────────────
class _ExerciseCard extends StatefulWidget {
  final _ExerciseEntry entry;
  final int index;
  final VoidCallback onRemove;
  final VoidCallback onAddSet;
  final void Function(int setIdx) onRemoveSet;
  final VoidCallback onSetChanged;

  const _ExerciseCard({
    required this.entry,
    required this.index,
    required this.onRemove,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onSetChanged,
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
          // ── Header ────────────────────────────────────────────────────────
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            onTap: () {
              setState(() => entry.expanded = !entry.expanded);
              entry.expanded ? _ctrl.forward() : _ctrl.reverse();
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.index + 1}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${entry.sets.length} set${entry.sets.length != 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      LucideIcons.trash2,
                      size: 18,
                      color: AppColors.inactive,
                    ),
                    onPressed: widget.onRemove,
                  ),
                  AnimatedRotation(
                    turns: entry.expanded ? 0 : -0.25,
                    duration: const Duration(milliseconds: 220),
                    child: const Icon(
                      LucideIcons.chevronDown,
                      size: 20,
                      color: AppColors.inactive,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Sets Table (animated expand) ──────────────────────────────────
          SizeTransition(
            sizeFactor: _exp,
            child: Column(
              children: [
                // Header row
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
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
                          'Weight (kg)',
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
                      SizedBox(
                        width: 52,
                        child: Text(
                          'Done',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inactive,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Set rows
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
                      widget.onSetChanged();
                      setState(() {});
                    },
                  );
                }),

                // Add Set button
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
                          const Icon(
                            LucideIcons.plus,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Add Set',
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

// ────────────────────────────────────────────────────────────────────────────
// Individual set row with inline editable fields
// ────────────────────────────────────────────────────────────────────────────
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
          // Set number
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

          // Weight field
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

          // Reps field
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

          // Done checkbox + remove
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
                    child: const Icon(
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

// ────────────────────────────────────────────────────────────────────────────
// Exercise Picker Bottom Sheet
// ────────────────────────────────────────────────────────────────────────────
class _ExercisePickerSheet extends StatefulWidget {
  final void Function(String name) onSelect;

  const _ExercisePickerSheet({required this.onSelect});

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  final _customCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _presetExercises
        .where((e) => e.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    final safeBottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: safeBottom + 16,
        left: 20,
        right: 20,
        top: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          const Text(
            'Choose Exercise',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Search field
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Search or type custom…',
                hintStyle: TextStyle(color: AppColors.textPlaceholder),
                prefixIcon: Icon(
                  LucideIcons.search,
                  size: 18,
                  color: AppColors.inactive,
                ),
                prefixIconConstraints: BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
              onSubmitted: (v) {
                if (v.trim().isNotEmpty) widget.onSelect(v.trim());
              },
            ),
          ),
          const SizedBox(height: 10),

          // Preset list (max height)
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: filtered.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: AppColors.border),
              itemBuilder: (ctx, i) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  leading: const Icon(
                    LucideIcons.dumbbell,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    filtered[i],
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  onTap: () => widget.onSelect(filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
