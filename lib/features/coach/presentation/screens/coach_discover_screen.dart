import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../events/domain/models/event_location_selection.dart';
import '../../../events/presentation/widgets/event_location_picker_sheet.dart';
import '../../domain/models/coach.dart';
import '../providers/coach_discover_provider.dart';
import '../widgets/coach_ui.dart';

const _specialtyOptions = [
  'nutrition',
  'weight_loss',
  'muscle',
  'cardio',
  'general',
];

class CoachDiscoverScreen extends ConsumerStatefulWidget {
  const CoachDiscoverScreen({super.key});

  @override
  ConsumerState<CoachDiscoverScreen> createState() =>
      _CoachDiscoverScreenState();
}

class _CoachDiscoverScreenState extends ConsumerState<CoachDiscoverScreen> {
  final _scrollController = ScrollController();
  bool _filtersExpanded = false;
  bool _askedLocationThisVisit = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _askedLocationThisVisit) return;
      _askedLocationThisVisit = true;
      _onUseGps(silentIfDeniedForever: false);
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 240) {
      ref.read(coachDiscoverProvider.notifier).loadMore();
    }
  }

  String _t(String key) => Translations.t(ref.read(localeProvider), key);

  String _errorMessage(String? code) {
    if (code == null) return _t('error');
    final mapped = Translations.t(ref.read(localeProvider), code);
    return mapped == code ? _t('error') : mapped;
  }

  Future<void> _onUseGps({bool silentIfDeniedForever = false}) async {
    HapticFeedback.selectionClick();
    final notifier = ref.read(coachDiscoverProvider.notifier);
    await notifier.useCurrentLocation();
    if (!mounted) return;
    final error = ref.read(coachDiscoverProvider).error;
    if (error == 'location_permission_denied_forever' &&
        !silentIfDeniedForever) {
      await _showOpenSettingsDialog();
    }
  }

  Future<void> _showOpenSettingsDialog() async {
    final lang = ref.read(localeProvider);
    String t(String k) => Translations.t(lang, k);
    final open = await AppConfirmDialog.show(
      context,
      title: t('location_permission_title'),
      message: t('location_permission_denied_forever'),
      cancelLabel: t('cancel'),
      confirmLabel: t('location_open_settings'),
    );
    if (open == true) {
      await ref.read(coachDiscoverProvider.notifier).openLocationSettings();
    }
  }

  int _activeFilterCount(CoachDiscoverState state) {
    var count = 0;
    if (state.specialty != null) count++;
    if (state.gender != null) count++;
    if (state.radiusKm.round() != 25) count++;
    return count;
  }

  Future<void> _pickManualLocation() async {
    HapticFeedback.selectionClick();
    final state = ref.read(coachDiscoverProvider);
    final selected = await EventLocationPickerSheet.show(
      context,
      initial: state.hasLocation
          ? EventLocationSelection(
              name: state.locationLabel == 'current_location'
                  ? _t('coaches_current_location')
                  : (state.locationLabel ?? ''),
              latitude: state.latitude,
              longitude: state.longitude,
            )
          : null,
    );
    if (selected == null || !selected.hasCoordinates || !mounted) return;
    ref.read(coachDiscoverProvider.notifier).setManualLocation(
          latitude: selected.latitude!,
          longitude: selected.longitude!,
          label: selected.name,
        );
    await ref.read(coachDiscoverProvider.notifier).search(reset: true);
  }

  Future<void> _applyFilters() async {
    HapticFeedback.selectionClick();
    setState(() => _filtersExpanded = false);
    await ref.read(coachDiscoverProvider.notifier).search(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    String t(String k) => Translations.t(lang, k);
    final state = ref.watch(coachDiscoverProvider);
    final bottomInset = MediaQuery.of(context).padding.bottom + 88;
    final maxFilterHeight = MediaQuery.sizeOf(context).height * 0.48;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CoachGradientHeader(
              title: t('coaches_title'),
              subtitle: t('coaches_subtitle'),
              icon: LucideIcons.users,
            )
                .animate()
                .fadeIn(duration: 420.ms, curve: Curves.easeOut)
                .slideY(begin: -0.06, curve: Curves.easeOutCubic),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _FilterBar(
                expanded: _filtersExpanded,
                maxExpandedHeight: maxFilterHeight,
                state: state,
                activeCount: _activeFilterCount(state),
                t: t,
                onToggle: () {
                  HapticFeedback.selectionClick();
                  setState(() => _filtersExpanded = !_filtersExpanded);
                },
                onUseGps: () => _onUseGps(),
                onPickManual: _pickManualLocation,
                onRadiusChanged: (v) =>
                    ref.read(coachDiscoverProvider.notifier).setRadiusKm(v),
                onSpecialtyChanged: (v) =>
                    ref.read(coachDiscoverProvider.notifier).setSpecialty(v),
                onGenderChanged: (v) =>
                    ref.read(coachDiscoverProvider.notifier).setGender(v),
                onApply: _applyFilters,
              )
                  .animate()
                  .fadeIn(delay: 80.ms, duration: 400.ms)
                  .slideY(begin: 0.04, curve: Curves.easeOutCubic),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildBody(state, t, bottomInset)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    CoachDiscoverState state,
    String Function(String) t,
    double bottomInset,
  ) {
    if (state.loading && state.items.isEmpty) {
      return const _CoachLoadingList();
    }

    if (state.error != null && state.items.isEmpty) {
      return _EmptyState(
        message: _errorMessage(state.error),
        primaryLabel: state.error == 'location_permission_denied_forever'
            ? t('location_open_settings')
            : t('coaches_use_gps'),
        secondaryLabel: t('coaches_choose_location'),
        onPrimary: state.error == 'location_permission_denied_forever'
            ? () async {
                await ref
                    .read(coachDiscoverProvider.notifier)
                    .openLocationSettings();
              }
            : () => _onUseGps(),
        onSecondary: _pickManualLocation,
      );
    }

    if (!state.hasLocation) {
      return _EmptyState(
        message: t('location_required'),
        primaryLabel: t('coaches_use_gps'),
        secondaryLabel: t('coaches_choose_location'),
        onPrimary: () => _onUseGps(),
        onSecondary: _pickManualLocation,
      );
    }

    if (state.items.isEmpty) {
      return _EmptyState(
        message: t('coaches_empty'),
        primaryLabel: t('coaches_choose_location'),
        secondaryLabel: t('coaches_use_gps'),
        onPrimary: _pickManualLocation,
        onSecondary: () => _onUseGps(),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () =>
          ref.read(coachDiscoverProvider.notifier).search(reset: true),
      child: ListView.separated(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(16, 4, 16, bottomInset),
        itemCount: state.items.length + (state.loadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= state.items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final coach = state.items[index];
          return _CoachCard(
            coach: coach,
            t: t,
            index: index,
            onTap: () {
              HapticFeedback.selectionClick();
              context.push(RoutePaths.coachDetailPath(coach.id));
            },
          );
        },
      ),
    );
  }
}

class _CoachLoadingList extends StatelessWidget {
  const _CoachLoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Container(
          height: 118,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(
              duration: 1200.ms,
              color: AppColors.primaryLight.withValues(alpha: 0.55),
            )
            .fadeIn(delay: (index * 60).ms);
      },
    );
  }
}

class _FilterBar extends StatelessWidget {
  final bool expanded;
  final double maxExpandedHeight;
  final CoachDiscoverState state;
  final int activeCount;
  final String Function(String) t;
  final VoidCallback onToggle;
  final VoidCallback onUseGps;
  final VoidCallback onPickManual;
  final ValueChanged<double> onRadiusChanged;
  final ValueChanged<String?> onSpecialtyChanged;
  final ValueChanged<String?> onGenderChanged;
  final VoidCallback onApply;

  const _FilterBar({
    required this.expanded,
    required this.maxExpandedHeight,
    required this.state,
    required this.activeCount,
    required this.t,
    required this.onToggle,
    required this.onUseGps,
    required this.onPickManual,
    required this.onRadiusChanged,
    required this.onSpecialtyChanged,
    required this.onGenderChanged,
    required this.onApply,
  });

  String get _summaryLocation {
    if (!state.hasLocation) return t('coaches_no_location');
    if (state.locationLabel == 'current_location') {
      return t('coaches_current_location');
    }
    return state.locationLabel ?? t('coaches_manual_location');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: AppColors.chipGradient,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        LucideIcons.slidersHorizontal,
                        size: 16,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('coaches_filters'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '$_summaryLocation · ${state.radiusKm.round()} km',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (activeCount > 0)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$activeCount',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: Icon(
                        LucideIcons.chevronDown,
                        size: 18,
                        color: AppColors.inactive,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: expanded
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: (maxExpandedHeight - 72).clamp(120, 1000),
                        ),
                        child: SingleChildScrollView(
                          child: _FilterDetails(
                            state: state,
                            t: t,
                            onUseGps: onUseGps,
                            onPickManual: onPickManual,
                            onRadiusChanged: onRadiusChanged,
                            onSpecialtyChanged: onSpecialtyChanged,
                            onGenderChanged: onGenderChanged,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                        child: SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            onPressed: state.hasLocation ? onApply : null,
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(t('coaches_apply_filters')),
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _FilterDetails extends StatelessWidget {
  final CoachDiscoverState state;
  final String Function(String) t;
  final VoidCallback onUseGps;
  final VoidCallback onPickManual;
  final ValueChanged<double> onRadiusChanged;
  final ValueChanged<String?> onSpecialtyChanged;
  final ValueChanged<String?> onGenderChanged;

  const _FilterDetails({
    required this.state,
    required this.t,
    required this.onUseGps,
    required this.onPickManual,
    required this.onRadiusChanged,
    required this.onSpecialtyChanged,
    required this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          Text(
            t('coaches_location'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _OutlineAction(
                  icon: LucideIcons.locateFixed,
                  label: t('coaches_use_gps'),
                  onTap: onUseGps,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _OutlineAction(
                  icon: LucideIcons.mapPinned,
                  label: t('coaches_choose_location'),
                  onTap: onPickManual,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                t('coaches_distance_label'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  '${state.radiusKm.round()} km',
                  key: ValueKey(state.radiusKm.round()),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primaryDark,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.primaryDark,
              overlayColor: AppColors.primary.withValues(alpha: 0.12),
              trackHeight: 3,
            ),
            child: Slider(
              value: state.radiusKm.clamp(5, 100),
              min: 5,
              max: 100,
              divisions: 19,
              onChanged: onRadiusChanged,
            ),
          ),
          Text(
            t('coaches_specialty'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              CoachSelectTile(
                icon: LucideIcons.sparkles,
                label: t('coaches_any'),
                selected: state.specialty == null,
                onTap: () => onSpecialtyChanged(null),
              ),
              ..._specialtyOptions.map(
                (value) => CoachSelectTile(
                  icon: coachSpecialtyIcon(value),
                  label: t('coach_specialty_$value'),
                  selected: state.specialty == value,
                  accent: coachSpecialtyTint(value),
                  onTap: () => onSpecialtyChanged(value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            t('coaches_gender'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              CoachSelectTile(
                icon: LucideIcons.users,
                label: t('coaches_any'),
                selected: state.gender == null,
                onTap: () => onGenderChanged(null),
              ),
              CoachSelectTile(
                icon: LucideIcons.user,
                label: t('gender_male'),
                selected: state.gender == 'male',
                onTap: () => onGenderChanged('male'),
              ),
              CoachSelectTile(
                icon: LucideIcons.user,
                label: t('gender_female'),
                selected: state.gender == 'female',
                onTap: () => onGenderChanged('female'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OutlineAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OutlineAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CoachPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: AppColors.primaryDark),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoachCard extends StatelessWidget {
  final Coach coach;
  final String Function(String) t;
  final int index;
  final VoidCallback onTap;

  const _CoachCard({
    required this.coach,
    required this.t,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = coach.name?.trim().isNotEmpty == true
        ? coach.name!
        : t('coaches_unnamed');
    final initial = name.characters.first.toUpperCase();
    final accent = coach.specialties.isNotEmpty
        ? coachSpecialtyTint(coach.specialties.first)
        : AppColors.primaryDark;

    return CoachPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.75)),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -24,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Hero(
                      tag: 'coach-avatar-${coach.id}',
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              accent.withValues(alpha: 0.35),
                              AppColors.primaryLight,
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(3),
                        child: CircleAvatar(
                          backgroundColor: AppColors.surface,
                          backgroundImage: coach.avatarUrl != null &&
                                  coach.avatarUrl!.isNotEmpty
                              ? NetworkImage(coach.avatarUrl!)
                              : null,
                          child: coach.avatarUrl == null ||
                                  coach.avatarUrl!.isEmpty
                              ? Text(
                                  initial,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: accent,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                coachModeIcon(coach.coachingMode),
                                size: 13,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  [
                                    if (coach.city != null &&
                                        coach.city!.isNotEmpty)
                                      coach.city!,
                                    if (coach.distanceKm != null)
                                      t('coaches_km_away').replaceAll(
                                        '{km}',
                                        coach.distanceKm!.toStringAsFixed(
                                          coach.distanceKm! < 10 ? 1 : 0,
                                        ),
                                      ),
                                  ].join(' · '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (coach.specialties.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: coach.specialties.take(3).map((s) {
                                final key = 'coach_specialty_$s';
                                final label = t(key);
                                final tint = coachSpecialtyTint(s);
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: tint.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        coachSpecialtyIcon(s),
                                        size: 11,
                                        color: tint,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        label == key ? s : label,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: tint,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        LucideIcons.chevronRight,
                        size: 16,
                        color: AppColors.inactive,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          delay: (40 + index * 55).ms,
          duration: 380.ms,
          curve: Curves.easeOut,
        )
        .slideY(begin: 0.08, curve: Curves.easeOutCubic)
        .scale(
          begin: const Offset(0.98, 0.98),
          curve: Curves.easeOutCubic,
        );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  const _EmptyState({
    required this.message,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom + 88;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 16, 24, bottomInset),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: AppColors.chipGradient,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.18),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      LucideIcons.mapPin,
                      color: AppColors.primaryDark,
                      size: 34,
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.04, 1.04),
                        duration: 1400.ms,
                        curve: Curves.easeInOut,
                      ),
                  const SizedBox(height: 18),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.05),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: onPrimary,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(primaryLabel),
                    ),
                  ).animate().fadeIn(delay: 140.ms).slideY(begin: 0.08),
                  TextButton(
                    onPressed: onSecondary,
                    child: Text(secondaryLabel),
                  ).animate().fadeIn(delay: 200.ms),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
