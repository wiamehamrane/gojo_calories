import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
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
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/app_pressable.dart';
import '../../../../core/widgets/cached_food_image.dart';
import '../providers/profile_providers.dart';


class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    String t(String k) => Translations.t(lang, k);
    final profileAsync = ref.watch(profileProvider);
    final isCoach = profileAsync.asData?.value['is_coach'] == true;

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
                loading: () => Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, st) => _ProfileLoadError(
                  lang: lang,
                  message: AppErrorHandler.message(e),
                  onRetry: () =>
                      ref.read(profileProvider.notifier).loadProfile(),
                  onSignIn: () => context.go(RoutePaths.auth),
                ),
              ),

              /*const SizedBox(height: 24),
              _SectionLabel('Memories'),
              _buildMemoriesGallery(ref),

              const SizedBox(height: 24),
              _SectionLabel('Circle of Friends'),
              _buildCircleOfFriends(context, ref),*/

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
                        child: Icon(
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
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              t('referral_subtitle'),
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        LucideIcons.chevronRight,
                        size: 18,
                        color: AppColors.inactive,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const _SectionLabel('My body journal'),
              _ProgressPromoCard(
                onTap: () => context.push(RoutePaths.progressPhotos),
              ),

              const SizedBox(height: 20),
              _SectionLabel(t('my_events')),

              _GroupedListCard(
                rows: [
                  _SettingsRow(
                    icon: LucideIcons.calendarCog,
                    label: t('manage_my_events'),
                    onTap: () => context.push(RoutePaths.myEvents),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              _SectionLabel(t('starred_meals')),

              _GroupedListCard(
                rows: [
                  _SettingsRow(
                    icon: LucideIcons.star,
                    label: t('view_starred_meals'),
                    onTap: () => context.push(RoutePaths.starredMeals),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              _CoachPromoCard(
                isCoach: isCoach,
                title: isCoach
                    ? t('become_coach_manage_title')
                    : t('become_coach_title'),
                subtitle: isCoach
                    ? t('coach_hub_subtitle')
                    : t('coach_paywall_headline'),
                cta: isCoach
                    ? t('become_coach_continue')
                    : t('become_coach_submit'),
                onTap: () => context.push(
                  isCoach ? RoutePaths.coachHub : RoutePaths.becomeCoach,
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
                    icon: LucideIcons.users,
                    label: t('clan_title'),
                    onTap: () => context.push(RoutePaths.profileClan),
                  ),
                  _SettingsRow(
                    icon: LucideIcons.share2,
                    label: t('share_access_title'),
                    onTap: () => context.push(RoutePaths.profileShare),
                  ),
                  _SettingsRow(
                    icon: LucideIcons.creditCard,
                    label: t('manage_subscription'),
                    onTap: () async {
                      try {
                        final uri = Uri.parse(
                          Platform.isAndroid
                              ? 'https://play.google.com/store/account/subscriptions?package=$kAndroidPackageName'
                              : 'https://apps.apple.com/account/subscriptions',
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
                            SnackBar(
                              content: Text(
                                t('could_not_open_subscription_settings'),
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  _SettingsRow(
                    icon: LucideIcons.refreshCw,
                    label: t('restore_purchases'),
                    onTap: () async {
                      try {
                        final iapService = IAPService();
                        await iapService.initialize();
                        await iapService.restorePurchases();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(t('restore_initiated')),
                            ),
                          );
                        }
                      } catch (e) {
                        debugPrint('Restore error: $e');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(t('restore_purchases_failed')),
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
              _SectionLabel(t('support_legal')),
              _GroupedListCard(
                rows: [
                  _SettingsRow(
                    icon: LucideIcons.lightbulb,
                    label: t('feature_request'),
                    onTap: () => context.push('/feature_request'),
                  ),
                  _SettingsRow(
                    icon: LucideIcons.mail,
                    label: t('support_email'),
                    onTap: () async {
                      final uri = Uri.parse('mailto:support@gojocalories.com?subject=Support%20Request');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                  ),
                  _SettingsRow(
                    icon: LucideIcons.fileText,
                    label: t('terms_of_service'),
                    onTap: () => context.push('/profile/terms'),
                  ),
                  _SettingsRow(
                    icon: LucideIcons.shieldCheck,
                    label: t('privacy_policy'),
                    onTap: () => context.push('/profile/privacy'),
                  ),
                ],
              ),

              const SizedBox(height: 30),
              // Danger Zone
              _GroupedListCard(
                rows: [
                  _SettingsRow(
                    icon: LucideIcons.logOut,
                    label: t('sign_out'),
                    color: AppColors.primary,
                    onTap: () => _signOut(context),
                  ),
                  _SettingsRow(
                    icon: LucideIcons.userMinus,
                    label: t('delete_account'),
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
          Icon(LucideIcons.mailWarning, color: AppColors.fire, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('email_not_verified'),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.fire,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  t('email_verify_secure_prompt'),
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
              final email = data['email'] as String?;
              if (email == null) return;
              try {
                await ref.read(authRepositoryProvider).resendVerification(
                      email: email,
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(t('verification_code_sent_inbox')),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t('failed_send_code'))),
                  );
                }
              }
              if (context.mounted) {
                context.push(
                  '${RoutePaths.verifyOtp}?email=${Uri.encodeComponent(email)}',
                );
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
            child: Text(t('verify'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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

    final avatarUrl = data['avatar_url'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.cardShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          AppPressable(
            scale: 0.92,
            onTap: () => _showAvatarOptions(
              context,
              ref,
              avatarUrl: avatarUrl,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.surfaceMuted,
                  child: ClipOval(
                    child: avatarUrl != null && avatarUrl.isNotEmpty
                        ? CachedFoodImage(
                            imageUrl: avatarUrl,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            memCacheWidth: 160,
                            placeholder: Center(
                              child: Icon(
                                LucideIcons.user,
                                size: 28,
                                color: AppColors.inactive,
                              ),
                            ),
                            errorWidget: Center(
                              child: Icon(
                                LucideIcons.user,
                                size: 28,
                                color: AppColors.inactive,
                              ),
                            ),
                          )
                        : Icon(
                            LucideIcons.user,
                            size: 28,
                            color: AppColors.inactive,
                          ),
                  ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 2),
                    ),
                    child: const Icon(
                      LucideIcons.camera,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        data['name'] ?? 'User',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (data['phone'] != null)
                      Icon(LucideIcons.phone, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () =>
                          _showUpdateProfileBottomSheet(context, ref, data),
                      child: Icon(
                        LucideIcons.pencil,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Text(
                  "${data['age'] ?? 30} ${t('profile_years_old')}",
                  style: TextStyle(
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
                        style: TextStyle(
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
        loading: () => Center(
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
              child: Icon(LucideIcons.imagePlus, color: AppColors.primary, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
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

  Future<void> _showAvatarOptions(
    BuildContext context,
    WidgetRef ref, {
    String? avatarUrl,
  }) async {
    HapticFeedback.selectionClick();
    final action = await showModalBottomSheet<_AvatarSheetAction>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (sheetContext) {
        return _AvatarPhotoSheet(avatarUrl: avatarUrl);
      },
    );
    if (action == null || !context.mounted) return;

    switch (action) {
      case _AvatarSheetAction.gallery:
        await _pickAndUploadAvatar(context, ref, ImageSource.gallery);
      case _AvatarSheetAction.camera:
        await _pickAndUploadAvatar(context, ref, ImageSource.camera);
      case _AvatarSheetAction.remove:
        final success =
            await ref.read(profileProvider.notifier).deleteAvatar();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success ? 'Profile photo removed' : 'Could not remove photo',
              ),
              backgroundColor: success ? Colors.green : AppColors.danger,
            ),
          );
        }
    }
  }

  Future<void> _pickAndUploadAvatar(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (pickedFile == null) return;

    final success = await ref
        .read(profileProvider.notifier)
        .uploadAvatar(File(pickedFile.path));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Profile photo updated' : 'Upload failed. Try again.',
          ),
          backgroundColor: success ? Colors.green : AppColors.danger,
        ),
      );
    }
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
                      style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
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
                    child: Icon(LucideIcons.plus, size: 16, color: AppColors.primary),
                  ),
                ),
                if (friends.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      '+${friends.length - 5}',
                      style: TextStyle(fontSize: 12, color: AppColors.inactive, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            loading: () => const SizedBox(height: 36, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
            error: (e, st) => Text(
              'Failed to load circle', 
              style: TextStyle(fontSize: 12, color: AppColors.danger)),
          ),
          const SizedBox(height: 12),
          Text(
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
    try {
      await OneSignal.logout();
    } catch (_) {}
    await TokenStorage.clearSession();
    if (context.mounted) context.go(RoutePaths.auth);
  }

  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final lang = ref.read(localeProvider);
    String t(String k) => Translations.t(lang, k);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('delete_account')),
        content: Text(t('delete_account_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              t('delete_permanently'),
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      try {
        await ref.read(profileRepositoryProvider).deleteAccount();
        try {
          await OneSignal.logout();
        } catch (_) {}
        await TokenStorage.clearSession();
        if (context.mounted) context.go(RoutePaths.auth);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(t('delete_failed'))));
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
    final lang = ref.watch(localeProvider);
    String t(String k) => Translations.t(lang, k);
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t('update_profile'),
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
              title: Text(t('share_phone_with_friends')),
              subtitle: Text(t('share_phone_with_friends_desc')),
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
                  : Text(t('save_changes')),
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
        style: TextStyle(
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
          Divider(color: AppColors.border, height: 1, indent: 52),
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

class _ProgressPromoCard extends StatefulWidget {
  final VoidCallback onTap;

  const _ProgressPromoCard({required this.onTap});

  @override
  State<_ProgressPromoCard> createState() => _ProgressPromoCardState();
}

class _ProgressPromoCardState extends State<_ProgressPromoCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PressScale(
      scale: 0.98,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            final t = Curves.easeInOut.transform(_pulse.value);
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.heroGradientWarm,
                ),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.18 + t * 0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.10 + t * 0.08),
                    blurRadius: 18 + t * 6,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.25),
                      AppColors.primaryLight,
                    ],
                  ),
                ),
                child: Icon(
                  LucideIcons.personStanding,
                  color: AppColors.primaryDark,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Front, sides & back',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Compare days and watch yourself change.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View progress',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            LucideIcons.arrowRight,
                            size: 14,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoachPromoCard extends StatefulWidget {
  final bool isCoach;
  final String title;
  final String subtitle;
  final String cta;
  final VoidCallback onTap;

  const _CoachPromoCard({
    required this.isCoach,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.onTap,
  });

  @override
  State<_CoachPromoCard> createState() => _CoachPromoCardState();
}

class _CoachPromoCardState extends State<_CoachPromoCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PressScale(
      scale: 0.98,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            final t = Curves.easeInOut.transform(_pulse.value);
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppColors.heroGradientWarm,
                ),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.18 + t * 0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.10 + t * 0.08),
                    blurRadius: 18 + t * 6,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.25),
                      AppColors.primaryLight,
                    ],
                  ),
                ),
                child: Icon(
                  widget.isCoach ? LucideIcons.badgeCheck : LucideIcons.sparkles,
                  color: AppColors.primaryDark,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.cta,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            LucideIcons.arrowRight,
                            size: 14,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
    return PressScale(
      scale: 0.98,
      child: Material(
        color: Colors.transparent,
        child: ListTile(
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
              ? Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: AppColors.inactive,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
        ),
      ),
    );
  }
}

class _ProfileLoadError extends StatelessWidget {
  final String lang;
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onSignIn;

  const _ProfileLoadError({
    required this.lang,
    required this.message,
    required this.onRetry,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    String t(String k) => Translations.t(lang, k);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('failed_load_profile'),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton(onPressed: onRetry, child: Text(t('retry'))),
              const SizedBox(width: 8),
              TextButton(onPressed: onSignIn, child: Text(t('sign_in'))),
            ],
          ),
        ],
      ),
    );
  }
}

enum _AvatarSheetAction { gallery, camera, remove }

class _AvatarPhotoSheet extends StatefulWidget {
  final String? avatarUrl;

  const _AvatarPhotoSheet({this.avatarUrl});

  @override
  State<_AvatarPhotoSheet> createState() => _AvatarPhotoSheetState();
}

class _AvatarPhotoSheetState extends State<_AvatarPhotoSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _avatarScale;

  bool get _hasAvatar =>
      widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutCubic),
      ),
    );
    _avatarScale = Tween<double>(begin: 0.82, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.05, 0.75, curve: Curves.easeOutBack),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _select(_AvatarSheetAction action) async {
    HapticFeedback.selectionClick();
    await _controller.reverse();
    if (!mounted) return;
    Navigator.of(context).pop(action);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, bottom + 20),
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Material(
            color: AppColors.surface,
            elevation: 0,
            shadowColor: Colors.black26,
            borderRadius: BorderRadius.circular(28),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 22),
                  ScaleTransition(
                    scale: _avatarScale,
                    child: _AvatarPreview(avatarUrl: widget.avatarUrl),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    _hasAvatar ? 'Update profile photo' : 'Add a profile photo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'This shows on your profile and public page',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _AvatarActionTile(
                          icon: LucideIcons.image,
                          label: 'Gallery',
                          subtitle: 'Pick a photo',
                          delayMs: 80,
                          onTap: () => _select(_AvatarSheetAction.gallery),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AvatarActionTile(
                          icon: LucideIcons.camera,
                          label: 'Camera',
                          subtitle: 'Take a shot',
                          delayMs: 140,
                          onTap: () => _select(_AvatarSheetAction.camera),
                        ),
                      ),
                    ],
                  ),
                  if (_hasAvatar) ...[
                    const SizedBox(height: 10),
                    AppPressable(
                      onTap: () => _select(_AvatarSheetAction.remove),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.trash2,
                              size: 16,
                              color: AppColors.danger,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Remove photo',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  final String? avatarUrl;

  const _AvatarPreview({this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = avatarUrl != null && avatarUrl!.isNotEmpty;

    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLight,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.22),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
            ),
            clipBehavior: Clip.antiAlias,
            child: hasPhoto
                ? CachedFoodImage(
                    imageUrl: avatarUrl,
                    width: 84,
                    height: 84,
                    fit: BoxFit.cover,
                    memCacheWidth: 252,
                    placeholder: Center(
                      child: Icon(
                        LucideIcons.user,
                        size: 34,
                        color: AppColors.inactive,
                      ),
                    ),
                    errorWidget: Center(
                      child: Icon(
                        LucideIcons.user,
                        size: 34,
                        color: AppColors.inactive,
                      ),
                    ),
                  )
                : Center(
                    child: Icon(
                      LucideIcons.user,
                      size: 34,
                      color: AppColors.inactive,
                    ),
                  ),
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                LucideIcons.camera,
                size: 13,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarActionTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final int delayMs;
  final VoidCallback onTap;

  const _AvatarActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.delayMs,
    required this.onTap,
  });

  @override
  State<_AvatarActionTile> createState() => _AvatarActionTileState();
}

class _AvatarActionTileState extends State<_AvatarActionTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fade = CurvedAnimation(parent: _enter, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic));
    Future<void>.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _enter.forward();
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: AppPressable(
          scale: 0.95,
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 22,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
