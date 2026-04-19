import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  bool _notifications = true;
  bool _appleHealth = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Preferences', style: AppTextStyles.sectionHeader),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          Container(
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text("Push Notifications", style: TextStyle(fontWeight: FontWeight.w600)),
                  value: _notifications,
                  activeThumbColor: AppColors.primaryDark,
                  onChanged: (val) => setState(() => _notifications = val),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.border),
                SwitchListTile(
                  title: const Text("Sync with Apple Health", style: TextStyle(fontWeight: FontWeight.w600)),
                  value: _appleHealth,
                  activeThumbColor: AppColors.primaryDark,
                  onChanged: (val) => setState(() => _appleHealth = val),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
