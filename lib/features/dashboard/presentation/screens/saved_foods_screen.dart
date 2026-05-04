import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/saved_foods_provider.dart';
import '../../../../core/network/api_client.dart';
import '../../../food_log/presentation/screens/food_detail_screen.dart';

class SavedFoodsScreen extends ConsumerWidget {
  const SavedFoodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedFoodsAsync = ref.watch(savedFoodsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Saved Foods",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.rotateCcw, size: 20),
            onPressed: () => ref.invalidate(savedFoodsProvider),
          ),
        ],
      ),
      body: savedFoodsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(child: Text("Error: $err")),
        data: (foods) {
          if (foods.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: foods.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final food = foods[index] as Map<String, dynamic>;
              return _FoodItemTile(food: food);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.bookmark,
              size: 48,
              color: AppColors.inactive,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "No saved foods",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Foods you frequently log or save will automatically appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodItemTile extends StatelessWidget {
  final Map<String, dynamic> food;
  const _FoodItemTile({required this.food});

  @override
  Widget build(BuildContext context) {
    final imageUrl = food['image_url'] as String?;
    final name = food['name'] ?? 'Food';
    final cal = food['calories'] ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FoodDetailScreen(log: food),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 50,
                height: 50,
                child: _buildImage(imageUrl),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    '$cal kcal',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.inactive),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String? url) {
    if (url == null || url.isEmpty) {
      return Container(color: AppColors.surface, child: const Icon(LucideIcons.image, size: 20));
    }
    if (url.startsWith('/uploads/')) {
      final fullUrl = '${ApiClient.instance.options.baseUrl.replaceAll('/api/', '')}$url';
      return Image.network(fullUrl, fit: BoxFit.cover);
    }
    return Image.network(url, fit: BoxFit.cover);
  }
}
