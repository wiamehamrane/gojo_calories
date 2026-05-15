import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gojocalories/core/theme/app_colors.dart';
import 'package:gojocalories/core/theme/app_radius.dart';
import 'package:gojocalories/core/theme/app_spacing.dart';
import 'package:gojocalories/core/theme/app_text_styles.dart';

class EventsFeedScreen extends ConsumerStatefulWidget {
  const EventsFeedScreen({super.key});

  @override
  ConsumerState<EventsFeedScreen> createState() => _EventsFeedScreenState();
}

class _EventsFeedScreenState extends ConsumerState<EventsFeedScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _activeCategory = 'All';
  final List<String> _categories = ['All', 'Running', 'Walking', 'Soccer', 'Cycling'];

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> mockEvents = [
      {
        'title': 'Morning Central Park Run',
        'type': 'Running',
        'date': 'Sat, May 20 • 8:00 AM',
        'location': 'Central Park, NY',
        'participants': 15,
        'imageUrl': 'https://images.unsplash.com/photo-1552674605-db6ffd4facb5?q=80&w=800&auto=format&fit=crop',
      },
      {
        'title': 'Weekend Soccer Match',
        'type': 'Soccer',
        'date': 'Sun, May 21 • 10:00 AM',
        'location': 'Westside Fields',
        'participants': 22,
        'imageUrl': 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?q=80&w=800&auto=format&fit=crop',
      },
      {
        'title': 'Sunset Yoga & Walk',
        'type': 'Walking',
        'date': 'Tue, May 23 • 6:30 PM',
        'location': 'Riverside Park',
        'participants': 8,
        'imageUrl': 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?q=80&w=800&auto=format&fit=crop',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 16, AppSpacing.screenPadding, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Explore Events', style: AppTextStyles.screenTitle),
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildCategoryChips()),
          SliverToBoxAdapter(child: _buildHeroSection()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 24, AppSpacing.screenPadding, 12),
              child: Text('Upcoming for You', style: AppTextStyles.sectionHeader.copyWith(fontSize: 18)),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildEventCardOverlay(mockEvents[index], index),
              childCount: mockEvents.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppColors.primaryDark,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text('Create', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(LucideIcons.search, color: AppColors.inactive, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search events...',
                hintStyle: TextStyle(color: AppColors.textPlaceholder, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const Icon(LucideIcons.slidersHorizontal, color: AppColors.primary, size: 20),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isActive = _activeCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _activeCategory = cat),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  border: Border.all(color: isActive ? AppColors.primary : AppColors.border),
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isActive ? Colors.white : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
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
      margin: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 24, AppSpacing.screenPadding, 0),
      height: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryMid], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Stack(
        children: [
          Positioned(right: -20, bottom: -20, child: Icon(LucideIcons.trophy, size: 140, color: Colors.white.withValues(alpha: 0.15))),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Community Challenge', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1)),
                const SizedBox(height: 8),
                const Text('Join the Mega Marathon\nthis Weekend!', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.2)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.chip)),
                  child: const Text('Join Now', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCardOverlay(Map<String, dynamic> event, int index) {
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 0, AppSpacing.screenPadding, 16),
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        image: DecorationImage(image: NetworkImage(event['imageUrl']), fit: BoxFit.cover),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.3), Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(AppRadius.chip)),
              child: Text(event['type'].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['title'],
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 8)]),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(LucideIcons.calendar, size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(event['date'], style: const TextStyle(color: Colors.white, fontSize: 12)),
                    const SizedBox(width: 12),
                    const Icon(LucideIcons.users, size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text('${event['participants']} joined', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.05);
  }
}
