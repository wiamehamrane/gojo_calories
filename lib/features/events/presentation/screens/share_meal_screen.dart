import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_handler.dart';
import '../providers/shared_meals_provider.dart';

/// Prefill data when sharing from the food detail screen.
class ShareMealPrefill {
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final List<String> ingredients;
  final String? imageUrl;

  const ShareMealPrefill({
    this.name = '',
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.ingredients = const [],
    this.imageUrl,
  });
}

/// Share a meal you prepared with the community: photo of the final
/// product, macros, ingredients, and how to cook it.
class ShareMealScreen extends ConsumerStatefulWidget {
  final ShareMealPrefill? prefill;

  const ShareMealScreen({super.key, this.prefill});

  @override
  ConsumerState<ShareMealScreen> createState() => _ShareMealScreenState();
}

class _ShareMealScreenState extends ConsumerState<ShareMealScreen> {
  final _nameCtrl = TextEditingController();
  final _ingredientsCtrl = TextEditingController();
  final _instructionsCtrl = TextEditingController();
  final _caloriesCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbsCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();

  File? _image;
  String? _existingImageUrl; // photo already stored for this food log
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final p = widget.prefill;
    if (p != null) {
      _nameCtrl.text = p.name;
      if (p.calories > 0) _caloriesCtrl.text = '${p.calories}';
      if (p.protein > 0) _proteinCtrl.text = '${p.protein}';
      if (p.carbs > 0) _carbsCtrl.text = '${p.carbs}';
      if (p.fat > 0) _fatCtrl.text = '${p.fat}';
      _ingredientsCtrl.text = p.ingredients.join('\n');
      _existingImageUrl =
          (p.imageUrl != null && p.imageUrl!.isNotEmpty) ? p.imageUrl : null;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ingredientsCtrl.dispose();
    _instructionsCtrl.dispose();
    _caloriesCtrl.dispose();
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    HapticFeedback.selectionClick();
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showError('Give your meal a name.');
      return;
    }
    if (_image == null && _existingImageUrl == null) {
      _showError('Add a photo of the final product.');
      return;
    }
    final ingredients = _ingredientsCtrl.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (ingredients.isEmpty) {
      _showError('List at least one ingredient.');
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(sharedMealsProvider.notifier).shareMeal(
            name: name,
            ingredients: ingredients,
            instructions: _instructionsCtrl.text.trim(),
            calories: int.tryParse(_caloriesCtrl.text.trim()) ?? 0,
            protein: int.tryParse(_proteinCtrl.text.trim()) ?? 0,
            carbs: int.tryParse(_carbsCtrl.text.trim()) ?? 0,
            fat: int.tryParse(_fatCtrl.text.trim()) ?? 0,
            imageFile: _image,
            sourceImageUrl: _image == null ? _existingImageUrl : null,
          );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meal shared with the community! 🍽️'),
          backgroundColor: AppColors.primaryDark,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(AppErrorHandler.message(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Share a meal',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _buildImagePicker(),
          const SizedBox(height: 20),
          _label('Meal name'),
          _textField(
            controller: _nameCtrl,
            hint: 'e.g. High-protein chicken bowl',
          ),
          const SizedBox(height: 18),
          _label('Macros (per serving)'),
          Row(
            children: [
              Expanded(child: _macroField(_caloriesCtrl, 'kcal')),
              const SizedBox(width: 8),
              Expanded(child: _macroField(_proteinCtrl, 'Protein g')),
              const SizedBox(width: 8),
              Expanded(child: _macroField(_carbsCtrl, 'Carbs g')),
              const SizedBox(width: 8),
              Expanded(child: _macroField(_fatCtrl, 'Fats g')),
            ],
          ),
          const SizedBox(height: 18),
          _label('Ingredients (one per line)'),
          _textField(
            controller: _ingredientsCtrl,
            hint: '200g chicken breast\n100g rice\n1 tbsp olive oil',
            maxLines: 5,
          ),
          const SizedBox(height: 18),
          _label('How to cook it'),
          _textField(
            controller: _instructionsCtrl,
            hint: 'Describe the steps to prepare this meal…',
            maxLines: 6,
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Share meal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    DecorationImage? preview;
    if (_image != null) {
      preview = DecorationImage(image: FileImage(_image!), fit: BoxFit.cover);
    } else if (_existingImageUrl != null) {
      preview = DecorationImage(
        image: NetworkImage(_existingImageUrl!),
        fit: BoxFit.cover,
      );
    }
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 190,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          image: preview,
        ),
        child: preview == null
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.camera, size: 32, color: AppColors.inactive),
                  SizedBox(height: 10),
                  Text(
                    'Add a photo of the final product',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              )
            : Align(
                alignment: Alignment.topRight,
                child: Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.pencil,
                      size: 14, color: Colors.white),
                ),
              ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppColors.textPlaceholder,
          fontSize: 14,
        ),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _macroField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: AppColors.textPlaceholder,
          fontSize: 11,
        ),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      ),
    );
  }
}
