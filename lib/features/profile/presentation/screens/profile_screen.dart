import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../auth/data/services/iap_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../social/presentation/providers/memories_provider.dart';
import '../../../social/presentation/providers/friends_provider.dart';
import 'add_friend_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/di/repository_providers.dart';
import '../providers/profile_providers.dart';


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

              const SizedBox(height: 24),
              _SectionLabel('Memories'),
              _buildMemoriesGallery(ref),

              const SizedBox(height: 24),
              _SectionLabel('Circle of Friends'),
              _buildCircleOfFriends(context, ref),

              const SizedBox(height: 24),
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
                        final uri = Uri.parse(
                          'https://apps.apple.com/account/subscriptions',
                        );
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      } catch (e) {
                        debugPrint('Subscription management error: $e');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Could not open subscription settings.',
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  _SettingsRow(
                    icon: LucideIcons.refreshCw,
                    label: 'Restore Purchases',
                    onTap: () async {
                      try {
                        final iapService = IAPService();
                        await iapService.initialize();
                        await iapService.restorePurchases();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Restore initiated. Please wait...'),
                            ),
                          );
                        }
                      } catch (e) {
                        debugPrint('Restore error: $e');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to restore purchases.'),
                            ),
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
                    onTap: () => _confirmDeleteAccount(context, ref),
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
                await ref.read(profileRepositoryProvider).resendVerification();
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
                    if (data['phone'] != null)
                      const Icon(LucideIcons.phone, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
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

  Widget _buildMemoriesGallery(WidgetRef ref) {
    final memoriesAsync = ref.watch(memoriesProvider);

    return SizedBox( 
      height: 180,
      child: memoriesAsync.when(
        data: (memories) => ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: memories.length + 1,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildAddMemoryButton(context, ref);
            }
            final memory = memories[index - 1];
            return _buildMemoryCard(memory);
          },
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, st) => Center(
          child: Text(
            'Failed to load memories',
            style: TextStyle(color: AppColors.danger, fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildAddMemoryButton(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _pickAndUploadMemory(context, ref),
      child: Container(
        width: 130,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.imagePlus, color: AppColors.primary, size: 20),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add Photo',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoryCard(Memory memory) {
    return Container(
      width: 130,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: NetworkImage(memory.imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          if (memory.isPrivate)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.lock, size: 10, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadMemory(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final success = await ref.read(memoriesProvider.notifier).uploadMemory(file);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Memory added! 🎉' : 'Upload failed. Try again.'),
            backgroundColor: success ? Colors.green : AppColors.danger,
          ),
        );
      }
    }
  }

  Widget _buildCircleOfFriends(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.cardShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          friendsAsync.when(
            data: (friends) => Row(
              children: [
                ...friends.take(5).map((f) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      f.name != null && f.name!.isNotEmpty ? f.name![0].toUpperCase() : '👤',
                      style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                )),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddFriendScreen()),
                  ),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: const Icon(LucideIcons.plus, size: 16, color: AppColors.primary),
                  ),
                ),
                if (friends.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      '+${friends.length - 5}',
                      style: const TextStyle(fontSize: 12, color: AppColors.inactive, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            loading: () => const SizedBox(height: 36, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
            error: (e, st) => const Text('Failed to load circle', style: TextStyle(fontSize: 12, color: AppColors.danger)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Keep it tight. Share your progress only with people you trust.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
        onSaved: () => ref.read(profileProvider.notifier).loadProfile(),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await TokenStorage.clearSession();
    if (context.mounted) context.go(RoutePaths.auth);
  }

  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
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
        await ref.read(profileRepositoryProvider).deleteAccount();
        await TokenStorage.clearSession();
        if (context.mounted) context.go(RoutePaths.auth);
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

class _ProfileUpdateSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onSaved;
  const _ProfileUpdateSheet({required this.user, required this.onSaved});

  @override
  ConsumerState<_ProfileUpdateSheet> createState() => _ProfileUpdateSheetState();
}

class _ProfileUpdateSheetState extends ConsumerState<_ProfileUpdateSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _phoneCtrl;
  bool _sharePhone = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user['name']);
    _ageCtrl = TextEditingController(text: widget.user['age']?.toString());
    _phoneCtrl = TextEditingController(text: widget.user['phone']);
    _sharePhone = widget.user['share_phone'] ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await ref.read(profileRepositoryProvider).updateProfile({
        'name': _nameCtrl.text,
        'age': int.tryParse(_ageCtrl.text),
        'phone': _phoneCtrl.text,
        'share_phone': _sharePhone,
      });
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
            const SizedBox(height: 16),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '+1 234 567 890',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Share phone with friends'),
              subtitle: const Text('Allow friends in your circle to see your number'),
              value: _sharePhone,
              onChanged: (val) => setState(() => _sharePhone = val),
              activeThumbColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
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
