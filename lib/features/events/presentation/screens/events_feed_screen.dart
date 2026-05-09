import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/events_provider.dart';
import '../../theme/events_theme.dart';
import '../widgets/event_card.dart';
import '../widgets/event_shimmer.dart';
import 'create_event_screen.dart';
import 'event_detail_screen.dart';

const _kCategories = ['All', 'Running', 'Walking', 'Soccer', 'Cycling'];

class EventsFeedScreen extends ConsumerStatefulWidget {
  const EventsFeedScreen({super.key});

  @override
  ConsumerState<EventsFeedScreen> createState() => _EventsFeedScreenState();
}

class _EventsFeedScreenState extends ConsumerState<EventsFeedScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String _activeCategory = 'All';
  bool _isMyEvents = false;
  bool _isSearchFocused = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() => _isSearchFocused = _searchFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(eventsProvider.notifier).fetchEvents(
            search: query.isNotEmpty ? query : null,
            type: _activeCategory == 'All' ? null : _activeCategory.toLowerCase(),
          );
    });
  }

  void _onCategoryChanged(String category) {
    setState(() => _activeCategory = category);
    ref.read(eventsProvider.notifier).fetchEvents(
          search: _searchController.text.isNotEmpty ? _searchController.text : null,
          type: category == 'All' ? null : category.toLowerCase(),
        );
  }

  Future<void> _onRefresh() async {
    await ref.read(eventsProvider.notifier).fetchEvents(
          search: _searchController.text.isNotEmpty ? _searchController.text : null,
          type: _activeCategory == 'All' ? null : _activeCategory.toLowerCase(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final eventsState = ref.watch(eventsProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: EventsTheme.background,
      body: Column(
        children: [
          // ── Sticky Header ─────────────────────────────────
          _buildHeader(topPadding),
          // ── Body ──────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: EventsTheme.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // Category filter chips
                  SliverToBoxAdapter(child: _buildCategoryChips()),
                  // Hero section (only when not searching)
                  if (_searchController.text.isEmpty && !_isMyEvents)
                    SliverToBoxAdapter(child: _buildHeroSection()),
                  // Events list title
                  SliverToBoxAdapter(child: _buildSectionTitle()),
                  // Events list
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: EventsTheme.pagePadding),
                    sliver: _buildEventsSliver(eventsState),
                  ),
                  // Bottom spacing
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  Widget _buildHeader(double topPadding) {
    return Container(
      color: EventsTheme.background,
      padding: EdgeInsets.only(
        top: topPadding + 8,
        left: EventsTheme.pagePadding,
        right: EventsTheme.pagePadding,
        bottom: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: title + segment toggle
          Row(
            children: [
              const Text(
                'Events',
                style: TextStyle(
                  color: EventsTheme.foreground,
                  fontFamily: EventsTheme.headingFont,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              _buildSegmentToggle(),
            ],
          ),
          const SizedBox(height: 12),
          // Search bar
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildSegmentToggle() {
    return Container(
      decoration: BoxDecoration(
        color: EventsTheme.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: EventsTheme.cardStroke),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton('Discover', !_isMyEvents),
          _buildToggleButton('My Events', _isMyEvents),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool active) {
    return GestureDetector(
      onTap: () {
        setState(() => _isMyEvents = label == 'My Events');
        _onRefresh();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? EventsTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : EventsTheme.muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 46,
      decoration: BoxDecoration(
        color: EventsTheme.cardBackground,
        borderRadius: BorderRadius.circular(EventsTheme.inputRadius),
        border: Border.all(
          color: _isSearchFocused ? EventsTheme.primary : EventsTheme.cardStroke,
          width: _isSearchFocused ? 1.5 : 1,
        ),
        boxShadow: _isSearchFocused
            ? [
                BoxShadow(
                  color: EventsTheme.primary.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                )
              ]
            : [],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(LucideIcons.search, size: 18, color: _isSearchFocused ? EventsTheme.primary : EventsTheme.muted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              style: const TextStyle(
                color: EventsTheme.foreground,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              decoration: const InputDecoration(
                hintText: 'Search events, locations…',
                hintStyle: TextStyle(color: EventsTheme.muted, fontSize: 15),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                _onSearchChanged('');
              },
              child: const Icon(LucideIcons.x, size: 16, color: EventsTheme.muted),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: EventsTheme.pagePadding, vertical: 8),
        itemCount: _kCategories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _kCategories[index];
          final active = cat == _activeCategory;
          final color = cat == 'All'
              ? EventsTheme.primary
              : EventsTheme.eventTypeColor(cat);
          return GestureDetector(
            onTap: () => _onCategoryChanged(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: active ? color : EventsTheme.cardBackground,
                borderRadius: BorderRadius.circular(EventsTheme.chipRadius),
                border: Border.all(
                  color: active ? color : EventsTheme.cardStroke,
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  color: active ? Colors.white : EventsTheme.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(EventsTheme.pagePadding, 8, EventsTheme.pagePadding, 0),
      decoration: BoxDecoration(
        gradient: EventsTheme.heroGradient,
        borderRadius: BorderRadius.circular(EventsTheme.cardRadius),
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(EventsTheme.chipRadius),
                  ),
                  child: const Text(
                    'COMMUNITY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Find your next\nfitness challenge.',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: EventsTheme.headingFont,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join 1M+ members on GojoCalories.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Icon(
            LucideIcons.trophy,
            size: 56,
            color: Colors.white.withValues(alpha: 0.18),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(EventsTheme.pagePadding, 24, EventsTheme.pagePadding, 12),
      child: Row(
        children: [
          Text(
            _isMyEvents ? 'My Events' : (_activeCategory == 'All' ? 'Upcoming Events' : '$_activeCategory Events'),
            style: const TextStyle(
              color: EventsTheme.foreground,
              fontFamily: EventsTheme.headingFont,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsSliver(AsyncValue eventsState) {
    return eventsState.when(
      loading: () => SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => const EventShimmerCard(),
          childCount: 3,
        ),
      ),
      error: (error, stackTrace) => SliverToBoxAdapter(
        child: _buildErrorState(),
      ),
      data: (events) {
        if (events.isEmpty) {
          return SliverToBoxAdapter(child: _buildEmptyState());
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => EventCard(
              event: events[index],
              onTap: () => Navigator.push(
                context,
                _buildDetailRoute(events[index].id),
              ),
            ),
            childCount: events.length,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: EventsTheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.calendarX, size: 36, color: EventsTheme.primary),
          ),
          const SizedBox(height: 20),
          const Text(
            'No events found',
            style: TextStyle(
              color: EventsTheme.foreground,
              fontFamily: EventsTheme.headingFont,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Be the first to host one!',
            style: TextStyle(color: EventsTheme.muted, fontSize: 14),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateEventScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: EventsTheme.primary,
                borderRadius: BorderRadius.circular(EventsTheme.chipRadius),
              ),
              child: const Text(
                'Create Event',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(LucideIcons.wifiOff, size: 40, color: EventsTheme.muted),
          const SizedBox(height: 16),
          const Text(
            'Couldn\'t load events',
            style: TextStyle(
              color: EventsTheme.foreground,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _onRefresh,
            child: Text(
              'Tap to retry',
              style: TextStyle(
                color: EventsTheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateEventScreen()),
      ),
      backgroundColor: EventsTheme.primaryDark,
      elevation: 4,
      icon: const Icon(LucideIcons.plus, color: Colors.white, size: 20),
      label: const Text(
        'Create',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }

  PageRoute _buildDetailRoute(String eventId) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => EventDetailScreen(eventId: eventId),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 280),
    );
  }
}
