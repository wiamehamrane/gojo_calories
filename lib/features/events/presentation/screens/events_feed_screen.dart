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
import '../widgets/event_card.dart';
import '../widgets/event_shimmer.dart';
import '../../domain/models/event.dart';

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

  String? _activeQuery;
  bool _searchHasText = false;

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
          backgroundColor: Colors.white,
          onRefresh: () async {
            setState(() => _activeQuery = null);
            _searchController.clear();
            await ref.read(eventsProvider.notifier).fetchEvents();
          },
          child: CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(bottom: false, child: _buildDarkHeader()),
              ),
              SliverToBoxAdapter(child: _buildWhiteSheet(eventsAsync)),
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
          const SizedBox(height: 32),
          const Text(
            'Events',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
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
              child: const Icon(
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
              style: const TextStyle(
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
                decoration: const BoxDecoration(
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
            const Padding(
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

  // ── White sheet with the events ─────────────────────────────────────────

  Widget _buildWhiteSheet(AsyncValue<List<Event>> eventsAsync) {
    final minHeight = MediaQuery.of(context).size.height * 0.62;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(_kSheetRadius)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              15,
              AppSpacing.screenPadding,
              12,
            ),
            child: _buildSectionHeader(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              0,
              AppSpacing.screenPadding,
              120,
            ),
            child: _buildEventsList(eventsAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    if (_activeQuery == null) {
     return SizedBox();
    }
    return Row(
      children: [
        const Icon(
          LucideIcons.sparkles,
          size: 16,
          color: AppColors.primaryDark,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Results for “$_activeQuery”',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.sectionHeader.copyWith(fontSize: 16),
          ),
        ),
        GestureDetector(
          onTap: _clearSearch,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Text(
              'Clear',
              style: AppTextStyles.bodyBold.copyWith(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventsList(AsyncValue<List<Event>> eventsAsync) {
    return eventsAsync.when(
      loading: () => const EventShimmerList(count: 3),
      error: (_, _) => _EmptyState(
        icon: LucideIcons.wifiOff,
        title: 'Couldn\'t load events',
        message: 'Check your connection and try again.',
        actionLabel: 'Retry',
        onAction: _retry,
      ),
      data: (events) {
        if (events.isEmpty) {
          return _EmptyState(
            icon: LucideIcons.calendarSearch,
            title: _activeQuery != null
                ? 'No matching events'
                : 'No upcoming events',
            message: _activeQuery != null
                ? 'Try a different search, or create the\nevent yourself.'
                : 'Be the first to create one in your area.',
            actionLabel: 'Create event',
            onAction: _openCreate,
          );
        }
        return Column(
          children: [
            for (final event in events)
              EventCard(
                event: event,
                onTap: () => context.push('/events/detail/${event.id}'),
              ),
          ],
        );
      },
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
