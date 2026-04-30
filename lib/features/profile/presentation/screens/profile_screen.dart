import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/network/api_client.dart';



// Providers
final profileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ApiClient.instance.get('auth/me');
  if (res.statusCode == 200) {
    return res.data;
  }
  return {};
});


class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    String t(String k) => Translations.t(lang, k);
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // User card
              profileAsync.when(
                data: (data) => Column(
                  children: [
                    _buildUserCard(context, ref, data, t),
                    if (data['is_email_verified'] != true) ...[
                      const SizedBox(height: 16),
                      _buildVerificationBanner(context, ref, data, t),
                    ],
                  ],
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, st) => const Text(
                  "Failed to load profile",
                  style: TextStyle(color: AppColors.danger),
                ),
              ),

              const SizedBox(height: 20),
              _SectionLabel(t('invite_friends')),

              // Invite card
              GestureDetector(
                onTap: () => context.push('/profile/referrals'),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppShadows.cardShadow,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          LucideIcons.userPlus,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t('referral_tagline'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              t('referral_subtitle'),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        LucideIcons.chevronRight,
                        size: 18,
                        color: AppColors.inactive,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              _SectionLabel(t('settings')),

              _GroupedListCard(
                rows: [
                  _SettingsRow(
                    icon: LucideIcons.badgeCheck,
                    label: t('personal_details'),
                    onTap: () => context.push('/profile/personal'),
                  ),
                  _SettingsRow(
                    icon: LucideIcons.settings2,
                    label: t('preferences'),
                    onTap: () => context.push('/profile/preferences'),
                  ),
                  _SettingsRow(
                    icon: LucideIcons.languages,
                    label: t('language'),
                    onTap: () => context.push('/profile/language'),
                  ),
                  _SettingsRow(
                    icon: LucideIcons.creditCard,
                    label: 'Manage Subscription',
                    onTap: () async {
                      try {
                        final res = await ApiClient.instance.post('payments/create-portal-session');
                        if (res.statusCode == 200 && res.data['url'] != null) {
                          final uri = Uri.parse(res.data['url']);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not load billing portal.')),
                            );
                          }
                        }
                      } catch (e) {
                        debugPrint('Portal error: $e');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No active subscription found.')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),
              _SectionLabel(t('nutrition_goals')),

              _GroupedListCard(
                rows: [
                  _SettingsRow(
                    icon: LucideIcons.circleDashed,
                    label: t('nutrition_goals'),
                    onTap: () => context.push('/profile/nutrition'),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              _SectionLabel('Support & Legal'),
              _GroupedListCard(
                rows: [
                  _SettingsRow(
                    icon: LucideIcons.lightbulb,
                    label: 'Feature Request',
                    onTap: () => context.push('/feature_request'),
                  ),
                  _SettingsRow(
                    icon: LucideIcons.mail,
                    label: 'Support Email',
                    onTap: () async {
                      final uri = Uri.parse('mailto:support@gojocalories.com?subject=Support%20Request');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                  ),
                  _SettingsRow(
                    icon: LucideIcons.fileText,
                    label: 'Terms of Service',
                    onTap: () async {
                      final uri = Uri.parse('https://gojocalories.com/terms-of-service');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                  ),
                  _SettingsRow(
                    icon: LucideIcons.shieldCheck,
                    label: 'Privacy Policy',
                    onTap: () async {
                      final uri = Uri.parse('https://gojocalories.com/privacy-policy');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 30),
              // Danger Zone
              _GroupedListCard(
                rows: [
                  _SettingsRow(
                    icon: LucideIcons.logOut,
                    label: 'Sign Out',
                    color: AppColors.primary,
                    onTap: () => _signOut(context),
                  ),
                  _SettingsRow(
                    icon: LucideIcons.userMinus,
                    label: 'Delete Account',
                    color: AppColors.danger,
                    onTap: () => _confirmDeleteAccount(context),
                  ),
                ],
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationBanner(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> data,
    String Function(String) t,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.fire.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fire.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(LucideIcons.mailWarning, color: AppColors.fire, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Email Not Verified",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.fire,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Please verify to secure your account.",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ApiClient.instance.post('auth/resend-verification');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Verification email sent! Check your inbox.")),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to send email.")),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.fire,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Verify", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> data,
    String Function(String) t,
  ) {
    // Compute BMI if we have both height and weight
    final double? weightKg = (data['current_weight'] as num?)?.toDouble();
    final double? heightCm = (data['height'] as num?)?.toDouble();
    double? bmi;
    String bmiLabel = '';
    Color bmiColor = AppColors.primary;
    if (weightKg != null && heightCm != null && heightCm > 0) {
      final heightM = heightCm / 100.0;
      bmi = weightKg / (heightM * heightM);
      if (bmi < 18.5) {
        bmiLabel = t('bmi_underweight');
        bmiColor = Colors.blue;
      } else if (bmi < 25) {
        bmiLabel = t('bmi_normal');
        bmiColor = Colors.green;
      } else if (bmi < 30) {
        bmiLabel = t('bmi_overweight');
        bmiColor = Colors.orange;
      } else {
        bmiLabel = t('bmi_obese');
        bmiColor = AppColors.danger;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.cardShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.surfaceMuted,
            child: Icon(LucideIcons.user, size: 28, color: AppColors.inactive),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      data['name'] ?? 'User',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () =>
                          _showUpdateProfileBottomSheet(context, ref, data),
                      child: const Icon(
                        LucideIcons.pencil,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Text(
                  "${data['age'] ?? 30} ${t('profile_years_old')}",
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (bmi != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '${t('bmi')}: ${bmi.toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: bmiColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          bmiLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: bmiColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }



  void _showUpdateProfileBottomSheet(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> data,
  ) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ProfileUpdateSheet(
        user: data,
        onSaved: () => ref.refresh(profileProvider),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    if (context.mounted) context.go('/auth');
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Account?"),
        content: const Text(
          "This action is permanent and will completely erase all your data and cancel any active subscription. Do you wish to proceed?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Delete Permanently",
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      try {
        await ApiClient.instance.delete('auth/me');
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('access_token');
        if (context.mounted) context.go('/auth');
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Delete failed.")));
        }
      }
    }
  }
}

class _ProfileUpdateSheet extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onSaved;
  const _ProfileUpdateSheet({required this.user, required this.onSaved});

  @override
  State<_ProfileUpdateSheet> createState() => _ProfileUpdateSheetState();
}

class _ProfileUpdateSheetState extends State<_ProfileUpdateSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _ageCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user['name']);
    _ageCtrl = TextEditingController(text: widget.user['age']?.toString());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await ApiClient.instance.put(
        'auth/me/profile',
        data: {'name': _nameCtrl.text, 'age': int.tryParse(_ageCtrl.text)},
      );
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Update Profile",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ageCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Age',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : const Text("Save Changes"),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.inactive,
        ),
      ),
    );
  }
}

class _GroupedListCard extends StatelessWidget {
  final List<Widget> rows;
  const _GroupedListCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    for (int i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i < rows.length - 1) {
        children.add(
          const Divider(color: AppColors.border, height: 1, indent: 52),
        );
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 22, color: color ?? AppColors.textPrimary),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: color ?? AppColors.textPrimary,
        ),
      ),
      trailing: color == null
          ? const Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: AppColors.inactive,
            )
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
    );
  }
}
