import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/localization/translations.dart';

// ─── Ingredients Provider ────────────────────────────────────────────────────

final _ingredientsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
      (ref, foodName) async {
        try {
          final encoded = Uri.encodeComponent(foodName);
          final res = await ApiClient.instance.get('food/ingredients/$encoded');
          final data = res.data as Map<String, dynamic>?;
          final list = data?['ingredients'] as List<dynamic>? ?? [];
          return list.cast<Map<String, dynamic>>();
        } catch (_) {
          return [];
        }
      },
    );

// ─── Screen ──────────────────────────────────────────────────────────────────

class FoodDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> log;

  const FoodDetailScreen({super.key, required this.log});

  @override
  ConsumerState<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends ConsumerState<FoodDetailScreen> {
  int _quantity = 1;
  final List<_EditableIngredient> _editedIngredients = [];
  bool _editMode = false;

  Map<String, dynamic> get log => widget.log;

  String _localizedName(String lang) {
    if (lang == 'ar' || lang == 'Darija') {
      if (log['name_ar'] != null) return log['name_ar'] as String;
    } else if (lang == 'fr') {
      if (log['name_fr'] != null) return log['name_fr'] as String;
    }
    return (log['name_en'] ?? log['meal_name'] ?? 'Food') as String;
  }

  String _formatTime(String? isoString) {
    if (isoString == null) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat('h:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final foodName = _localizedName('en'); // use English for AI query
    final ingredientsAsync = ref.watch(_ingredientsProvider(foodName));
    final imageUrl = log['image_url'] as String?;
    final calories = (log['calories'] as num? ?? 0).toInt();
    final protein = (log['protein'] as num? ?? 0).toInt();
    final carbs = (log['carbs'] as num? ?? 0).toInt();
    final fat = (log['fat'] as num? ?? 0).toInt();
    final timeStr = _formatTime(log['created_at']?.toString());
    final displayName = _localizedName(lang);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // ─── Hero image ───────────────────────────────────────────────
          Stack(
            children: [
              SizedBox(
                height: 300,
                width: double.infinity,
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, e, __) => _imagePlaceholder(),
                      )
                    : _imagePlaceholder(),
              ),
              // Top gradient + back button
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.55),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                    child: const Icon(
                      LucideIcons.arrowLeft,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              // Time stamp overlay
              if (timeStr.isNotEmpty)
                Positioned(
                  bottom: 14,
                  left: 18,
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.clock,
                        size: 13,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // ─── Content card ─────────────────────────────────────────────
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + quantity stepper
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: AppTextStyles.sectionHeader.copyWith(
                              fontSize: 20,
                              color: Colors.black,
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
                    const SizedBox(height: 18),

                    // Calories highlight
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7F9),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              LucideIcons.flame,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Calories',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF888888),
                                ),
                              ),
                              Text(
                                '${calories * _quantity}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Macro tiles row
                    Row(
                      children: [
                        _MacroCard(
                          label: Translations.t(lang, 'macro_protein'),
                          value: '${protein * _quantity}g',
                          color: AppColors.protein,
                          icon: LucideIcons.beef,
                        ),
                        const SizedBox(width: 10),
                        _MacroCard(
                          label: Translations.t(lang, 'macro_carbs'),
                          value: '${carbs * _quantity}g',
                          color: AppColors.carbs,
                          icon: LucideIcons.wheat,
                        ),
                        const SizedBox(width: 10),
                        _MacroCard(
                          label: Translations.t(lang, 'macro_fats'),
                          value: '${fat * _quantity}g',
                          color: AppColors.fats,
                          icon: LucideIcons.droplets,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Ingredients section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ingredients',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _editMode = !_editMode),
                          child: Row(
                            children: [
                              Icon(
                                _editMode
                                    ? LucideIcons.check
                                    : LucideIcons.pencil,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _editMode ? 'Done editing' : '+ Edit',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Ingredients list
                    ingredientsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(
                                color: AppColors.primary,
                                strokeWidth: 2,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Loading ingredients…',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.inactive,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      error: (e, _) => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Could not load ingredient details.',
                          style: TextStyle(color: AppColors.inactive),
                        ),
                      ),
                      data: (ingredients) {
                        // Sync editable list first time
                        if (_editedIngredients.isEmpty &&
                            ingredients.isNotEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() {
                                _editedIngredients.clear();
                                _editedIngredients.addAll(
                                  ingredients.map(
                                    (i) => _EditableIngredient(
                                      name: i['name']?.toString() ?? '',
                                      amount: i['amount']?.toString() ?? '',
                                      calories:
                                          (i['calories'] as num? ?? 0).toInt(),
                                    ),
                                  ),
                                );
                              });
                            }
                          });
                        }

                        final display = _editedIngredients.isEmpty
                            ? ingredients
                                .map(
                                  (i) => _EditableIngredient(
                                    name: i['name']?.toString() ?? '',
                                    amount: i['amount']?.toString() ?? '',
                                    calories:
                                        (i['calories'] as num? ?? 0).toInt(),
                                  ),
                                )
                                .toList()
                            : _editedIngredients;

                        if (display.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'No ingredient data available.',
                              style: TextStyle(color: AppColors.inactive),
                            ),
                          );
                        }

                        return Column(
                          children: display.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final ing = entry.value;
                            if (_editMode) {
                              return _EditableIngredientTile(
                                ingredient: ing,
                                onChanged: (updated) {
                                  setState(() {
                                    if (_editedIngredients.length > idx) {
                                      _editedIngredients[idx] = updated;
                                    }
                                  });
                                },
                              );
                            }
                            return _IngredientTile(ingredient: ing);
                          }).toList(),
                        );
                      },
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // ─── Bottom action buttons ───────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _editMode = !_editMode),
                  icon: Icon(
                    LucideIcons.penLine,
                    size: 16,
                    color: Colors.black,
                  ),
                  label: const Text(
                    'Fix Results',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.black, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
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

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: const Center(
        child: Icon(LucideIcons.utensils, size: 64, color: Colors.white24),
      ),
    );
  }
}

// ─── Quantity Stepper ────────────────────────────────────────────────────────

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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          _StepBtn(icon: LucideIcons.plus, onTap: () => onChanged(value + 1)),
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
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: onTap != null ? Colors.black : Colors.black12,
        ),
        child: Icon(icon, size: 14, color: Colors.white),
      ),
    );
  }
}

// ─── Macro Card ───────────────────────────────────────────────────────────────

class _MacroCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _MacroCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.18), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Ingredient models & tiles ────────────────────────────────────────────────

class _EditableIngredient {
  String name;
  String amount;
  int calories;
  _EditableIngredient({
    required this.name,
    required this.amount,
    required this.calories,
  });
}

class _IngredientTile extends StatelessWidget {
  final _EditableIngredient ingredient;
  const _IngredientTile({required this.ingredient});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ingredient.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Text(
                  ingredient.amount,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${ingredient.calories} cal',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableIngredientTile extends StatefulWidget {
  final _EditableIngredient ingredient;
  final ValueChanged<_EditableIngredient> onChanged;
  const _EditableIngredientTile({
    required this.ingredient,
    required this.onChanged,
  });

  @override
  State<_EditableIngredientTile> createState() =>
      _EditableIngredientTileState();
}

class _EditableIngredientTileState extends State<_EditableIngredientTile> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _calCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.ingredient.name);
    _amountCtrl = TextEditingController(text: widget.ingredient.amount);
    _calCtrl = TextEditingController(
      text: widget.ingredient.calories.toString(),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _calCtrl.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onChanged(
      _EditableIngredient(
        name: _nameCtrl.text,
        amount: _amountCtrl.text,
        calories: int.tryParse(_calCtrl.text) ?? widget.ingredient.calories,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 13, color: Colors.black);
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: Color(0xFFDDDDDD)),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _nameCtrl,
                  onChanged: (_) => _notify(),
                  style: style,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(fontSize: 11),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    enabledBorder: border,
                    focusedBorder: border,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _amountCtrl,
                  onChanged: (_) => _notify(),
                  style: style,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    labelStyle: TextStyle(fontSize: 11),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    enabledBorder: border,
                    focusedBorder: border,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _calCtrl,
                  onChanged: (_) => _notify(),
                  keyboardType: TextInputType.number,
                  style: style,
                  decoration: const InputDecoration(
                    labelText: 'Calories',
                    labelStyle: TextStyle(fontSize: 11),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    enabledBorder: border,
                    focusedBorder: border,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
