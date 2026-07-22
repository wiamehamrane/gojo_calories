import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/di/repository_providers.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_message.dart';
import '../../../../core/widgets/cached_food_image.dart';
import '../../domain/models/coach_post.dart';

/// Instagram-style vertical feed of coach posts, opened on the tapped post.
class CoachPostViewerScreen extends ConsumerStatefulWidget {
  final List<CoachPost> posts;
  final int initialIndex;
  final bool isOwner;
  final String? coachName;
  final String? coachAvatarUrl;

  const CoachPostViewerScreen({
    super.key,
    required this.posts,
    required this.initialIndex,
    this.isOwner = false,
    this.coachName,
    this.coachAvatarUrl,
  });

  @override
  ConsumerState<CoachPostViewerScreen> createState() =>
      _CoachPostViewerScreenState();
}

class _CoachPostViewerScreenState extends ConsumerState<CoachPostViewerScreen> {
  late final List<CoachPost> _posts;
  bool _didMutate = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _posts = [...widget.posts];
  }

  Future<void> _editCaption(CoachPost post) async {
    if (!widget.isOwner || _busy) return;
    final lang = ref.read(localeProvider);
    String t(String k) => Translations.t(lang, k);
    final controller = TextEditingController(text: post.caption ?? '');

    final saved = await showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(t('coach_post_edit_caption_title')),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 5,
            minLines: 2,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: t('coach_post_caption_hint'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(t('coach_post_save_caption')),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (saved == null || !mounted) return;

    final nextCaption = saved.trim();
    final prevCaption = (post.caption ?? '').trim();
    if (nextCaption == prevCaption) return;

    setState(() => _busy = true);
    try {
      final updated = await ref
          .read(coachesRepositoryProvider)
          .updatePostCaption(post.id, nextCaption.isEmpty ? null : nextCaption);
      if (!mounted) return;
      setState(() {
        _didMutate = true;
        _busy = false;
        final i = _posts.indexWhere((p) => p.id == post.id);
        if (i >= 0) _posts[i] = updated;
      });
      AppMessage.success(context, t('coach_post_caption_updated'));
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppMessage.error(context, t('coach_post_caption_update_failed'));
    }
  }

  Future<void> _deletePost(CoachPost post) async {
    if (!widget.isOwner || _busy) return;
    final lang = ref.read(localeProvider);
    String t(String k) => Translations.t(lang, k);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('coach_post_delete_title')),
        content: Text(t('coach_post_delete_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(coachesRepositoryProvider).deletePost(post.id);
      if (!mounted) return;
      AppMessage.success(context, t('coach_post_deleted'));
      setState(() {
        _didMutate = true;
        _busy = false;
        _posts.removeWhere((p) => p.id == post.id);
      });
      if (_posts.isEmpty) {
        context.pop(true);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppMessage.error(context, t('coach_post_delete_failed'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    String t(String k) => Translations.t(lang, k);

    final initial = widget.initialIndex.clamp(
      0,
      _posts.isEmpty ? 0 : _posts.length - 1,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.pop(_didMutate);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            onPressed: () => context.pop(_didMutate),
            icon: const Icon(LucideIcons.arrowLeft),
          ),
          title: Text(
            t('coach_post_viewer_title'),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        body: _posts.isEmpty
            ? Center(
                child: Icon(LucideIcons.imageOff, color: AppColors.textSecondary),
              )
            : ScrollablePositionedList.builder(
                itemCount: _posts.length,
                initialScrollIndex: initial,
                itemBuilder: (context, index) {
                  final post = _posts[index];
                  return _FeedPostCard(
                    key: ValueKey('${post.id}-${post.caption}'),
                    t: t,
                    lang: lang,
                    post: post,
                    coachName: widget.coachName,
                    coachAvatarUrl: widget.coachAvatarUrl,
                    isOwner: widget.isOwner,
                    onEditCaption: () => _editCaption(post),
                    onDelete: () => _deletePost(post),
                  );
                },
              ),
      ),
    );
  }
}

class _FeedPostCard extends StatefulWidget {
  final String Function(String) t;
  final String lang;
  final CoachPost post;
  final String? coachName;
  final String? coachAvatarUrl;
  final bool isOwner;
  final VoidCallback onEditCaption;
  final VoidCallback onDelete;

  const _FeedPostCard({
    super.key,
    required this.t,
    required this.lang,
    required this.post,
    required this.coachName,
    required this.coachAvatarUrl,
    required this.isOwner,
    required this.onEditCaption,
    required this.onDelete,
  });

  @override
  State<_FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<_FeedPostCard> {
  late final PageController _mediaController;
  int _mediaPage = 0;

  @override
  void initState() {
    super.initState();
    _mediaController = PageController();
  }

  @override
  void dispose() {
    _mediaController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    try {
      return DateFormat.yMMMd(toIntlLocale(widget.lang)).format(date.toLocal());
    } catch (_) {
      return DateFormat.yMMMd().format(date.toLocal());
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final post = widget.post;
    final media = post.media;
    final name = widget.coachName?.trim().isNotEmpty == true
        ? widget.coachName!
        : t('coaches_unnamed');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: avatar + name (+ owner menu)
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryLight,
                backgroundImage: widget.coachAvatarUrl != null &&
                        widget.coachAvatarUrl!.isNotEmpty
                    ? NetworkImage(widget.coachAvatarUrl!)
                    : null,
                child: widget.coachAvatarUrl == null ||
                        widget.coachAvatarUrl!.isEmpty
                    ? Text(
                        name.characters.first.toUpperCase(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (widget.isOwner)
                PopupMenuButton<String>(
                  icon: Icon(
                    LucideIcons.ellipsisVertical,
                    size: 18,
                    color: AppColors.textPrimary,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') widget.onEditCaption();
                    if (value == 'delete') widget.onDelete();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.pencil,
                            size: 16,
                            color: AppColors.textPrimary,
                          ),
                          const SizedBox(width: 8),
                          Text(t('coach_post_edit_caption')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(LucideIcons.trash2,
                              size: 16, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(
                            t('delete'),
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        // Media
        AspectRatio(
          aspectRatio: 1,
          child: media.isEmpty
              ? Container(
                  color: AppColors.surfaceMuted,
                  child: Icon(
                    LucideIcons.imageOff,
                    color: AppColors.textSecondary,
                  ),
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    PageView.builder(
                      controller: _mediaController,
                      itemCount: media.length,
                      onPageChanged: (i) => setState(() => _mediaPage = i),
                      itemBuilder: (context, i) {
                        final item = media[i];
                        if (item.isVideo) {
                          return _FeedVideo(
                            url: item.url,
                            thumbnailUrl: item.thumbnailUrl,
                          );
                        }
                        return CachedFoodImage(
                          imageUrl: item.url,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                    if (post.isBeforeAfter)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _mediaPage == 0
                                ? t('coach_post_before')
                                : t('coach_post_after'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    if (media.length > 1)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${_mediaPage + 1}/${media.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        if (media.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < media.length; i++)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _mediaPage
                          ? AppColors.primaryDark
                          : AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
        // Caption + date
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (post.caption?.trim().isNotEmpty == true)
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$name ',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextSpan(
                        text: post.caption!.trim(),
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  style: const TextStyle(fontSize: 13.5, height: 1.35),
                ),
              if (post.createdAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  _formatDate(post.createdAt!),
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Divider(height: 1, thickness: 0.5, color: AppColors.border),
      ],
    );
  }
}

/// Video inside the feed: shows the thumbnail with a play button, then plays
/// inline once tapped.
class _FeedVideo extends StatefulWidget {
  final String url;
  final String? thumbnailUrl;

  const _FeedVideo({required this.url, this.thumbnailUrl});

  @override
  State<_FeedVideo> createState() => _FeedVideoState();
}

class _FeedVideoState extends State<_FeedVideo> {
  VideoPlayerController? _controller;
  bool _initializing = false;
  bool _failed = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_initializing || _controller != null) return;
    setState(() => _initializing = true);
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      controller.setLooping(true);
      setState(() {
        _controller = controller;
        _initializing = false;
      });
      controller.play();
    } catch (_) {
      controller.dispose();
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _failed = true;
      });
    }
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null) return;
    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Container(
        color: AppColors.surfaceMuted,
        child: Icon(LucideIcons.videoOff, color: AppColors.textSecondary),
      );
    }

    final controller = _controller;
    if (controller == null) {
      return GestureDetector(
        onTap: _start,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty)
              CachedFoodImage(
                imageUrl: widget.thumbnailUrl!,
                fit: BoxFit.cover,
              )
            else
              ColoredBox(color: Colors.black87),
            Center(
              child: _initializing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.play,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _togglePlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: Colors.black),
          Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio == 0
                  ? 1
                  : controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),
          if (!controller.value.isPlaying)
            Center(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.play,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
