import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/repository_providers.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/repositories/coaches_repository.dart';
import '../../domain/models/coach.dart';

class CoachDetailScreen extends ConsumerStatefulWidget {
  final String coachId;

  const CoachDetailScreen({super.key, required this.coachId});

  @override
  ConsumerState<CoachDetailScreen> createState() => _CoachDetailScreenState();
}

class _CoachDetailScreenState extends ConsumerState<CoachDetailScreen> {
  Future<Coach>? _future;
  bool _contactLoading = false;

  Future<Coach> _load() {
    return ref.read(coachesRepositoryProvider).getPublic(widget.coachId);
  }

  Future<void> _showContactSheet(String Function(String) t) async {
    if (_contactLoading) return;
    setState(() => _contactLoading = true);
    try {
      final contact =
          await ref.read(coachesRepositoryProvider).contact(widget.coachId);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _ContactSheet(
          t: t,
          contact: contact,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('coaches_contact_failed'))),
      );
    } finally {
      if (mounted) setState(() => _contactLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    String t(String k) => Translations.t(lang, k);
    _future ??= _load();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<Coach>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t('coaches_detail_failed'),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: () => setState(() => _future = _load()),
                      child: Text(t('retry')),
                    ),
                  ],
                ),
              ),
            );
          }

          final coach = snapshot.data!;
          final name = coach.name?.trim().isNotEmpty == true
              ? coach.name!
              : t('coaches_unnamed');
          final initial = name.characters.first.toUpperCase();

          return Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      expandedHeight: 220,
                      backgroundColor: AppColors.surface,
                      surfaceTintColor: Colors.transparent,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.primaryLight,
                                AppColors.background,
                              ],
                            ),
                          ),
                          child: SafeArea(
                            bottom: false,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                CircleAvatar(
                                  radius: 48,
                                  backgroundColor: AppColors.surface,
                                  backgroundImage: coach.avatarUrl != null &&
                                          coach.avatarUrl!.isNotEmpty
                                      ? NetworkImage(coach.avatarUrl!)
                                      : null,
                                  child: coach.avatarUrl == null ||
                                          coach.avatarUrl!.isEmpty
                                      ? Text(
                                          initial,
                                          style: const TextStyle(
                                            fontSize: 34,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primaryDark,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (coach.city != null &&
                                    coach.city!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        LucideIcons.mapPin,
                                        size: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        coach.city!,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          if (coach.bio != null &&
                              coach.bio!.trim().isNotEmpty)
                            _SectionCard(
                              title: t('coaches_about'),
                              child: Text(
                                coach.bio!,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.45,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          if (coach.specialties.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _SectionCard(
                              title: t('coaches_specialty'),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: coach.specialties.map((s) {
                                  final key = 'coach_specialty_$s';
                                  final label = t(key);
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      label == key ? s : label,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          _SectionCard(
                            title: t('coaches_info'),
                            child: Column(
                              children: [
                                if (coach.experienceYears != null)
                                  _InfoRow(
                                    icon: LucideIcons.award,
                                    label: t('coaches_experience').replaceAll(
                                      '{years}',
                                      coach.experienceYears.toString(),
                                    ),
                                  ),
                                if (coach.coachingMode != null) ...[
                                  if (coach.experienceYears != null)
                                    const SizedBox(height: 10),
                                  _InfoRow(
                                    icon: LucideIcons.video,
                                    label: t(
                                      'coach_mode_${coach.coachingMode}',
                                    ),
                                  ),
                                ],
                                if (coach.languages.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  _InfoRow(
                                    icon: LucideIcons.languages,
                                    label: coach.languages
                                        .map((l) => l.toUpperCase())
                                        .join(' · '),
                                  ),
                                ],
                                if (coach.gender != null) ...[
                                  const SizedBox(height: 10),
                                  _InfoRow(
                                    icon: LucideIcons.user,
                                    label: coach.gender == 'female'
                                        ? t('gender_female')
                                        : t('gender_male'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _contactLoading
                          ? null
                          : () {
                              HapticFeedback.selectionClick();
                              _showContactSheet(t);
                            },
                      icon: _contactLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(LucideIcons.messageCircle),
                      label: Text(t('coaches_contact')),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: AppColors.primaryDark),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ContactSheet extends StatelessWidget {
  final String Function(String) t;
  final CoachContact contact;

  const _ContactSheet({required this.t, required this.contact});

  Future<void> _launch(String? raw) async {
    if (raw == null || raw.isEmpty) return;
    final uri = Uri.parse(raw);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.paddingOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            t('coaches_contact_title'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t('coaches_contact_subtitle'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          _ContactAction(
            icon: LucideIcons.phone,
            label: t('coaches_call'),
            color: AppColors.primaryDark,
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).pop();
              _launch(contact.callUri);
            },
          ),
          const SizedBox(height: 10),
          _ContactAction(
            icon: LucideIcons.messageCircle,
            label: t('coaches_whatsapp'),
            color: const Color(0xFF25D366),
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).pop();
              _launch(contact.whatsappUrl);
            },
          ),
        ],
      ),
    );
  }
}

class _ContactAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ContactAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              Icon(LucideIcons.chevronRight, size: 18, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
