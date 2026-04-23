import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'profile_screen.dart';

class PersonalDetailsScreen extends ConsumerWidget {
  const PersonalDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Personal Details',
          style: AppTextStyles.sectionHeader,
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: profileAsync.when(
        data: (data) => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          children: [
            _buildField("Name", "${data['name'] ?? ''}"),
            const SizedBox(height: 16),
            _buildField("Age", "${data['age'] ?? ''}"),
            const SizedBox(height: 16),
            _buildField("Height", "${data['height'] ?? ''} cm"),
            const SizedBox(height: 16),
            _buildField("Current Weight", "${data['current_weight'] ?? ''} kg"),
            const SizedBox(height: 16),
            _buildField("Target Weight", "${data['target_weight'] ?? ''} kg"),
            const SizedBox(height: 16),
            _buildField("Gender", "${data['gender'] ?? 'Not Set'}"),
            const SizedBox(height: 16),
            _buildField("Activity Level", "${data['activity_level'] ?? 'Not Set'}"),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text("Error", style: TextStyle(color: AppColors.danger))),
      ),
    );
  }

  Widget _buildField(String label, String value) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          hintText: value,
          border: InputBorder.none,
          labelStyle: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
