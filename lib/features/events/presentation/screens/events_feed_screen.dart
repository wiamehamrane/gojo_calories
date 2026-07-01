import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gojocalories/core/theme/app_colors.dart';
import 'package:gojocalories/core/theme/app_radius.dart';
import 'package:gojocalories/core/theme/app_spacing.dart';
import 'package:gojocalories/features/profile/presentation/providers/profile_providers.dart';

class EventsFeedScreen extends ConsumerStatefulWidget {
  const EventsFeedScreen({super.key});

  @override
  ConsumerState<EventsFeedScreen> createState() => _EventsFeedScreenState();
}

class _EventsFeedScreenState extends ConsumerState<EventsFeedScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    
    // Default to 'mixed' if profile not loaded
    final String userGender = profileAsync.maybeWhen(
      data: (data) => data['gender']?.toString().toLowerCase() ?? 'male',
      orElse: () => 'male',
    );

    // Mockup data for Events with gender requirements
    final List<Map<String, dynamic>> allEvents = [
      {
        'title': 'Mens Heavy Lifting',
        'gender': 'male',
        'date': 'Sat, May 20 • 8:00 AM',
        'location': 'Power Gym, NY',
        'participants': 12,
        'imageUrl': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=800&auto=format&fit=crop',
      },
      {
        'title': 'Morning Central Park Run',
        'gender': 'mixed',
        'date': 'Sat, May 20 • 8:00 AM',
        'location': 'Central Park, NY',
        'participants': 15,
        'imageUrl': 'https://images.unsplash.com/photo-1552674605-db6ffd4facb5?q=80&w=800&auto=format&fit=crop',
      },
      {
        'title': 'Females Yoga Flow',
        'gender': 'female',
        'date': 'Sun, May 21 • 9:00 AM',
        'location': 'Zen Studio',
        'participants': 18,
        'imageUrl': 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?q=80&w=800&auto=format&fit=crop',
      },
      {
        'title': 'Weekend Soccer Match',
        'gender': 'mixed',
        'date': 'Sun, May 21 • 10:00 AM',
        'location': 'Westside Fields',
        'participants': 22,
        'imageUrl': 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?q=80&w=800&auto=format&fit=crop',
      },
    ];

    // Filter events based on user gender
    final filteredEvents = allEvents.where((e) {
      final String eventGender = e['gender'];
      if (eventGender == 'mixed') return true;
      return eventGender == userGender;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Search Bar (No "Explore Events" title)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 16, AppSpacing.screenPadding, 8),
              child: _buildSearchBar(),
            ),
          ),

          // Hero Section
          SliverToBoxAdapter(
            child: _buildHeroSection(),
          ),

          // Events List
          SliverPadding(
            padding: const EdgeInsets.only(top: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildEventCardCompact(filteredEvents[index], index),
                childCount: filteredEvents.length,
              ),
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

  Widget _buildHeroSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 20, AppSpacing.screenPadding, 0),
      height: 140,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryMid],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Stack(
        children: [
          Positioned(right: -10, bottom: -10, child: Icon(LucideIcons.trophy, size: 100, color: Colors.white.withValues(alpha: 0.1))),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Featured Challenge', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                const Text('Mega Marathon 2024', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.chip)),
                  child: const Text('Join Now', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCardCompact(Map<String, dynamic> event, int index) {
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 0, AppSpacing.screenPadding, 12),
      height: 160, // Smaller height as requested
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        image: DecorationImage(image: NetworkImage(event['imageUrl']), fit: BoxFit.cover),
      ),
      child: Stack(
        children: [
          // Darker overlay for better contrast
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2), 
                    Colors.black.withValues(alpha: 0.8)
                  ],
                ),
              ),
            ),
          ),
          
          // Gender Badge (Bottom Right instead of Top Left Category)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.chip),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    event['gender'] == 'mixed' 
                        ? LucideIcons.users 
                        : (event['gender'] == 'male' ? LucideIcons.mars : LucideIcons.venus),
                    size: 10,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    event['gender'].toString().toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // Event Details (Bottom)
          Positioned(
            bottom: 12,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['title'],
                  style: const TextStyle(
                    color: Colors.white, 
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(LucideIcons.calendar, size: 12, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(event['date'], style: const TextStyle(color: Colors.white, fontSize: 11)),
                    const SizedBox(width: 12),
                    const Icon(LucideIcons.mapPin, size: 12, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(event['location'], style: const TextStyle(color: Colors.white, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 80).ms).slideY(begin: 0.05);
  }
}
