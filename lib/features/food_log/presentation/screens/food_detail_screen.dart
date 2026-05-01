import 'dart:io';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/providers/selected_date_provider.dart';
import '../../../dashboard/providers/dashboard_provider.dart';
import '../../../dashboard/providers/history_provider.dart';
import '../../../dashboard/providers/weekly_stats_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class FoodDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> log;
  const FoodDetailScreen({super.key, required this.log});

  @override
  ConsumerState<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends ConsumerState<FoodDetailScreen> {
  int _quantity = 1;
  bool _saved = false;
  bool _savingInProgress = false;

  // Ingredients — seeded from log data or fetched lazily
  List<_Ingredient> _ingredients = [];
  bool _ingredientsLoading = false;

  late Map<String, dynamic> _log;

  Map<String, dynamic> get log => _log;

  // ── helpers ─────────────────────────────────────────────────────────────────

  String _displayName(String lang) {
    if (lang == 'ar' || lang == 'Darija') {
      return (log['name_ar'] ?? log['name_en'] ?? log['meal_name'] ?? 'Food') as String;
    } else if (lang == 'fr') {
      return (log['name_fr'] ?? log['name_en'] ?? log['meal_name'] ?? 'Food') as String;
    }
    return (log['name_en'] ?? log['meal_name'] ?? 'Food') as String;
  }

  String _localTime() {
    final raw = log['created_at']?.toString();
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('h:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  void initState() {
    super.initState();
    _log = Map<String, dynamic>.from(widget.log);
    _seedIngredients();
  }

  Future<void> _navigateToFixResults() async {
    final updatedLog = await context.push<Map<String, dynamic>>('/fix-results', extra: _log);
    if (updatedLog != null) {
      setState(() {
        _log = updatedLog;
        _seedIngredients(); // Re-seed ingredients with the new data
      });
    }
  }

  void _seedIngredients() {
    // Prefer ingredients already in the log from analyze response
    final raw = log['ingredients'];
    if (raw is List && raw.isNotEmpty) {
      _ingredients = raw.map((e) {
        final m = e as Map<String, dynamic>;
        return _Ingredient(
          name: m['name']?.toString() ?? '',
          amount: m['amount']?.toString() ?? '',
          calories: (m['calories'] as num? ?? 0).toInt(),
        );
      }).toList();
    } else {
      // Fetch from backend lazily
      _fetchIngredients();
    }
  }

  Future<void> _fetchIngredients() async {
    final foodName = (log['name_en'] ?? log['meal_name'] ?? '') as String;
    if (foodName.isEmpty) return;
    setState(() => _ingredientsLoading = true);
    try {
      final encoded = Uri.encodeComponent(foodName);
      final res = await ApiClient.instance.get('food/ingredients/$encoded');
      final data = res.data as Map<String, dynamic>?;
      final list = (data?['ingredients'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      if (mounted) {
        setState(() {
          _ingredients = list
              .map((e) => _Ingredient(
                    name: e['name']?.toString() ?? '',
                    amount: e['amount']?.toString() ?? '',
                    calories: (e['calories'] as num? ?? 0).toInt(),
                  ))
              .toList();
        });
      }
    } catch (_) {
      // silently fail – user can manually add
    } finally {
      if (mounted) setState(() => _ingredientsLoading = false);
    }
  }

  Future<void> _toggleSave() async {
    if (_savingInProgress) return;
    setState(() { _savingInProgress = true; _saved = !_saved; });
    try {
      // Optimistic: just toggle locally; backend save could be added later
      await Future.delayed(const Duration(milliseconds: 300));
    } finally {
      if (mounted) setState(() => _savingInProgress = false);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_saved ? 'Saved to your food library' : 'Removed from saved foods'),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _share() {
    final lang = ref.read(localeProvider);
    final name = _displayName(lang);
    final cal = (log['calories'] as num? ?? 0).toInt() * _quantity;
    SharePlus.instance.share(
      ShareParams(text: 'I just logged $name — $cal kcal 🔥  via GojoCalories'),
    );
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ActionSheet(
        onDelete: () {
          Navigator.pop(context); // close sheet
          Navigator.pop(context); // go back
        },
        onChangePic: () {
          Navigator.pop(context);
          // future: open image picker to replace photo
        },
      ),
    );
  }

  void _addIngredient() {
    setState(() {
      _ingredients.add(_Ingredient(name: '', amount: '', calories: 0));
    });
  }

  // ── build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final displayName = _displayName(lang);
    final imageUrl = log['image_url'] as String?;
    final calories = (log['calories'] as num? ?? 0).toInt();
    final protein = (log['protein'] as num? ?? 0).toInt();
    final carbs = (log['carbs'] as num? ?? 0).toInt();
    final fat = (log['fat'] as num? ?? 0).toInt();
    final timeStr = _localTime();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        body: Column(
          children: [
            // ─── Hero Image (full-bleed) ─────────────────────────────────
            Stack(
              children: [
                // Photo
                SizedBox(
                  height: 310,
                  width: double.infinity,
                  child: _buildHeroImage(imageUrl),
                ),

                // Dark gradient at top for legibility
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withValues(alpha: 0.65), Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

                // Bottom gradient for card overlap
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.white],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

                // ── Top bar: back + "Nutrition" + save + share + 3-dot ──
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      _CircleIconBtn(
                        icon: LucideIcons.arrowLeft,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      const Text(
                        'Nutrition',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      _CircleIconBtn(
                        icon: _saved ? LucideIcons.bookmark : LucideIcons.bookmark,
                        filled: _saved,
                        onTap: _toggleSave,
                      ),
                      const SizedBox(width: 8),
                      _CircleIconBtn(
                        icon: LucideIcons.share,
                        onTap: _share,
                      ),
                      const SizedBox(width: 8),
                      _CircleIconBtn(
                        icon: LucideIcons.ellipsis,
                        onTap: _showMenu,
                      ),
                    ],
                  ),
                ),

                // ── Time stamp bottom-left ───────────────────────────────
                if (timeStr.isNotEmpty)
                  Positioned(
                    bottom: 28,
                    left: 18,
                    child: Row(
                      children: [
                        const Icon(LucideIcons.bookmark, size: 14, color: Colors.black54),
                        const SizedBox(width: 5),
                        Text(
                          timeStr,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            // ─── White card content ──────────────────────────────────────
            Expanded(
              child: Container(
                color: Colors.white,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + stepper
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _QuantityStepper(
                            value: _quantity,
                            onChanged: (v) => setState(() => _quantity = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Calories floating card ──────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 42, height: 42,
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.flame, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Calories', style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
                                Text(
                                  '${calories * _quantity}',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Macro row ────────────────────────────────────────
                      Row(
                        children: [
                          _MacroTile(
                            label: Translations.t(ref.watch(localeProvider), 'macro_protein'),
                            value: '${protein * _quantity}g',
                            icon: LucideIcons.beef,
                            color: AppColors.protein,
                          ),
                          const SizedBox(width: 10),
                          _MacroTile(
                            label: Translations.t(ref.watch(localeProvider), 'macro_carbs'),
                            value: '${carbs * _quantity}g',
                            icon: LucideIcons.wheat,
                            color: AppColors.carbs,
                          ),
                          const SizedBox(width: 10),
                          _MacroTile(
                            label: Translations.t(ref.watch(localeProvider), 'macro_fats'),
                            value: '${fat * _quantity}g',
                            icon: LucideIcons.droplets,
                            color: AppColors.fats,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Pagination dots (UI only, matches screenshot) ───
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Dot(active: true),
                          const SizedBox(width: 6),
                          _Dot(active: false),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Ingredients section ──────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Ingredients',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                          GestureDetector(
                            onTap: _addIngredient,
                            child: const Row(
                              children: [
                                Icon(LucideIcons.plus, size: 14, color: Color(0xFF888888)),
                                SizedBox(width: 4),
                                Text(
                                  'Add more',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF888888),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Loading state
                      if (_ingredientsLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                          ),
                        )
                      else if (_ingredients.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: GestureDetector(
                            onTap: _addIngredient,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFEEEEEE), style: BorderStyle.solid),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.plus, size: 16, color: Color(0xFF888888)),
                                  SizedBox(width: 8),
                                  Text('Add ingredient', style: TextStyle(color: Color(0xFF888888), fontSize: 14)),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        ..._ingredients.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final ing = entry.value;
                          return _IngredientRow(
                            ingredient: ing,
                            onChanged: (updated) {
                              setState(() => _ingredients[idx] = updated);
                            },
                            onDelete: () {
                              setState(() => _ingredients.removeAt(idx));
                            },
                          );
                        }),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        // ─── Bottom buttons: Fix Results + Done ──────────────────────────
        bottomNavigationBar: Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(
            20, 8, 20, MediaQuery.of(context).padding.bottom + 12,
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _navigateToFixResults,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.sparkles, size: 15, color: Colors.black),
                        SizedBox(width: 7),
                        Text(
                          'Fix Results',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    final selectedDate = ref.read(selectedDateProvider);
                    ref.invalidate(historyProvider(selectedDate));
                    ref.invalidate(weeklyStatsProvider);
                    ref.invalidate(dashboardProvider);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Done',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroImage(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      // Local file path (camera/gallery before upload completes)
      if (imageUrl.startsWith('file://') || (imageUrl.startsWith('/') && !imageUrl.startsWith('/uploads/'))) {
        final path = imageUrl.replaceFirst('file://', '');
        return Image.file(
          File(path),
          fit: BoxFit.cover,
          errorBuilder: (_, e, s) => _placeholder(),
        );
      }
      // Relative network path
      if (imageUrl.startsWith('/uploads/')) {
        final fullUrl = '${ApiClient.instance.options.baseUrl.replaceAll('/api/', '')}$imageUrl';
        return Image.network(
          fullUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, e, s) => _placeholder(),
          loadingBuilder: (ctx, child, progress) {
            if (progress == null) return child;
            return _ShimmerPlaceholder();
          },
        );
      }
      // Network image — show shimmer while loading, never fallback to placeholder mid-load
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, e, s) => _placeholder(),
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child; // fully loaded
          // Show animated shimmer while loading
          return _ShimmerPlaceholder();
        },
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/avocado.svg',
              width: 56,
              height: 56,
            ),
            const SizedBox(height: 10),
            const Text(
              'No photo',
              style: TextStyle(color: Colors.white30, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Circle icon button with optional filled state
// ─────────────────────────────────────────────────────────────────────────────

class _CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  const _CircleIconBtn({required this.icon, required this.onTap, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.45),
        ),
        child: Icon(icon, size: 18, color: filled ? Colors.yellow.shade200 : Colors.white),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quantity Stepper
// ─────────────────────────────────────────────────────────────────────────────

class _QuantityStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _QuantityStepper({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          _StepBtn(
            icon: LucideIcons.minus,
            onTap: value > 1 ? () => onChanged(value - 1) : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '$value',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black),
            ),
          ),
          _StepBtn(
            icon: LucideIcons.plus,
            onTap: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: onTap != null ? Colors.black : Colors.black26,
        ),
        child: Icon(icon, size: 14, color: Colors.white),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Macro Tile (compact — matches screenshot)
// ─────────────────────────────────────────────────────────────────────────────

class _MacroTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _MacroTile({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page indicator dots
// ─────────────────────────────────────────────────────────────────────────────

class _Dot extends StatelessWidget {
  final bool active;
  const _Dot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 20 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? Colors.black : const Color(0xFFDDDDDD),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ingredient model
// ─────────────────────────────────────────────────────────────────────────────

class _Ingredient {
  String name;
  String amount;
  int calories;
  _Ingredient({required this.name, required this.amount, required this.calories});
}

// ─────────────────────────────────────────────────────────────────────────────
// Ingredient row — inline editable on tap
// ─────────────────────────────────────────────────────────────────────────────

class _IngredientRow extends StatefulWidget {
  final _Ingredient ingredient;
  final ValueChanged<_Ingredient> onChanged;
  final VoidCallback onDelete;
  const _IngredientRow({required this.ingredient, required this.onChanged, required this.onDelete});

  @override
  State<_IngredientRow> createState() => _IngredientRowState();
}

class _IngredientRowState extends State<_IngredientRow> {
  bool _editing = false;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _calCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.ingredient.name);
    _amountCtrl = TextEditingController(text: widget.ingredient.amount);
    _calCtrl = TextEditingController(text: widget.ingredient.calories.toString());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _calCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.onChanged(_Ingredient(
      name: _nameCtrl.text,
      amount: _amountCtrl.text,
      calories: int.tryParse(_calCtrl.text) ?? widget.ingredient.calories,
    ));
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _editing = !_editing),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.ingredient.name.isNotEmpty ? widget.ingredient.name : 'New ingredient',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: widget.ingredient.name.isNotEmpty ? Colors.black : const Color(0xFFAAAAAA),
                            ),
                          ),
                          if (widget.ingredient.calories > 0) ...[
                            const Text(' • ', style: TextStyle(color: Color(0xFFCCCCCC))),
                            Text(
                              '${widget.ingredient.calories} cal',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF888888)),
                            ),
                          ],
                        ],
                      ),
                      if (widget.ingredient.amount.isNotEmpty)
                        Text(
                          widget.ingredient.amount,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: widget.onDelete,
                  child: const Icon(LucideIcons.x, size: 16, color: Color(0xFFCCCCCC)),
                ),
              ],
            ),
          ),
        ),

        // Inline edit fields (expand on tap)
        if (_editing)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            child: Column(
              children: [
                _Field(ctrl: _nameCtrl, label: 'Name'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _Field(ctrl: _amountCtrl, label: 'Amount')),
                    const SizedBox(width: 8),
                    Expanded(child: _Field(ctrl: _calCtrl, label: 'Calories', numeric: true)),
                  ],
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _save,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Save',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),

        const Divider(height: 1, color: Color(0xFFF0F0F0)),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final bool numeric;
  const _Field({required this.ctrl, required this.label, this.numeric = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 13, color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 11),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.black, width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Sheet (3-dot menu)
// ─────────────────────────────────────────────────────────────────────────────

class _ActionSheet extends StatelessWidget {
  final VoidCallback onDelete;
  final VoidCallback onChangePic;
  const _ActionSheet({required this.onDelete, required this.onChangePic});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(color: const Color(0xFFDDDDDD), borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          _SheetTile(icon: LucideIcons.image, label: 'Change photo', onTap: onChangePic),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          _SheetTile(
            icon: LucideIcons.trash2,
            label: 'Remove from log',
            onTap: onDelete,
            danger: true,
          ),
        ],
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  const _SheetTile({required this.icon, required this.label, required this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFCC2200) : Colors.black;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 14),
            Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer placeholder — shown while a network image loads
// ─────────────────────────────────────────────────────────────────────────────

class _ShimmerPlaceholder extends StatefulWidget {
  const _ShimmerPlaceholder();

  @override
  State<_ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<_ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Container(
        color: Color.lerp(
          const Color(0xFF1C1C1C),
          const Color(0xFF2E2E2E),
          _anim.value,
        ),
      ),
    );
  }
}
