import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../providers/profile_providers.dart';

class PersonalDetailsScreen extends ConsumerStatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  ConsumerState<PersonalDetailsScreen> createState() =>
      _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends ConsumerState<PersonalDetailsScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _targetWeightCtrl;
  String _gender = 'male';
  String _activityLevel = 'sedentary';
  bool _isLoading = false;
  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _ageCtrl = TextEditingController();
    _heightCtrl = TextEditingController();
    _weightCtrl = TextEditingController();
    _targetWeightCtrl = TextEditingController();
  }

  void _initializeControllers(Map<String, dynamic> data) {
    if (_isDataLoaded) return;
    _nameCtrl.text = data['name'] ?? '';
    _ageCtrl.text = data['age']?.toString() ?? '';
    _heightCtrl.text = data['height']?.toString() ?? '';
    _weightCtrl.text = data['current_weight']?.toString() ?? '';
    _targetWeightCtrl.text = data['goal_weight']?.toString() ?? '';
    _gender = data['gender']?.toString().toLowerCase() ?? 'male';
    _activityLevel =
        data['activity_level']?.toString().toLowerCase() ?? 'sedentary';
    _isDataLoaded = true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _targetWeightCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final lang = ref.read(localeProvider);
    String t(String k) => Translations.t(lang, k);
    setState(() => _isLoading = true);
    try {
      await ref.read(personalDetailsProvider.notifier).saveProfile({
        'name': _nameCtrl.text,
        'age': int.tryParse(_ageCtrl.text),
        'gender': _gender,
        'activity_level': _activityLevel,
      });

      await ref.read(personalDetailsProvider.notifier).saveWeight({
        'current_weight': double.tryParse(_weightCtrl.text),
        'goal_weight': double.tryParse(_targetWeightCtrl.text),
        'weight_unit': 'kg',
        'height': double.tryParse(_heightCtrl.text),
        'height_unit': 'cm',
        'age': int.tryParse(_ageCtrl.text),
        'gender': _gender,
        'activity_level': _activityLevel,
      });

      ref.read(profileProvider.notifier).loadProfile();

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t('failed_save_details'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    String t(String k) => Translations.t(lang, k);
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          t('personal_details'),
          style: AppTextStyles.sectionHeader,
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: profileAsync.when(
        data: (data) {
          _initializeControllers(data);
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            children: [
              _buildField("Name", _nameCtrl),
              const SizedBox(height: 16),
              _buildField("Age", _ageCtrl, isNumber: true),
              const SizedBox(height: 16),
              _buildField("Height (cm)", _heightCtrl, isNumber: true),
              const SizedBox(height: 16),
              _buildField("Current Weight (kg)", _weightCtrl, isNumber: true),
              const SizedBox(height: 16),
              _buildField("Target Weight (kg)", _targetWeightCtrl, isNumber: true),
              const SizedBox(height: 16),
              
              _SectionHeader("Gender"),
              _buildDropdown(['Male', 'Female'], _gender, (val) => setState(() => _gender = val.toLowerCase())),
              
              const SizedBox(height: 24),
              _SectionHeader("Activity Level"),
              _buildDropdown(['Sedentary', 'Light', 'Moderate', 'Active', 'Very_Active'], _activityLevel, (val) => setState(() => _activityLevel = val.toLowerCase())),

              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  backgroundColor: AppColors.primaryDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onPressed: _isLoading ? null : _saveChanges,
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(t('save_details'), style: AppTextStyles.buttonLabel),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text("Error", style: TextStyle(color: AppColors.danger))),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          labelStyle: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildDropdown(List<String> options, String current, Function(String) onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: options.firstWhere((o) => o.toLowerCase() == current, orElse: () => options.first),
          items: options.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) onChanged(newValue);
          },
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
