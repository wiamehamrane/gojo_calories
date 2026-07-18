import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../events/domain/models/event_location_selection.dart';
import '../../../events/presentation/widgets/event_location_picker_sheet.dart';
import '../../domain/models/coach.dart';
import '../providers/coach_discover_provider.dart';

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
    final open = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('location_permission_title')),
        content: Text(t('location_permission_denied_forever')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t('location_open_settings')),
          ),
        ],
      ),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('coaches_title'),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t('coaches_subtitle'),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
              ),
            ),
            const SizedBox(height: 10),
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
      return const Center(child: CircularProgressIndicator());
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
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.cardShadow,
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
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
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
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '$_summaryLocation · ${state.radiusKm.round()} km',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
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
                          horizontal: 7,
                          vertical: 3,
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
                      child: const Icon(
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
            duration: const Duration(milliseconds: 240),
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
                          height: 46,
                          child: FilledButton(
                            onPressed: state.hasLocation ? onApply : null,
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
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          Text(
            t('coaches_location'),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
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
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                t('coaches_distance_label'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '${state.radiusKm.round()} km',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
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
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                label: t('coaches_any'),
                selected: state.specialty == null,
                onTap: () => onSpecialtyChanged(null),
              ),
              ..._specialtyOptions.map(
                (value) => _FilterChip(
                  label: t('coach_specialty_$value'),
                  selected: state.specialty == value,
                  onTap: () => onSpecialtyChanged(value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            t('coaches_gender'),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                label: t('coaches_any'),
                selected: state.gender == null,
                onTap: () => onGenderChanged(null),
              ),
              _FilterChip(
                label: t('gender_male'),
                selected: state.gender == 'male',
                onTap: () => onGenderChanged('male'),
              ),
              _FilterChip(
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
    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
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
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadius.chip),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.primaryDark : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _CoachCard extends StatelessWidget {
  final Coach coach;
  final String Function(String) t;
  final VoidCallback onTap;

  const _CoachCard({
    required this.coach,
    required this.t,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = coach.name?.trim().isNotEmpty == true
        ? coach.name!
        : t('coaches_unnamed');
    final initial = name.characters.first.toUpperCase();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppShadows.cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage:
                      coach.avatarUrl != null && coach.avatarUrl!.isNotEmpty
                          ? NetworkImage(coach.avatarUrl!)
                          : null,
                  child: coach.avatarUrl == null || coach.avatarUrl!.isEmpty
                      ? Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        )
                      : null,
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (coach.city != null && coach.city!.isNotEmpty)
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
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (coach.specialties.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: coach.specialties.take(3).map((s) {
                            final key = 'coach_specialty_$s';
                            final label = t(key);
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                label == key ? s : label,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
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
      ),
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
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      LucideIcons.mapPin,
                      color: AppColors.primaryDark,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: onPrimary, child: Text(primaryLabel)),
                  TextButton(
                    onPressed: onSecondary,
                    child: Text(secondaryLabel),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
