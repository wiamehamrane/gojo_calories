import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cached_food_image.dart';
import '../../../food/domain/meal_share_data.dart';
import '../../../food/presentation/utils/meal_share_helper.dart';
import '../../domain/models/shared_meal.dart';
import '../providers/shared_meals_provider.dart';
import 'shared_meal_comments_section.dart';

const _starActive = Color(0xFFF5A623);
const _likeActive = Color(0xFFE11D48);

/// Card used in the horizontal "Shared meals" row on the Events page.
class SharedMealCard extends ConsumerStatefulWidget {
  final SharedMeal meal;
  final double? width;

  const SharedMealCard({super.key, required this.meal, this.width});

  @override
  ConsumerState<SharedMealCard> createState() => _SharedMealCardState();
}

class _SharedMealCardState extends ConsumerState<SharedMealCard> {
  bool _pressed = false;

  SharedMeal _liveMeal() {
    final meals = ref.watch(sharedMealsProvider).value;
    if (meals != null) {
      for (final m in meals) {
        if (m.id == widget.meal.id) return m;
      }
    }
    return widget.meal;
  }

  void _openDetails(SharedMeal liveMeal) {
    HapticFeedback.selectionClick();
    showSharedMealSheet(context, liveMeal);
  }

  @override
  Widget build(BuildContext context) {
    final cardWidth = widget.width ?? MediaQuery.sizeOf(context).width - 32;
    final liveMeal = _liveMeal();

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: () => _openDetails(liveMeal),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: Container(
          width: cardWidth,
          height: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SizedBox(
                      width: double.infinity,
                      child: liveMeal.imageUrl != null &&
                              liveMeal.imageUrl!.isNotEmpty
                          ? CachedFoodImage(
                              imageUrl: liveMeal.imageUrl,
                              fit: BoxFit.cover,
                              memCacheWidth: 900,
                              placeholder:
                                  const ColoredBox(color: Color(0xFFF2F2F7)),
                              errorWidget: _imageFallback(),
                            )
                          : _imageFallback(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          liveMeal.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'by ${liveMeal.authorName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _MacroChip(label: '${liveMeal.calories} kcal'),
                            _MacroChip(
                              label: '${liveMeal.protein}g P',
                              color: AppColors.protein,
                            ),
                            _MacroChip(
                              label: '${liveMeal.carbs}g C',
                              color: AppColors.carbs,
                            ),
                            _MacroChip(
                              label: '${liveMeal.fat}g F',
                              color: AppColors.fats,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 10,
                right: 10,
                child: _StarButton(
                  isStarred: liveMeal.isStarred,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref
                        .read(sharedMealsProvider.notifier)
                        .toggleStar(liveMeal.id);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: AppColors.primaryLight,
      child: const Center(
        child: Icon(LucideIcons.utensils, size: 30, color: AppColors.primaryDark),
      ),
    );
  }
}

class _StarButton extends StatelessWidget {
  final bool isStarred;
  final VoidCallback onTap;

  const _StarButton({required this.isStarred, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          // Absorb the tap so the parent card doesn't open the sheet.
          onTap();
        },
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            isStarred ? Icons.star_rounded : LucideIcons.star,
            size: 20,
            color: isStarred ? _starActive : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final Color? color;

  const _MacroChip({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final chipColor = color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: chipColor?.withValues(alpha: 0.12) ?? AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: chipColor ?? AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Full meal details: photo, macros, ingredients, and how to cook it.
void showSharedMealSheet(BuildContext context, SharedMeal meal) {
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    sheetAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 420),
      reverseDuration: Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ),
    builder: (sheetContext) {
      final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: _SharedMealSheet(initialMeal: meal),
      );
    },
  );
}

class _SharedMealSheet extends ConsumerStatefulWidget {
  final SharedMeal initialMeal;

  const _SharedMealSheet({required this.initialMeal});

  @override
  ConsumerState<_SharedMealSheet> createState() => _SharedMealSheetState();
}

class _SharedMealSheetState extends ConsumerState<_SharedMealSheet> {
  late SharedMeal _meal = widget.initialMeal;
  bool _toggling = false;
  bool _liking = false;
  bool _entranceDone = false;
  final _commentsKey = GlobalKey();
  final _composerKey = GlobalKey();
  final _commentFocus = FocusNode();
  final _sheetController = DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 750), () {
      if (mounted) setState(() => _entranceDone = true);
    });
    // Pull fresh like/comment counts so the sheet isn't stuck on a stale feed snapshot.
    Future<void>.microtask(_refreshMealCounts);
  }

  Future<void> _refreshMealCounts() async {
    await ref.read(sharedMealsProvider.notifier).fetchMeals();
    if (!mounted || _liking) return;
    final fromFeed = _findMeal(
      ref.read(sharedMealsProvider).value,
      widget.initialMeal.id,
    );
    if (fromFeed != null) {
      setState(() => _meal = fromFeed);
      return;
    }
    final fromStarred = _findMeal(
      ref.read(starredSharedMealsProvider).value,
      widget.initialMeal.id,
    );
    if (fromStarred != null) {
      setState(() => _meal = fromStarred);
    }
  }

  SharedMeal? _findMeal(List<SharedMeal>? meals, String id) {
    if (meals == null) return null;
    for (final m in meals) {
      if (m.id == id) return m;
    }
    return null;
  }

  @override
  void dispose() {
    _commentFocus.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _scrollToComments() async {
    HapticFeedback.selectionClick();

    if (_sheetController.isAttached) {
      await _sheetController.animateTo(
        0.95,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }

    final commentsContext = _commentsKey.currentContext;
    if (commentsContext != null && mounted) {
      await Scrollable.ensureVisible(
        commentsContext,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        alignment: 0.0,
      );
    }

    if (!mounted || !_meal.commentsEnabled) return;
    _commentFocus.requestFocus();
  }

  Widget _enter(
    Widget child, {
    required int delayMs,
    Offset slideBegin = const Offset(0, 0.14),
    Offset? scaleBegin,
    bool slideX = false,
  }) {
    if (_entranceDone) return child;
    var animated = child.animate().fadeIn(
          delay: delayMs.ms,
          duration: 380.ms,
          curve: Curves.easeOut,
        );
    if (slideX) {
      animated = animated.slideX(
        begin: slideBegin.dx,
        end: 0,
        delay: delayMs.ms,
        duration: 400.ms,
        curve: Curves.easeOutCubic,
      );
    } else {
      animated = animated.slideY(
        begin: slideBegin.dy,
        end: 0,
        delay: delayMs.ms,
        duration: 400.ms,
        curve: Curves.easeOutCubic,
      );
    }
    if (scaleBegin != null) {
      animated = animated.scale(
        begin: scaleBegin,
        end: const Offset(1, 1),
        delay: delayMs.ms,
        duration: 420.ms,
        curve: Curves.easeOutBack,
      );
    }
    return animated;
  }

  Future<void> _toggleStar() async {
    if (_toggling) return;
    _toggling = true;
    final previous = _meal;
    setState(() => _meal = _meal.copyWith(isStarred: !_meal.isStarred));
    HapticFeedback.lightImpact();
    final ok =
        await ref.read(sharedMealsProvider.notifier).toggleStar(previous.id);
    if (!mounted) {
      _toggling = false;
      return;
    }
    if (!ok) {
      setState(() => _meal = previous);
    } else {
      final fromFeed = ref.read(sharedMealsProvider).value;
      if (fromFeed != null) {
        for (final m in fromFeed) {
          if (m.id == previous.id) {
            setState(() => _meal = m);
            break;
          }
        }
      }
    }
    _toggling = false;
  }

  Future<void> _toggleLike() async {
    if (_liking) return;
    _liking = true;
    HapticFeedback.lightImpact();
    final previous = _meal;
    final nextLiked = !_meal.isLiked;
    setState(() {
      _meal = _meal.copyWith(
        isLiked: nextLiked,
        likesCount: (_meal.likesCount + (nextLiked ? 1 : -1)).clamp(0, 999999),
      );
    });
    final result =
        await ref.read(sharedMealsProvider.notifier).toggleLike(previous.id);
    if (!mounted) {
      _liking = false;
      return;
    }
    if (result == null) {
      setState(() => _meal = previous);
    } else {
      setState(() {
        _meal = _meal.copyWith(
          isLiked: result.isLiked,
          likesCount: result.likesCount,
        );
      });
    }
    _liking = false;
  }

  void _openAuthorProfile() {
    if (!_meal.authorProfilePublic || _meal.userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This profile is private.')),
      );
      return;
    }
    HapticFeedback.selectionClick();
    final router = GoRouter.of(context);
    final path =
        RoutePaths.publicProfile.replaceFirst(':id', _meal.userId);
    Navigator.of(context).pop();
    router.push(path);
  }

  @override
  Widget build(BuildContext context) {
    final meal = _meal;
    final lang = ref.watch(localeProvider);
    String t(String k) => Translations.t(lang, k);

    final imageBlock = _enter(
      Stack(
        children: [
          if (meal.imageUrl != null && meal.imageUrl!.isNotEmpty)
            SizedBox(
              height: 240,
              width: double.infinity,
              child: CachedFoodImage(
                imageUrl: meal.imageUrl,
                fit: BoxFit.cover,
                memCacheWidth: 1080,
                placeholder: const ColoredBox(color: Color(0xFFF2F2F7)),
                errorWidget: Container(
                  color: AppColors.primaryLight,
                  child: const Center(
                    child: Icon(LucideIcons.utensils,
                        size: 42, color: AppColors.primaryDark),
                  ),
                ),
              ),
            )
          else
            Container(
              height: 160,
              color: AppColors.primaryLight,
              child: const Center(
                child: Icon(LucideIcons.utensils,
                    size: 42, color: AppColors.primaryDark),
              ),
            ),
          Positioned(
            top: 12,
            right: 12,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StarButton(
                  isStarred: meal.isStarred,
                  onTap: _toggleStar,
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      shareMealAsImage(
                        context,
                        MealShareData(
                          name: meal.name,
                          imageUrl: meal.imageUrl,
                          calories: meal.calories,
                          protein: meal.protein,
                          carbs: meal.carbs,
                          fat: meal.fat,
                          ingredients: meal.ingredients,
                          authorName: meal.authorName,
                        ),
                      );
                    },
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                        LucideIcons.share,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      delayMs: 0,
      slideBegin: Offset.zero,
      scaleBegin: const Offset(1.05, 1.05),
    );

    final titleBlock = _enter(
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              meal.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: _toggleStar,
            icon: Icon(
              meal.isStarred ? Icons.star_rounded : LucideIcons.star,
              size: 16,
              color: meal.isStarred ? _starActive : AppColors.primaryDark,
            ),
            label: Text(meal.isStarred ? t('starred') : t('star')),
            style: TextButton.styleFrom(
              foregroundColor:
                  meal.isStarred ? _starActive : AppColors.primaryDark,
              backgroundColor: meal.isStarred
                  ? _starActive.withValues(alpha: 0.12)
                  : AppColors.primaryLight,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
      delayMs: 80,
    );

    final authorBlock = _enter(
      GestureDetector(
        onTap: _openAuthorProfile,
        child: Text(
          'Shared by ${meal.authorName}',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ),
      delayMs: 140,
    );

    final engagementBlock = _enter(
      Row(
        children: [
          _EngagementChip(
            icon: meal.isLiked ? Icons.favorite : LucideIcons.heart,
            label: meal.likesCount > 0 ? '${meal.likesCount}' : 'Like',
            active: meal.isLiked,
            activeColor: _likeActive,
            onTap: _toggleLike,
          ),
          const SizedBox(width: 10),
          _EngagementChip(
            icon: LucideIcons.messageCircle,
            label: meal.commentsCount > 0
                ? '${meal.commentsCount}'
                : 'Comment',
            active: false,
            onTap: _scrollToComments,
          ),
        ],
      ),
      delayMs: 160,
    );

    final macrosBlock = Row(
      children: [
        for (var i = 0; i < 4; i++)
          Expanded(
            child: _enter(
              _MacroStat(
                value: [
                  '${meal.calories}',
                  '${meal.protein}g',
                  '${meal.carbs}g',
                  '${meal.fat}g',
                ][i],
                label: const ['kcal', 'Protein', 'Carbs', 'Fats'][i],
              ),
              delayMs: 180 + i * 55,
              scaleBegin: const Offset(0.92, 0.92),
            ),
          ),
      ],
    );

    final detailsChildren = <Widget>[
      titleBlock,
      const SizedBox(height: 4),
      authorBlock,
      const SizedBox(height: 14),
      engagementBlock,
      const SizedBox(height: 18),
      macrosBlock,
    ];

    if (meal.ingredients.isNotEmpty) {
      detailsChildren.addAll([
        const SizedBox(height: 24),
        _enter(
          const Text(
            'Ingredients',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          delayMs: 360,
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < meal.ingredients.length; i++)
          _enter(
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: Icon(LucideIcons.check,
                        size: 14, color: AppColors.primaryDark),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      meal.ingredients[i],
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            delayMs: 400 + i * 40,
            slideBegin: const Offset(0.08, 0),
            slideX: true,
          ),
      ]);
    }

    if (meal.instructions != null && meal.instructions!.trim().isNotEmpty) {
      detailsChildren.addAll([
        const SizedBox(height: 20),
        _enter(
          const Text(
            'How to cook it',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          delayMs: 480,
        ),
        const SizedBox(height: 10),
        _enter(
          Text(
            meal.instructions!.trim(),
            style: const TextStyle(
              fontSize: 14,
              height: 1.55,
              color: AppColors.textPrimary,
            ),
          ),
          delayMs: 540,
        ),
      ]);
    }

    detailsChildren.addAll([
      const SizedBox(height: 28),
      KeyedSubtree(
        key: _commentsKey,
        child: SharedMealCommentsSection(
          mealId: meal.id,
          mealOwnerId: meal.userId,
          commentsEnabled: meal.commentsEnabled,
          onCommentsEnabledChanged: (enabled) {
            setState(() => _meal = _meal.copyWith(commentsEnabled: enabled));
          },
        ),
      ),
      // Extra space so last comments aren't hidden behind sticky composer.
      const SizedBox(height: 16),
    ]);

    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        final sheet = Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  controller: scrollController,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.zero,
                  children: [
                    imageBlock,
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: detailsChildren,
                      ),
                    ),
                  ],
                ),
              ),
              KeyedSubtree(
                key: _composerKey,
                child: SharedMealCommentComposer(
                  mealId: meal.id,
                  focusNode: _commentFocus,
                  enabled: meal.commentsEnabled,
                ),
              ),
            ],
          ),
        );
        if (_entranceDone) return sheet;
        return sheet
            .animate()
            .slideY(
              begin: 0.06,
              end: 0,
              duration: 420.ms,
              curve: Curves.easeOutCubic,
            )
            .fadeIn(duration: 280.ms);
      },
    );
  }
}

class _EngagementChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _EngagementChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.activeColor = AppColors.primaryDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : AppColors.textSecondary;
    return Material(
      color: active
          ? activeColor.withValues(alpha: 0.12)
          : AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MacroStat extends StatelessWidget {
  final String value;
  final String label;

  const _MacroStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
