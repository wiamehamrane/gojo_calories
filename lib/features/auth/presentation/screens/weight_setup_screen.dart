import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gojocalories/core/theme/app_colors.dart';
import 'package:gojocalories/core/di/repository_providers.dart';

class WeightSetupScreen extends ConsumerStatefulWidget {
  const WeightSetupScreen({super.key});

  @override
  ConsumerState<WeightSetupScreen> createState() => _WeightSetupScreenState();
}

class _WeightSetupScreenState extends ConsumerState<WeightSetupScreen> {
  bool _isLoading = false;
  late PageController _pageCtrl;
  int _currentIndex = 0;
  final int _totalPages = 8;

  String _gender = 'male';
  String _activityLevel = 'sedentary';

  bool _isKg = true;
  bool _isCm = true;

  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _currentWtCtrl = TextEditingController();
  final _goalWtCtrl = TextEditingController();
  final _referralCtrl = TextEditingController();

  final _focusNodes = List.generate(5, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(initialPage: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _currentWtCtrl.dispose();
    _goalWtCtrl.dispose();
    _referralCtrl.dispose();
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _nextPage() {
    if (_currentIndex < _totalPages - 1) {
      // Validate current
      if (_currentIndex == 0 && _ageCtrl.text.isEmpty) return;
      if (_currentIndex == 1 && _heightCtrl.text.isEmpty) return;
      if (_currentIndex == 2 && _currentWtCtrl.text.isEmpty) return;
      if (_currentIndex == 3 && _goalWtCtrl.text.isEmpty) return;

      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.fastOutSlowIn,
      );
      if (_currentIndex + 1 < _focusNodes.length) {
        _focusNodes[_currentIndex + 1].requestFocus();
      }
    } else {
      _submitWeights();
    }
  }

  void _prevPage() {
    if (_currentIndex > 0) {
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.fastOutSlowIn,
      );
      _focusNodes[_currentIndex - 1].requestFocus();
    } else {
      context.go('/auth');
    }
  }

  Future<void> _submitWeights() async {
    final currentStr = _currentWtCtrl.text.trim();
    final goalStr = _goalWtCtrl.text.trim();
    final ageStr = _ageCtrl.text.trim();
    final heightStr = _heightCtrl.text.trim();
    final referralStr = _referralCtrl.text.trim();

    if (currentStr.isEmpty ||
        goalStr.isEmpty ||
        ageStr.isEmpty ||
        heightStr.isEmpty) {
      _showError('Please fill out all fields.');
      return;
    }

    final currentWt = double.tryParse(currentStr);
    final goalWt = double.tryParse(goalStr);
    final age = int.tryParse(ageStr);
    final height = double.tryParse(heightStr);

    if (currentWt == null || goalWt == null || age == null || height == null) {
      _showError('Please enter valid numbers.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final unit = _isKg ? 'kg' : 'lbs';
      final heightUnit = _isCm ? 'cm' : 'ft';

      await ref.read(authRepositoryProvider).updateWeight({
          'current_weight': currentWt,
          'goal_weight': goalWt,
          'weight_unit': unit,
          'height': height,
          'height_unit': heightUnit,
          'age': age,
          'gender': _gender,
          'activity_level': _activityLevel,
          if (referralStr.isNotEmpty) 'referral_code': referralStr,
        });

      if (mounted) {
        _pageCtrl.animateToPage(
          7,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) context.go('/onboarding/paywall');
        });
      }
    } catch (e) {
      _showError('Connection error. Please try again.');
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
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: _prevPage,
        ),
        title: _ProgressBar(currentIndex: _currentIndex, total: _totalPages),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (idx) {
                  setState(() => _currentIndex = idx);
                },
                children: [
                  _buildStep(
                    title: 'How old are you?',
                    subtitle: 'This helps us calculate your metabolic rate.',
                    icon: Icons.cake_rounded,
                    inputChild: _buildHugeInput(
                      controller: _ageCtrl,
                      focusNode: _focusNodes[0],
                      suffix: 'years',
                      hint: '25',
                    ),
                  ),
                  _buildStep(
                    title: 'How tall are you?',
                    subtitle: 'For your Body Mass Index (BMI).',
                    icon: Icons.height_rounded,
                    inputChild: Column(
                      children: [
                        _buildToggle(
                          option1: 'cm',
                          option2: 'ft',
                          isOpt1Valid: _isCm,
                          onChanged: (val) {
                            setState(() => _isCm = val);
                            _focusNodes[1].requestFocus();
                          },
                        ),
                        const SizedBox(height: 30),
                        _buildHugeInput(
                          controller: _heightCtrl,
                          focusNode: _focusNodes[1],
                          suffix: _isCm ? 'cm' : 'ft',
                          hint: _isCm ? '175' : '5.9',
                          isDecimal: true,
                        ),
                      ],
                    ),
                  ),
                  _buildStep(
                    title: 'What is your current weight?',
                    subtitle: 'Let\'s set your starting point.',
                    icon: Icons.monitor_weight_rounded,
                    inputChild: Column(
                      children: [
                        _buildToggle(
                          option1: 'kg',
                          option2: 'lbs',
                          isOpt1Valid: _isKg,
                          onChanged: (val) {
                            setState(() => _isKg = val);
                            _focusNodes[2].requestFocus();
                          },
                        ),
                        const SizedBox(height: 30),
                        _buildHugeInput(
                          controller: _currentWtCtrl,
                          focusNode: _focusNodes[2],
                          suffix: _isKg ? 'kg' : 'lbs',
                          hint: _isKg ? '75.0' : '165.0',
                          isDecimal: true,
                        ),
                      ],
                    ),
                  ),
                  _buildStep(
                    title: 'What is your goal weight?',
                    subtitle: 'The target we\'re aiming for.',
                    icon: Icons.flag_rounded,
                    inputChild: Column(
                      children: [
                        _buildToggle(
                          option1: 'kg',
                          option2: 'lbs',
                          isOpt1Valid: _isKg,
                          onChanged: (val) {
                            setState(() => _isKg = val);
                          },
                        ),
                        const SizedBox(height: 30),
                        _buildHugeInput(
                          controller: _goalWtCtrl,
                          focusNode: _focusNodes[3],
                          suffix: _isKg ? 'kg' : 'lbs',
                          hint: _isKg ? '70.0' : '155.0',
                          isDecimal: true,
                        ),
                      ],
                    ),
                  ),
                  _buildStep(
                    title: 'Select your gender',
                    subtitle: 'This adjusts your caloric needs base.',
                    icon: Icons.person_search_rounded,
                    inputChild: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSelectionPill(
                          title: 'Male',
                          isSelected: _gender == 'male',
                          onTap: () => setState(() => _gender = 'male'),
                        ),
                        const SizedBox(width: 16),
                        _buildSelectionPill(
                          title: 'Female',
                          isSelected: _gender == 'female',
                          onTap: () => setState(() => _gender = 'female'),
                        ),
                      ],
                    ),
                  ),
                  _buildStep(
                    title: 'Your activity level?',
                    subtitle: 'How active are you on a weekly basis?',
                    icon: Icons.directions_run_rounded,
                    inputChild: Column(
                      children: [
                        _buildSelectionPill(
                          title: 'Sedentary',
                          subtitle: 'Office job, little exercise',
                          isSelected: _activityLevel == 'sedentary',
                          onTap: () => setState(() => _activityLevel = 'sedentary'),
                          isFullWidth: true,
                        ),
                        const SizedBox(height: 12),
                        _buildSelectionPill(
                          title: 'Lightly Active',
                          subtitle: '1-3 days of exercise',
                          isSelected: _activityLevel == 'light',
                          onTap: () => setState(() => _activityLevel = 'light'),
                          isFullWidth: true,
                        ),
                        const SizedBox(height: 12),
                        _buildSelectionPill(
                          title: 'Moderately Active',
                          subtitle: '3-5 days of exercise',
                          isSelected: _activityLevel == 'moderate',
                          onTap: () => setState(() => _activityLevel = 'moderate'),
                          isFullWidth: true,
                        ),
                        const SizedBox(height: 12),
                        _buildSelectionPill(
                          title: 'Very Active',
                          subtitle: '6-7 days of hard exercise',
                          isSelected: _activityLevel == 'active',
                          onTap: () => setState(() => _activityLevel = 'active'),
                          isFullWidth: true,
                        ),
                      ],
                    ),
                  ),
                  _buildStep(
                    title: 'Got a referral code?',
                    subtitle: 'Enter it here (optional)',
                    icon: Icons.card_giftcard_rounded,
                    inputChild: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _referralCtrl,
                            focusNode: _focusNodes[4],
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submitWeights(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                              letterSpacing: 2,
                            ),
                            decoration: InputDecoration(
                              hintText: 'ABC123',
                              hintStyle: TextStyle(
                                color: AppColors.primary.withValues(alpha: 0.2),
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildLoadingStep(),
                ],
              ),
            ),
            // Bottom Action Area
            if (_currentIndex < 7)
            AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: EdgeInsets.fromLTRB(
                24,
                0,
                24,
                24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: GestureDetector(
                onTap: _nextPage,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 58,
                  decoration: BoxDecoration(
                    color: _isLoading
                        ? AppColors.primaryMid
                        : AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDark.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
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
                        : Text(
                            _currentIndex == 6
                                ? 'Finish Setup'
                                : 'Continue',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                strokeWidth: 8,
                color: AppColors.primary.withValues(alpha: 0.2),
                value: 1.0,
              ),
              const CircularProgressIndicator(
                strokeWidth: 8,
                color: AppColors.primaryDark,
              ),
              const Text(
                '🥑',
                style: TextStyle(fontSize: 48),
              ).animate(onPlay: (controller) => controller.repeat())
               .scale(duration: 1000.ms, begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2))
               .then()
               .scale(duration: 1000.ms, begin: const Offset(1.2, 1.2), end: const Offset(0.8, 0.8)),
            ],
          ),
        ),
        const SizedBox(height: 48),
        const Text(
          'Perfecting your plan...',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),
        const SizedBox(height: 12),
        const Text(
          'AI is calculating your custom nutritional needs.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }

  Widget _buildStep({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget inputChild,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: AppColors.primaryDark),
          ).animate().scale(
            delay: 100.ms,
            duration: 400.ms,
            curve: Curves.easeOutBack,
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ).animate().slideY(begin: 0.1, duration: 400.ms).fadeIn(),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 50),
          inputChild.animate().slideY(begin: 0.1, delay: 200.ms).fadeIn(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHugeInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String suffix,
    required String hint,
    bool isDecimal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        IntrinsicWidth(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
            inputFormatters: isDecimal
                ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
                : [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _nextPage(),
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
              letterSpacing: -2,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          suffix,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionPill({
    required String title,
    String? subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    bool isFullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isFullWidth ? double.infinity : 120,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryDark : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryDark : AppColors.border,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryDark.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildToggle({
    required String option1,
    required String option2,
    required bool isOpt1Valid,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TogglePill(
            title: option1,
            isSelected: isOpt1Valid,
            onTap: () => onChanged(true),
          ),
          _TogglePill(
            title: option2,
            isSelected: !isOpt1Valid,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _TogglePill extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _TogglePill({
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
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int currentIndex;
  final int total;

  const _ProgressBar({required this.currentIndex, required this.total});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Row(
        children: List.generate(total, (index) {
          final isActive = index <= currentIndex;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: EdgeInsets.only(right: index == total - 1 ? 0 : 6),
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
  }
}
