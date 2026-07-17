import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:gojocalories/core/routing/route_paths.dart';
import 'package:gojocalories/core/theme/app_colors.dart';
import 'package:gojocalories/core/theme/app_radius.dart';
import 'package:gojocalories/core/theme/app_spacing.dart';
import 'package:gojocalories/core/theme/app_text_styles.dart';
import '../providers/events_provider.dart';
import '../providers/shared_meals_provider.dart';
import '../widgets/event_card.dart';
import '../widgets/event_shimmer.dart';
import '../widgets/shared_meal_card.dart';
import '../../domain/models/event.dart';
import '../../domain/models/shared_meal.dart';

const _kDarkBackground = Color(0xFF0A0A0A);
const _kSheetRadius = 32.0;

class EventsFeedScreen extends ConsumerStatefulWidget {
  const EventsFeedScreen({super.key});

  @override
  ConsumerState<EventsFeedScreen> createState() => _EventsFeedScreenState();
}

class _EventsFeedScreenState extends ConsumerState<EventsFeedScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final PageController _mealsPageController = PageController();

  String? _activeQuery;
  bool _searchHasText = false;
  int _mealsPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final hasText = _searchController.text.trim().isNotEmpty;
      if (hasText != _searchHasText) {
        setState(() => _searchHasText = hasText);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _mealsPageController.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    HapticFeedback.selectionClick();
    _searchFocus.unfocus();
    setState(() => _activeQuery = query);
    await ref.read(eventsProvider.notifier).aiSearch(query);
  }

  void _clearSearch() {
    HapticFeedback.selectionClick();
    _searchController.clear();
    setState(() => _activeQuery = null);
    ref.read(eventsProvider.notifier).fetchEvents();
  }

  Future<void> _retry() async {
    if (_activeQuery != null) {
      await ref.read(eventsProvider.notifier).aiSearch(_activeQuery!);
    } else {
      await ref.read(eventsProvider.notifier).fetchEvents();
    }
  }

  void _openCreate() {
    HapticFeedback.lightImpact();
    context.push(RoutePaths.createEvent);
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _kDarkBackground,
        body: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            setState(() => _activeQuery = null);
            _searchController.clear();
            await Future.wait([
              ref.read(eventsProvider.notifier).fetchEvents(),
              ref.read(sharedMealsProvider.notifier).fetchMeals(),
            ]);
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(bottom: false, child: _buildDarkHeader()),
              ),
              if (_activeQuery == null) ...[
                SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding), child: _buildMealsSection(),)),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
              ..._buildEventsSlivers(eventsAsync),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Dark hero ───────────────────────────────────────────────────────────

  Widget _buildDarkHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        28,
        AppSpacing.screenPadding,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Where the doers and\nthe creatives and\nthe top meet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1.3,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                'Search for events in your city, or find people near you to train with.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSearchPill(),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _buildSearchPill() {
    final isLoading =
        _activeQuery != null && ref.watch(eventsProvider).isLoading;

    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5EA),
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // "+" — create an event, like the mockup
          GestureDetector(
            onTap: _openCreate,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.plus,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              textInputAction: TextInputAction.search,
              textAlign: TextAlign.center,
              onSubmitted: (_) => _runSearch(),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
              ),
              cursorColor: AppColors.textPrimary,
              decoration: const InputDecoration(
                hintText: 'I wanna go for a run…',
                hintStyle: TextStyle(
                  color: Color(0xFF6B6B6B),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(9),
              child: CupertinoActivityIndicator(radius: 9),
            )
          else if (_searchHasText)
            GestureDetector(
              onTap: _runSearch,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.textPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.arrowUp,
                  color: Colors.white,
                  size: 17,
                ),
              ),
            )
          else
            Padding(
              padding: EdgeInsets.only(right: 10),
              child: Icon(
                LucideIcons.sparkles,
                color: AppColors.primaryDark,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  // ── Meals: title outside, white card with horizontal scroll ─────────────

  Widget _buildMealsSection() {
    final mealsAsync = ref.watch(sharedMealsProvider);
    final meals = mealsAsync.value ?? const <SharedMeal>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            0,
            AppSpacing.screenPadding,
            12,
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Meals',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push(RoutePaths.shareMealChooser);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.plus,
                        size: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Share yours',
                        style: AppTextStyles.bodyBold.copyWith(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          clipBehavior: Clip.hardEdge,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(_kSheetRadius)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: mealsAsync.isLoading && meals.isEmpty
              ? const SizedBox(
                  height: 260,
                  child: Center(child: CupertinoActivityIndicator(radius: 11)),
                )
              : meals.isEmpty
                  ? SizedBox(height: 260, child: _buildSharedMealsEmpty())
                  : Column(
                      children: [
                        SizedBox(
                          height: 260,
                          child: PageView.builder(
                            controller: _mealsPageController,
                            itemCount: meals.length,
                            onPageChanged: (index) {
                              HapticFeedback.selectionClick();
                              setState(() => _mealsPageIndex = index);
                            },
                            itemBuilder: (context, index) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                child: SharedMealCard(
                                  meal: meals[index],
                                  width: double.infinity,
                                ),
                              );
                            },
                          ),
                        ),
                        if (meals.length > 1) ...[
                          const SizedBox(height: 12),
                          _MealsPageDots(
                            count: meals.length,
                            index: _mealsPageIndex.clamp(0, meals.length - 1),
                          ),
                        ],
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildSharedMealsEmpty() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: GestureDetector(
        onTap: () => context.push(RoutePaths.shareMealChooser),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.utensils,
                  size: 30, color: AppColors.inactive),
              const SizedBox(height: 10),
              Text(
                'No meals shared yet',
                style: AppTextStyles.bodyBold.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Cooked something great? Share it\nwith photo, macros & recipe.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyRegular.copyWith(
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Events: title outside, white card with vertical list ────────────────

  List<Widget> _buildEventsSlivers(AsyncValue<List<Event>> eventsAsync) {
    return [
      SliverToBoxAdapter(child: _buildEventsTitleOutside()),
      ...eventsAsync.when(
        loading: () => [
          SliverToBoxAdapter(
            child: _eventsCard(
              child: const Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  18,
                  AppSpacing.screenPadding,
                  24,
                ),
                child: EventShimmerList(count: 3),
              ),
            ),
          ),
        ],
        error: (_, _) => [
          SliverToBoxAdapter(
            child: _eventsCard(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24, top: 8),
                child: _EmptyState(
                  icon: LucideIcons.wifiOff,
                  title: 'Couldn\'t load events',
                  message: 'Check your connection and try again.',
                  actionLabel: 'Retry',
                  onAction: _retry,
                ),
              ),
            ),
          ),
        ],
        data: (events) {
          if (events.isEmpty) {
            return [
              SliverToBoxAdapter(
                child: _eventsCard(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24, top: 8),
                    child: _EmptyState(
                      icon: LucideIcons.calendarSearch,
                      title: _activeQuery != null
                          ? 'No matching events'
                          : 'No upcoming events',
                      message: _activeQuery != null
                          ? 'Try a different search, or create the\nevent yourself.'
                          : 'Be the first to create one in your area.',
                      actionLabel: 'Create event',
                      onAction: _openCreate,
                    ),
                  ),
                ),
              ),
            ];
          }
          return [
            SliverToBoxAdapter(
              child: _eventsCard(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    12,
                    AppSpacing.screenPadding,
                    24,
                  ),
                  child: Column(
                    children: [
                      for (final event in events)
                        EventCard(
                          event: event,
                          onTap: () =>
                              context.push('/events/detail/${event.id}'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
      ),
    ];
  }

  Widget _buildEventsTitleOutside() {
    if (_activeQuery != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          0,
          AppSpacing.screenPadding,
          12,
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.sparkles,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Results for “$_activeQuery”',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            GestureDetector(
              onTap: _clearSearch,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Text(
                  'Clear',
                  style: AppTextStyles.bodyBold.copyWith(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        0,
        AppSpacing.screenPadding,
        12,
      ),
      child: Text(
        'Events',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _eventsCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(_kSheetRadius)),
      ),
      child: child,
    );
  }
}

/// Centered, chrome-free empty/error state (iOS style).
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 36, color: AppColors.inactive),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyBold.copyWith(fontSize: 17),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyRegular.copyWith(height: 1.45),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Text(
                  actionLabel,
                  style: AppTextStyles.bodyBold.copyWith(
                    color: AppColors.primaryDark,
                    fontSize: 14,
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

class _MealsPageDots extends StatelessWidget {
  final int count;
  final int index;

  const _MealsPageDots({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count.clamp(0, 12), (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? AppColors.primaryDark : AppColors.border,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
