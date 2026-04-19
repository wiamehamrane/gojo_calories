import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gojocalories/core/theme/app_colors.dart';
import 'package:gojocalories/core/network/api_client.dart';

class WeightSetupScreen extends StatefulWidget {
  const WeightSetupScreen({super.key});

  @override
  State<WeightSetupScreen> createState() => _WeightSetupScreenState();
}

class _WeightSetupScreenState extends State<WeightSetupScreen> {
  bool _isLoading = false;
  bool _isKg = true; // true = kg, false = lbs

  final _currentWeightCtrl = TextEditingController();
  final _goalWeightCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();

  @override
  void dispose() {
    _currentWeightCtrl.dispose();
    _goalWeightCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitWeights() async {
    final currentStr = _currentWeightCtrl.text.trim();
    final goalStr = _goalWeightCtrl.text.trim();
    final ageStr = _ageCtrl.text.trim();

    if (currentStr.isEmpty || goalStr.isEmpty || ageStr.isEmpty) {
      _showError('Please fill out all fields.');
      return;
    }

    final currentWt = double.tryParse(currentStr);
    final goalWt = double.tryParse(goalStr);
    final age = int.tryParse(ageStr);

    if (currentWt == null || goalWt == null || age == null) {
      _showError('Please enter valid numbers.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final unit = _isKg ? 'kg' : 'lbs';
      
      final res = await ApiClient.instance.put('auth/me/weight', data: {
        'current_weight': currentWt,
        'goal_weight': goalWt,
        'weight_unit': unit,
        'age': age,
      });

      if (res.statusCode == 200) {
        if (mounted) context.go('/onboarding/paywall');
      } else {
        _showError('Failed to save weight. Please try again.');
      }
    } catch (e) {
      _showError('Failed to connect to the server. Please check your connection.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.go('/auth'),
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Let\'s set your goals.',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.15,
                    letterSpacing: -0.8,
                  ),
                ).animate().slideY(begin: 0.1, duration: 500.ms).fadeIn(),

                const SizedBox(height: 8),

                const Text(
                  'Tell us your weight so we can calculate your daily targets accurately.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 40),

                // Unit Toggle
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _UnitToggleBtn(
                          title: 'Kilograms (kg)',
                          isSelected: _isKg,
                          onTap: () => setState(() => _isKg = true),
                        ),
                        _UnitToggleBtn(
                          title: 'Pounds (lbs)',
                          isSelected: !_isKg,
                          onTap: () => setState(() => _isKg = false),
                        ),
                      ],
                    ),
                  ),
                ).animate().slideY(begin: 0.1, delay: 200.ms).fadeIn(),

                const SizedBox(height: 40),

                // Age Input
                _AgeInput(
                  label: 'Age',
                  controller: _ageCtrl,
                  hintText: '25',
                ).animate().slideX(begin: -0.05, delay: 250.ms).fadeIn(),

                const SizedBox(height: 24),

                // Current Weight
                _WeightInput(
                  label: 'Current Weight',
                  controller: _currentWeightCtrl,
                  unitLabel: _isKg ? 'kg' : 'lbs',
                  hintText: _isKg ? '75.0' : '165.0',
                ).animate().slideX(begin: -0.05, delay: 300.ms).fadeIn(),

                const SizedBox(height: 24),

                // Goal Weight
                _WeightInput(
                  label: 'Desired Weight',
                  controller: _goalWeightCtrl,
                  unitLabel: _isKg ? 'kg' : 'lbs',
                  hintText: _isKg ? '70.0' : '155.0',
                ).animate().slideX(begin: -0.05, delay: 350.ms).fadeIn(),

                const SizedBox(height: 60),

                // Continue Button
                GestureDetector(
                  onTap: _isLoading ? null : _submitWeights,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 56,
                    decoration: BoxDecoration(
                      color: _isLoading
                          ? AppColors.primaryDark.withValues(alpha: 0.7)
                          : AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDark.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ).animate().fadeIn(delay: 450.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Reusable Widgets ─────────────────────────────────────────────────────────

class _UnitToggleBtn extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _UnitToggleBtn({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _WeightInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String unitLabel;
  final String hintText;

  const _WeightInput({
    required this.label,
    required this.controller,
    required this.unitLabel,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      color: AppColors.textPlaceholder.withValues(alpha: 0.5),
                      fontSize: 24,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                ),
              ),
              Container(
                width: 60,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  border: Border(left: BorderSide(color: AppColors.border)),
                ),
                child: Text(
                  unitLabel,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}

class _AgeInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hintText;

  const _AgeInput({
    required this.label,
    required this.controller,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(
                      color: AppColors.textPlaceholder.withValues(alpha: 0.5),
                      fontSize: 24,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                ),
              ),
              Container(
                width: 60,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  border: Border(left: BorderSide(color: AppColors.border)),
                ),
                child: const Text(
                  'yrs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}

