import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/repository_providers.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_message.dart';
import '../../data/repositories/coaches_repository.dart';
import '../../domain/models/coach.dart';
import '../widgets/coach_ui.dart';

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
      AppMessage.error(context, t('coaches_contact_failed'));
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
                      style: TextStyle(color: AppColors.textSecondary),
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
          final accent = coach.specialties.isNotEmpty
              ? coachSpecialtyTint(coach.specialties.first)
              : AppColors.primaryDark;

          return Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      expandedHeight: 260,
                      backgroundColor: AppColors.surface,
                      surfaceTintColor: Colors.transparent,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: AppColors.heroGradient,
                              stops: const [0, 0.55, 1],
                            ),
                          ),
                          child: SafeArea(
                            bottom: false,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Hero(
                                  tag: 'coach-avatar-${coach.id}',
                                  child: Container(
                                    width: 104,
                                    height: 104,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          accent.withValues(alpha: 0.35),
                                          AppColors.primaryLight,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: accent.withValues(alpha: 0.25),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: CircleAvatar(
                                      radius: 48,
                                      backgroundColor: AppColors.surface,
                                      backgroundImage: coach.avatarUrl !=
                                                  null &&
                                              coach.avatarUrl!.isNotEmpty
                                          ? NetworkImage(coach.avatarUrl!)
                                          : null,
                                      child: coach.avatarUrl == null ||
                                              coach.avatarUrl!.isEmpty
                                          ? Text(
                                              initial,
                                              style: TextStyle(
                                                fontSize: 34,
                                                fontWeight: FontWeight.w700,
                                                color: accent,
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.4,
                                  ),
                                ).animate().fadeIn(delay: 60.ms).slideY(
                                      begin: 0.08,
                                      curve: Curves.easeOutCubic,
                                    ),
                                if (coach.city != null &&
                                    coach.city!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        LucideIcons.mapPin,
                                        size: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        coach.city!,
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ).animate().fadeIn(delay: 100.ms),
                                ],
                                const SizedBox(height: 20),
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
                            CoachSectionCard(
                              title: t('coaches_about'),
                              icon: LucideIcons.fileText,
                              child: Text(
                                coach.bio!,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.45,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            )
                                .animate()
                                .fadeIn(delay: 80.ms, duration: 360.ms)
                                .slideY(
                                  begin: 0.05,
                                  curve: Curves.easeOutCubic,
                                ),
                          if (coach.specialties.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            CoachSectionCard(
                              title: t('coaches_specialty'),
                              icon: LucideIcons.sparkles,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: coach.specialties.map((s) {
                                  final key = 'coach_specialty_$s';
                                  final label = t(key);
                                  final tint = coachSpecialtyTint(s);
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: tint.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: tint.withValues(alpha: 0.28),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          coachSpecialtyIcon(s),
                                          size: 14,
                                          color: tint,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          label == key ? s : label,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: tint,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            )
                                .animate()
                                .fadeIn(delay: 140.ms, duration: 360.ms)
                                .slideY(
                                  begin: 0.05,
                                  curve: Curves.easeOutCubic,
                                ),
                          ],
                          const SizedBox(height: 12),
                          CoachSectionCard(
                            title: t('coaches_info'),
                            icon: LucideIcons.info,
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
                                    icon: coachModeIcon(coach.coachingMode),
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
                          )
                              .animate()
                              .fadeIn(delay: 200.ms, duration: 360.ms)
                              .slideY(
                                begin: 0.05,
                                curve: Curves.easeOutCubic,
                              ),
                          if (coach.works.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            CoachSectionCard(
                              title: t('coach_portfolio_title'),
                              icon: LucideIcons.images,
                              child: Column(
                                children: [
                                  for (var i = 0;
                                      i < coach.works.length;
                                      i++) ...[
                                    if (i > 0) const SizedBox(height: 12),
                                    _BeforeAfterPair(
                                      work: coach.works[i],
                                      beforeLabel: t('coach_portfolio_before'),
                                      afterLabel: t('coach_portfolio_after'),
                                    ),
                                  ],
                                ],
                              ),
                            )
                                .animate()
                                .fadeIn(delay: 260.ms, duration: 360.ms)
                                .slideY(
                                  begin: 0.05,
                                  curve: Curves.easeOutCubic,
                                ),
                          ],
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
              ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.88),
                      border: Border(
                        top: BorderSide(
                          color: AppColors.border.withValues(alpha: 0.8),
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
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

class _BeforeAfterPair extends StatelessWidget {
  final CoachWork work;
  final String beforeLabel;
  final String afterLabel;

  const _BeforeAfterPair({
    required this.work,
    required this.beforeLabel,
    required this.afterLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _LabeledPhoto(
                url: work.beforeUrl,
                label: beforeLabel,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _LabeledPhoto(
                url: work.afterUrl,
                label: afterLabel,
              ),
            ),
          ],
        ),
        if (work.caption != null && work.caption!.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            work.caption!,
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _LabeledPhoto extends StatelessWidget {
  final String url;
  final String label;

  const _LabeledPhoto({required this.url, required this.label});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url.isNotEmpty)
              Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: AppColors.surfaceMuted,
                  alignment: Alignment.center,
                  child: const Icon(LucideIcons.imageOff),
                ),
              )
            else
              Container(color: AppColors.surfaceMuted),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 5),
                color: Colors.black.withValues(alpha: 0.45),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
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
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: AppColors.primaryDark),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
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
      decoration: BoxDecoration(
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t('coaches_contact_subtitle'),
            textAlign: TextAlign.center,
            style: TextStyle(
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
