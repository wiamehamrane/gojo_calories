import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../providers/groups_provider.dart';

class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  int _selectedTab = 0;
  final List<String> _tabs = ["Feed", "My Groups", "Discover"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Groups", style: AppTextStyles.screenTitle),
                  IconButton(
                    onPressed: _showCreateGroupSheet,
                    icon: const Icon(LucideIcons.plus, color: AppColors.textPrimary),
                    tooltip: "Create Group",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final bool active = i == _selectedTab;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTab = i),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _tabs[i],
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                              color: active ? AppColors.textPrimary : AppColors.inactive,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 2, width: 24,
                            color: active ? AppColors.primary : Colors.transparent,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: const [
                  _FeedTab(),
                  _MyGroupsTab(),
                  _DiscoverTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateGroupSheet() {
    final nameController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Create Group", style: AppTextStyles.cardHeading),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Group name...",
                  hintStyle: TextStyle(color: AppColors.textPlaceholder),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Create", style: AppTextStyles.buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedTab extends ConsumerWidget {
  const _FeedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(communityFeedProvider);
    return feedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => _EmptyFeedPlaceholder(),
      data: (items) {
        if (items.isEmpty) return _EmptyFeedPlaceholder();
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) {
            final item = items[i];
            return _FeedCard(
              userName: item['user_name'] ?? 'Anonymous',
              mealName: item['meal_name'] ?? 'Meal',
              calories: item['calories'] ?? 0,
              groupName: item['group_name'] ?? 'Community',
            );
          },
        );
      },
    );
  }
}

class _MyGroupsTab extends ConsumerWidget {
  const _MyGroupsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(myGroupsProvider);
    return groupsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => _EmptyGroupsPlaceholder(message: "You haven't joined any groups yet."),
      data: (groups) {
        if (groups.isEmpty) return _EmptyGroupsPlaceholder(message: "You haven't joined any groups yet.");
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          itemCount: groups.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) {
            final g = groups[i];
            return _GroupCard(
              name: g['name'] ?? 'Group',
              description: g['description'] ?? '',
              memberCount: g['member_count'] ?? 0,
              joined: true,
            );
          },
        );
      },
    );
  }
}

class _DiscoverTab extends ConsumerWidget {
  const _DiscoverTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(discoverGroupsProvider);
    return groupsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => _EmptyGroupsPlaceholder(message: "No groups to discover right now."),
      data: (groups) {
        if (groups.isEmpty) return _EmptyGroupsPlaceholder(message: "No groups to discover right now.");
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          itemCount: groups.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) {
            final g = groups[i];
            return _GroupCard(
              name: g['name'] ?? 'Group',
              description: g['description'] ?? '',
              memberCount: g['member_count'] ?? 0,
              joined: false,
              onJoin: () async {
                await GroupsController.joinGroup(g['id']);
                ref.invalidate(myGroupsProvider);
                ref.invalidate(discoverGroupsProvider);
              },
            );
          },
        );
      },
    );
  }
}

// ─── Cards ───────────────────────────────────────────────────────────────────

class _FeedCard extends StatelessWidget {
  final String userName;
  final String mealName;
  final int calories;
  final String groupName;

  const _FeedCard({
    required this.userName,
    required this.mealName,
    required this.calories,
    required this.groupName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.cardShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.surfaceMuted,
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(userName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(width: 4),
                    Text("in $groupName", style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 2),
                Text("logged $mealName", style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
              ],
            ),
          ),
          Column(
            children: [
              const Icon(LucideIcons.flame, size: 16, color: AppColors.fire),
              Text("$calories", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const Text("kcal", style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final String name;
  final String description;
  final int memberCount;
  final bool joined;
  final VoidCallback? onJoin;

  const _GroupCard({
    required this.name,
    required this.description,
    required this.memberCount,
    required this.joined,
    this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.cardShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(12)),
            child: const Icon(LucideIcons.users, size: 22, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                if (description.isNotEmpty)
                  Text(description, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text("$memberCount members", style: const TextStyle(fontSize: 12, color: AppColors.inactive)),
              ],
            ),
          ),
          if (!joined && onJoin != null)
            GestureDetector(
              onTap: onJoin,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text("Join", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            )
          else if (joined)
            const Text("Joined ✓", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
        ],
      ),
    );
  }
}

class _EmptyFeedPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.rss, size: 48, color: AppColors.inactive.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          const Text("Your community feed is empty", style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          const Text("Join a group to see activity here.", style: TextStyle(fontSize: 13, color: AppColors.inactive)),
        ],
      ),
    );
  }
}

class _EmptyGroupsPlaceholder extends StatelessWidget {
  final String message;
  const _EmptyGroupsPlaceholder({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.users, size: 48, color: AppColors.inactive.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(fontSize: 15, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
