import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/cached_food_image.dart';
import '../../../auth/presentation/providers/auth_session_provider.dart';
import '../../domain/models/shared_meal.dart';
import '../providers/shared_meals_provider.dart';

/// Comments list for a shared meal (likes allowed, no replies).
class SharedMealCommentsSection extends ConsumerStatefulWidget {
  final String mealId;
  final String mealOwnerId;
  final bool commentsEnabled;
  final ValueChanged<bool>? onCommentsEnabledChanged;

  const SharedMealCommentsSection({
    super.key,
    required this.mealId,
    required this.mealOwnerId,
    this.commentsEnabled = true,
    this.onCommentsEnabledChanged,
  });

  @override
  ConsumerState<SharedMealCommentsSection> createState() =>
      _SharedMealCommentsSectionState();
}

class _SharedMealCommentsSectionState
    extends ConsumerState<SharedMealCommentsSection> {
  final Map<String, SharedMealComment> _localOverrides = {};
  final Set<String> _removingIds = {};

  List<SharedMealComment> _merged(List<SharedMealComment> remote) {
    return remote
        .where((c) => !_removingIds.contains(c.id))
        .map((c) => _localOverrides[c.id] ?? c)
        .toList();
  }

  String? get _currentUserId =>
      ref.watch(currentUserProvider).value?['user_id'] as String?;

  bool get _isMealOwner {
    final me = _currentUserId;
    return me != null && me == widget.mealOwnerId;
  }

  Future<void> _toggleCommentLike(SharedMealComment comment) async {
    HapticFeedback.selectionClick();
    final nextLiked = !comment.isLiked;
    final optimistic = comment.copyWith(
      isLiked: nextLiked,
      likesCount: (comment.likesCount + (nextLiked ? 1 : -1)).clamp(0, 999999),
    );
    setState(() => _localOverrides[comment.id] = optimistic);
    try {
      final data = await ref
          .read(sharedMealsRepositoryProvider)
          .toggleCommentLike(widget.mealId, comment.id);
      if (!mounted) return;
      setState(() {
        _localOverrides[comment.id] = optimistic.copyWith(
          isLiked: data['is_liked'] as bool? ?? nextLiked,
          likesCount: (data['likes_count'] as num?)?.toInt() ??
              optimistic.likesCount,
        );
      });
    } catch (_) {
      if (mounted) {
        setState(() => _localOverrides[comment.id] = comment);
      }
    }
  }

  void _openProfile(SharedMealComment comment) {
    if (!comment.profilePublic) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This profile is private.')),
      );
      return;
    }
    HapticFeedback.selectionClick();
    final router = GoRouter.of(context);
    final path =
        RoutePaths.publicProfile.replaceFirst(':id', comment.userId);
    Navigator.of(context).pop();
    router.push(path);
  }

  void _onCommentLongPress(SharedMealComment comment) {
    final me = _currentUserId;
    if (me == null) return;

    final isAuthor = me == comment.userId;
    final canDelete = isAuthor || _isMealOwner;
    if (!canDelete) return;

    HapticFeedback.mediumImpact();
    showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(sheetContext);
              _confirmDeleteComment(comment);
            },
            child: Text(isAuthor ? 'Delete comment' : 'Remove comment'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(sheetContext),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteComment(SharedMealComment comment) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Delete comment?'),
        content: const Text('This cannot be undone.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _removingIds.add(comment.id));
    final ok = await ref
        .read(sharedMealsProvider.notifier)
        .deleteComment(widget.mealId, comment.id);
    if (!mounted) return;
    if (!ok) {
      setState(() => _removingIds.remove(comment.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete comment.')),
      );
    } else {
      setState(() {
        _removingIds.remove(comment.id);
        _localOverrides.remove(comment.id);
      });
    }
  }

  void _showOwnerCommentsMenu() {
    if (!_isMealOwner) return;
    HapticFeedback.selectionClick();
    final enabled = widget.commentsEnabled;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: const Text('Comment settings'),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: enabled,
            onPressed: () {
              Navigator.pop(sheetContext);
              _setCommentsEnabled(!enabled);
            },
            child: Text(enabled ? 'Turn off comments' : 'Turn on comments'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(sheetContext),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _setCommentsEnabled(bool enabled) async {
    final ok = await ref
        .read(sharedMealsProvider.notifier)
        .setCommentsEnabled(widget.mealId, enabled);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update comment settings.')),
      );
      return;
    }
    widget.onCommentsEnabledChanged?.call(enabled);
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(mealCommentsProvider(widget.mealId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Comments',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (_isMealOwner)
              GestureDetector(
                onTap: _showOwnerCommentsMenu,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Icon(
                    LucideIcons.settings2,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
        if (!widget.commentsEnabled) ...[
          const SizedBox(height: 8),
          Text(
            _isMealOwner
                ? 'Comments are turned off. Tap the settings icon to turn them back on.'
                : 'Comments are turned off for this meal.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 12),
        commentsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CupertinoActivityIndicator(radius: 10)),
          ),
          error: (e, _) => Text(
            AppErrorHandler.message(e),
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          data: (remote) {
            final comments = _merged(remote);
            if (comments.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  widget.commentsEnabled
                      ? 'No comments yet. Be the first!'
                      : 'No comments.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }
            return Column(
              children: [
                for (final comment in comments)
                  _CommentTile(
                    comment: comment,
                    canModerate: _currentUserId != null &&
                        (_currentUserId == comment.userId || _isMealOwner),
                    onLike: () => _toggleCommentLike(comment),
                    onOpenProfile: () => _openProfile(comment),
                    onLongPress: () => _onCommentLongPress(comment),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Sticky comment composer pinned above the keyboard / sheet bottom.
class SharedMealCommentComposer extends ConsumerStatefulWidget {
  final String mealId;
  final FocusNode? focusNode;
  final bool enabled;

  const SharedMealCommentComposer({
    super.key,
    required this.mealId,
    this.focusNode,
    this.enabled = true,
  });

  @override
  ConsumerState<SharedMealCommentComposer> createState() =>
      _SharedMealCommentComposerState();
}

class _SharedMealCommentComposerState
    extends ConsumerState<SharedMealCommentComposer> {
  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!widget.enabled) return;
    final text = _controller.text.trim();
    if (text.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    HapticFeedback.lightImpact();
    try {
      await ref
          .read(sharedMealsRepositoryProvider)
          .addComment(widget.mealId, text);
      _controller.clear();
      FocusManager.instance.primaryFocus?.unfocus();
      ref.read(sharedMealsProvider.notifier).bumpCommentsCount(widget.mealId, 1);
      ref.invalidate(mealCommentsProvider(widget.mealId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppErrorHandler.message(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return Material(
        color: AppColors.surface,
        elevation: 8,
        shadowColor: Colors.black26,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Text(
              'Comments are turned off',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: AppColors.surface,
      elevation: 8,
      shadowColor: Colors.black26,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: widget.focusNode,
                  maxLines: 3,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submit(),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Add a comment…',
                    hintStyle: TextStyle(
                      color: AppColors.textPlaceholder,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceMuted,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: _submitting ? null : _submit,
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 46,
                    height: 46,
                    child: _submitting
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            LucideIcons.send,
                            size: 18,
                            color: Colors.white,
                          ),
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

class _CommentAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;

  const _CommentAvatar({required this.name, required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = avatarUrl != null && avatarUrl!.isNotEmpty;
    if (!hasPhoto) return _initials();

    return CachedFoodImage(
      imageUrl: avatarUrl,
      width: 32,
      height: 32,
      fit: BoxFit.cover,
      memCacheWidth: 96,
      placeholder: _initials(),
      errorWidget: _initials(),
    );
  }

  Widget _initials() {
    return SizedBox(
      width: 32,
      height: 32,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final SharedMealComment comment;
  final bool canModerate;
  final VoidCallback onLike;
  final VoidCallback onOpenProfile;
  final VoidCallback onLongPress;

  const _CommentTile({
    required this.comment,
    required this.canModerate,
    required this.onLike,
    required this.onOpenProfile,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: canModerate ? onLongPress : null,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onOpenProfile,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryLight,
                child: ClipOval(
                  child: _CommentAvatar(
                    name: comment.authorName,
                    avatarUrl: comment.authorAvatarUrl,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: onOpenProfile,
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            comment.authorName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (comment.profilePublic) ...[
                          const SizedBox(width: 4),
                          Icon(
                            LucideIcons.chevronRight,
                            size: 14,
                            color: AppColors.inactive,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comment.body,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onLike,
              child: Column(
                children: [
                  Icon(
                    comment.isLiked ? Icons.favorite : LucideIcons.heart,
                    size: 16,
                    color: comment.isLiked
                        ? const Color(0xFFE11D48)
                        : AppColors.inactive,
                  ),
                  if (comment.likesCount > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${comment.likesCount}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: comment.isLiked
                            ? const Color(0xFFE11D48)
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
