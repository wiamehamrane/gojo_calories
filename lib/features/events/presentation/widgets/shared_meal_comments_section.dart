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
import '../../domain/models/shared_meal.dart';
import '../providers/shared_meals_provider.dart';

/// Comments list for a shared meal (likes allowed, no replies).
class SharedMealCommentsSection extends ConsumerStatefulWidget {
  final String mealId;

  const SharedMealCommentsSection({
    super.key,
    required this.mealId,
  });

  @override
  ConsumerState<SharedMealCommentsSection> createState() =>
      _SharedMealCommentsSectionState();
}

class _SharedMealCommentsSectionState
    extends ConsumerState<SharedMealCommentsSection> {
  final Map<String, SharedMealComment> _localOverrides = {};

  List<SharedMealComment> _merged(List<SharedMealComment> remote) {
    return remote.map((c) => _localOverrides[c.id] ?? c).toList();
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

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(mealCommentsProvider(widget.mealId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comments',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        commentsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CupertinoActivityIndicator(radius: 10)),
          ),
          error: (e, _) => Text(
            AppErrorHandler.message(e),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          data: (remote) {
            final comments = _merged(remote);
            if (comments.isEmpty) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'No comments yet. Be the first!',
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
                    onLike: () => _toggleCommentLike(comment),
                    onOpenProfile: () => _openProfile(comment),
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

  const SharedMealCommentComposer({
    super.key,
    required this.mealId,
    this.focusNode,
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
    return Material(
      color: Colors.white,
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
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Add a comment…',
                    hintStyle: const TextStyle(
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
          style: const TextStyle(
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
  final VoidCallback onLike;
  final VoidCallback onOpenProfile;

  const _CommentTile({
    required this.comment,
    required this.onLike,
    required this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (comment.profilePublic) ...[
                        const SizedBox(width: 4),
                        const Icon(
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
                  style: const TextStyle(
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
    );
  }
}
