import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/di/repository_providers.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/widgets/cached_food_image.dart';
import 'share_meal_screen.dart';

/// Lazy-loaded list of the user's logged meals to share with the community.
class ShareExistingMealScreen extends ConsumerStatefulWidget {
  const ShareExistingMealScreen({super.key});

  @override
  ConsumerState<ShareExistingMealScreen> createState() =>
      _ShareExistingMealScreenState();
}

class _ShareExistingMealScreenState
    extends ConsumerState<ShareExistingMealScreen> {
  static const _pageSize = 20;

  final _scrollController = ScrollController();
  final List<Map<String, dynamic>> _meals = [];

  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _loading) return;
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 240) {
      _load();
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _hasMore = true;
        _meals.clear();
      });
    } else {
      if (!_hasMore || _loadingMore) return;
      setState(() => _loadingMore = true);
    }

    try {
      final skip = reset ? 0 : _meals.length;
      final page = await ref.read(foodRepositoryProvider).getHistoryPage(
            skip: skip,
            limit: _pageSize,
          );
      final mapped = page
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (!mounted) return;
      setState(() {
        _meals.addAll(mapped);
        _hasMore = mapped.length >= _pageSize;
        _loading = false;
        _loadingMore = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = AppErrorHandler.message(e);
      });
    }
  }

  List<String> _ingredientLines(Map<String, dynamic> log) {
    final raw = log['ingredients'];
    if (raw is! List || raw.isEmpty) return const [];
    return raw.map((e) {
      if (e is String) return e.trim();
      if (e is Map) {
        final name = (e['name'] ?? '').toString().trim();
        final amount = (e['amount'] ?? '').toString().trim();
        if (name.isEmpty) return '';
        return amount.isEmpty ? name : '$name · $amount';
      }
      return e.toString().trim();
    }).where((s) => s.isNotEmpty).toList();
  }

  void _selectMeal(Map<String, dynamic> log) {
    HapticFeedback.selectionClick();
    final name = (log['meal_name'] ?? log['name_en'] ?? 'Meal') as String;
    context.push(
      RoutePaths.shareMeal,
      extra: ShareMealPrefill(
        name: name,
        calories: (log['calories'] as num?)?.toInt() ?? 0,
        protein: (log['protein'] as num?)?.toInt() ?? 0,
        carbs: (log['carbs'] as num?)?.toInt() ?? 0,
        fat: (log['fat'] as num?)?.toInt() ?? 0,
        ingredients: _ingredientLines(log),
        imageUrl: log['image_url'] as String?,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.chevronLeft,
            size: 24,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            HapticFeedback.selectionClick();
            context.pop();
          },
        ),
        title: const Text(
          'Your meals',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _meals.isEmpty) {
      return const Center(child: CupertinoActivityIndicator(radius: 14));
    }
    if (_error != null && _meals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.wifiOff, size: 36, color: AppColors.inactive),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _load(reset: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_meals.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.utensils, size: 36, color: AppColors.inactive),
              SizedBox(height: 12),
              Text(
                'No logged meals yet',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Log a meal first, then come back to share it with the community.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _load(reset: true),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          8,
          AppSpacing.screenPadding,
          40,
        ),
        itemCount: _meals.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _meals.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CupertinoActivityIndicator(radius: 11)),
            );
          }
          return _MealTile(
            log: _meals[index],
            onTap: () => _selectMeal(_meals[index]),
          );
        },
      ),
    );
  }
}

class _MealTile extends StatelessWidget {
  final Map<String, dynamic> log;
  final VoidCallback onTap;

  const _MealTile({required this.log, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = (log['meal_name'] ?? log['name_en'] ?? 'Meal') as String;
    final imageUrl = log['image_url'] as String?;
    final calories = (log['calories'] as num?)?.toInt() ?? 0;
    final protein = (log['protein'] as num?)?.toInt() ?? 0;
    final carbs = (log['carbs'] as num?)?.toInt() ?? 0;
    final fat = (log['fat'] as num?)?.toInt() ?? 0;
    DateTime? createdAt;
    final rawDate = log['created_at'] as String?;
    if (rawDate != null) createdAt = DateTime.tryParse(rawDate)?.toLocal();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 72,
                height: 72,
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? CachedFoodImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        memCacheWidth: 216,
                        placeholder:
                            const ColoredBox(color: Color(0xFFF2F2F7)),
                        errorWidget: _fallback(),
                      )
                    : _fallback(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      DateFormat.yMMMd().add_jm().format(createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    '$calories kcal · ${protein}g P · ${carbs}g C · ${fat}g F',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: AppColors.inactive,
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: AppColors.primaryLight,
      child: const Center(
        child: Icon(LucideIcons.utensils, size: 24, color: AppColors.primaryDark),
      ),
    );
  }
}
