import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/repository_providers.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_message.dart';
import '../../../../core/widgets/cached_food_image.dart';
import '../../domain/models/coach_post.dart';

class CoachSocialProfileScreen extends ConsumerStatefulWidget {
  final String coachId;

  const CoachSocialProfileScreen({super.key, required this.coachId});

  @override
  ConsumerState<CoachSocialProfileScreen> createState() =>
      _CoachSocialProfileScreenState();
}

class _CoachSocialProfileScreenState
    extends ConsumerState<CoachSocialProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  CoachSocialProfile? _profile;
  String? _error;
  bool _loading = true;
  bool _contactBusy = false;
  bool _starBusy = false;

  final Map<String, List<CoachPost>> _postsByTab = {
    'images': [],
    'videos': [],
  };
  final Map<String, bool> _loadingTab = {
    'images': false,
    'videos': false,
  };
  final Map<String, bool> _hasMore = {
    'images': true,
    'videos': true,
  };
  final Map<String, int> _page = {
    'images': 0,
    'videos': 0,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _bootstrap();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  String get _activeTab => _tabController.index == 0 ? 'images' : 'videos';

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final tab = _activeTab;
    if (_postsByTab[tab]!.isEmpty && !_loadingTab[tab]!) {
      _loadPosts(tab, reset: true);
    }
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile =
          await ref.read(coachesRepositoryProvider).getSocial(widget.coachId);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
      await _loadPosts('images', reset: true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'coach_social_load_failed';
      });
    }
  }

  Future<void> _loadPosts(String tab, {bool reset = false}) async {
    if (_loadingTab[tab] == true) return;
    if (!reset && _hasMore[tab] != true) return;

    setState(() => _loadingTab[tab] = true);
    try {
      final nextPage = reset ? 1 : (_page[tab]! + 1);
      final page = await ref.read(coachesRepositoryProvider).listPosts(
            coachId: widget.coachId,
            tab: tab,
            page: nextPage,
          );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _postsByTab[tab] = page.items;
        } else {
          _postsByTab[tab] = [..._postsByTab[tab]!, ...page.items];
        }
        _page[tab] = page.page;
        _hasMore[tab] = page.hasMore;
        _loadingTab[tab] = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingTab[tab] = false);
    }
  }

  Future<void> _toggleStar() async {
    final profile = _profile;
    if (profile == null || profile.isOwner || _starBusy) return;

    setState(() => _starBusy = true);
    HapticFeedback.selectionClick();
    try {
      final starred =
          await ref.read(coachesRepositoryProvider).toggleStar(profile.id);
      if (!mounted) return;
      setState(() {
        _profile = profile.copyWith(isStarred: starred);
        _starBusy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _starBusy = false);
      AppMessage.error(
        context,
        Translations.t(ref.read(localeProvider), 'coach_star_failed'),
      );
    }
  }

  Future<void> _contactCoach() async {
    if (_contactBusy) return;
    final lang = ref.read(localeProvider);
    String t(String k) => Translations.t(lang, k);

    setState(() => _contactBusy = true);
    HapticFeedback.selectionClick();
    try {
      final contact =
          await ref.read(coachesRepositoryProvider).contact(widget.coachId);
      final url = contact.whatsappUrl?.trim();
      if (url == null || url.isEmpty) {
        throw Exception('no whatsapp');
      }
      final uri = Uri.parse(url);
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        AppMessage.error(context, t('coaches_contact_failed'));
      }
    } catch (_) {
      if (!mounted) return;
      AppMessage.error(context, t('coaches_contact_failed'));
    } finally {
      if (mounted) setState(() => _contactBusy = false);
    }
  }

  Future<void> _openCreatePost() async {
    final created = await context.push<bool>(RoutePaths.coachCreatePost);
    if (created == true && mounted) {
      await _bootstrap();
    }
  }

  void _openPost(CoachPost post, String tab) {
    final posts = _postsByTab[tab]!;
    final index = posts.indexWhere((p) => p.id == post.id);
    context.push(
      RoutePaths.coachPostViewer,
      extra: {
        'posts': posts,
        'index': index < 0 ? 0 : index,
        'isOwner': _profile?.isOwner ?? false,
        'coachName': _profile?.name,
        'coachAvatarUrl': _profile?.avatarUrl,
      },
    ).then((deleted) {
      if (deleted == true) _bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    String t(String k) => Translations.t(lang, k);
    final profile = _profile;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || profile == null
              ? SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          t(_error ?? 'coach_social_load_failed'),
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _bootstrap,
                          child: Text(t('retry')),
                        ),
                      ],
                    ),
                  ),
                )
              : NestedScrollView(
                  headerSliverBuilder: (context, _) => [
                    SliverAppBar(
                      pinned: true,
                      backgroundColor: AppColors.background,
                      surfaceTintColor: Colors.transparent,
                      title: Text(
                        profile.name?.trim().isNotEmpty == true
                            ? profile.name!
                            : t('coaches_unnamed'),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      actions: [
                        if (!profile.isOwner)
                          IconButton(
                            tooltip: profile.isStarred
                                ? t('coach_unstar')
                                : t('coach_star'),
                            onPressed: _starBusy ? null : _toggleStar,
                            icon: Icon(
                              profile.isStarred
                                  ? Icons.star_rounded
                                  : LucideIcons.star,
                              color: profile.isStarred
                                  ? const Color(0xFFF5B301)
                                  : AppColors.textPrimary,
                            ),
                          ),
                        if (profile.isOwner)
                          IconButton(
                            onPressed: _openCreatePost,
                            icon: const Icon(LucideIcons.plus),
                          ),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: _ProfileHeader(
                        t: t,
                        profile: profile,
                        contactBusy: _contactBusy,
                        onContact: _contactCoach,
                        onDetails: () => context.push(
                          RoutePaths.coachAboutPath(profile.id),
                        ),
                        onEdit: () => context.push(RoutePaths.becomeCoach),
                        onCreate: _openCreatePost,
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _TabBarDelegate(
                        TabBar(
                          controller: _tabController,
                          indicatorColor: AppColors.primaryDark,
                          labelColor: AppColors.textPrimary,
                          unselectedLabelColor: AppColors.textSecondary,
                          dividerColor: AppColors.border,
                          tabs: [
                            Tab(
                              icon: const Icon(LucideIcons.layoutGrid, size: 20),
                              text: t('coach_tab_images'),
                            ),
                            Tab(
                              icon: const Icon(LucideIcons.clapperboard, size: 20),
                              text: t('coach_tab_videos'),
                            ),
                          ],
                        ),
                        backgroundColor: AppColors.background,
                      ),
                    ),
                  ],
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      _PostsGrid(
                        t: t,
                        posts: _postsByTab['images']!,
                        loading: _loadingTab['images']!,
                        isOwner: profile.isOwner,
                        emptyTitle: t('coach_posts_empty_images'),
                        onCreate: profile.isOwner ? _openCreatePost : null,
                        onOpen: (p) => _openPost(p, 'images'),
                        onLoadMore: () => _loadPosts('images'),
                      ),
                      _PostsGrid(
                        t: t,
                        posts: _postsByTab['videos']!,
                        loading: _loadingTab['videos']!,
                        isOwner: profile.isOwner,
                        emptyTitle: t('coach_posts_empty_videos'),
                        onCreate: profile.isOwner ? _openCreatePost : null,
                        onOpen: (p) => _openPost(p, 'videos'),
                        onLoadMore: () => _loadPosts('videos'),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String Function(String) t;
  final CoachSocialProfile profile;
  final bool contactBusy;
  final VoidCallback onContact;
  final VoidCallback onDetails;
  final VoidCallback onEdit;
  final VoidCallback onCreate;

  const _ProfileHeader({
    required this.t,
    required this.profile,
    required this.contactBusy,
    required this.onContact,
    required this.onDetails,
    required this.onEdit,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    final name = profile.name?.trim().isNotEmpty == true
        ? profile.name!
        : t('coaches_unnamed');
    final initial = name.characters.first.toUpperCase();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.primaryLight,
            backgroundImage:
                profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                    ? NetworkImage(profile.avatarUrl!)
                    : null,
            child: profile.avatarUrl == null || profile.avatarUrl!.isEmpty
                ? Text(
                    initial,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  )
                : null,
          ),
          if (profile.bio?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 14),
            Text(
              profile.bio!,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: AppColors.textPrimary,
              ),
            ),
          ],
          if (profile.city?.trim().isNotEmpty == true ||
              profile.specialties.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                if (profile.city?.trim().isNotEmpty == true)
                  _Chip(icon: LucideIcons.mapPin, label: profile.city!),
                ...profile.specialties.take(3).map(
                      (s) => _Chip(
                        icon: LucideIcons.dumbbell,
                        label: t('coach_specialty_$s'),
                      ),
                    ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          if (profile.isOwner)
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: t('coach_edit_profile'),
                    onTap: onEdit,
                    filled: false,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _ActionButton(
                    label: t('coach_create_post'),
                    onTap: onCreate,
                    filled: true,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 44,
                  width: 44,
                  child: OutlinedButton(
                    onPressed: onDetails,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Icon(LucideIcons.info, size: 18),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: contactBusy ? null : onContact,
                      icon: contactBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(LucideIcons.messageCircle, size: 18),
                      label: Text(
                        t('coaches_contact_title'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: onDetails,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      t('coach_view_details'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool filled;

  const _ActionButton({
    required this.label,
    required this.onTap,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    final child = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        label,
        maxLines: 1,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          height: 1.0,
        ),
      ),
    );
    return SizedBox(
      height: 44,
      child: filled
          ? FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: child,
            )
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: child,
            ),
    );
  }
}

class _PostsGrid extends StatelessWidget {
  final String Function(String) t;
  final List<CoachPost> posts;
  final bool loading;
  final bool isOwner;
  final String emptyTitle;
  final VoidCallback? onCreate;
  final ValueChanged<CoachPost> onOpen;
  final VoidCallback onLoadMore;

  const _PostsGrid({
    required this.t,
    required this.posts,
    required this.loading,
    required this.isOwner,
    required this.emptyTitle,
    required this.onCreate,
    required this.onOpen,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (loading && posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                emptyTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t('coach_posts_empty_body'),
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              if (isOwner && onCreate != null) ...[
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onCreate,
                  child: Text(t('coach_create_post')),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels > n.metrics.maxScrollExtent - 240) {
          onLoadMore();
        }
        return false;
      },
      child: GridView.builder(
        padding: const EdgeInsets.only(top: 2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: posts.length + (loading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= posts.length) {
            return const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          final post = posts[index];
          final cover = post.coverMedia;
          final coverUrl = cover == null
              ? null
              : cover.isImage
                  ? cover.url
                  : cover.thumbnailUrl;
          return GestureDetector(
            onTap: () => onOpen(post),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (coverUrl != null && coverUrl.isNotEmpty)
                  CachedFoodImage(
                    imageUrl: coverUrl,
                    fit: BoxFit.cover,
                  )
                else
                  Container(
                    color: AppColors.surfaceMuted,
                    child: Icon(
                      LucideIcons.video,
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (post.isVideo || post.isBeforeAfter)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Icon(
                      post.isVideo ? LucideIcons.play : LucideIcons.images,
                      size: 16,
                      color: Colors.white,
                      shadows: const [
                        Shadow(blurRadius: 6, color: Colors.black54),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _TabBarDelegate(this.tabBar, {required this.backgroundColor});

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: backgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) =>
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.tabBar != tabBar;
}
