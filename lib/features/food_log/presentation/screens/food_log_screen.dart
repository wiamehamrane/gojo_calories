import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/localization/translations.dart';
import '../../../dashboard/providers/dashboard_provider.dart';
import 'scan_food_screen.dart';
import 'food_detail_screen.dart';

class FoodLogScreen extends ConsumerStatefulWidget {
  const FoodLogScreen({super.key});

  @override
  ConsumerState<FoodLogScreen> createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends ConsumerState<FoodLogScreen> {
  int _selectedTab = 0;
  List<String> _tabs(String lang) => [
    Translations.t(lang, 'tab_all'),
    Translations.t(lang, 'tab_my_meals'),
    Translations.t(lang, 'tab_my_foods'),
    Translations.t(lang, 'tab_saved_scans'),
  ];
  final _searchController = TextEditingController();
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];

  Future<void> _submitSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      final res = await ApiClient.instance.get(
        'food/search',
        queryParameters: {'query': query},
      );

      if (res.statusCode == 200 && res.data != null) {
        if (!mounted) return;
        setState(() {
          _searchResults = List<Map<String, dynamic>>.from(res.data['results'] ?? []);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error searching food library.')));
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _logFoodItem(Map<String, dynamic> data) async {
    final calories = int.tryParse(data['calories']?.toString() ?? '0') ?? 0;
    final protein = int.tryParse(data['protein']?.toString() ?? '0') ?? 0;
    final carbs = int.tryParse(data['carbs']?.toString() ?? '0') ?? 0;
    final fat = int.tryParse(data['fat']?.toString() ?? '0') ?? 0;
    final name = data['name']?.toString() ?? 'Food Item';

    try {
      await ApiClient.instance.post(
        'food/analyze/log',
        data: {
          'name': name,
          'image_url': data['image_url'],
          'calories': calories,
          'protein': protein,
          'carbs': carbs,
          'fat': fat,
        },
      );
    } catch (_) {}

    ref.read(dashboardProvider.notifier).logFood(
          calories: calories,
          protein: protein,
          carbs: carbs,
          fat: fat,
          name: name,
          imageUrl: data['image_url'],
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged $name!'),
          backgroundColor: AppColors.primaryDark,
        ),
      );
      _searchController.clear();
      setState(() => _searchResults = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          Translations.t(lang, 'log_food'),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  child: Row(
                    children: List.generate(_tabs(lang).length, (i) {
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
                                _tabs(lang)[i],
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: active
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: active
                                      ? AppColors.textPrimary
                                      : AppColors.inactive,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height: 2,
                                width: 24, // simplified underline length
                                color: active
                                    ? AppColors.primary
                                    : Colors.transparent,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 12),

                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.textPrimary, width: 2),
                    borderRadius: BorderRadius.circular(AppRadius.input),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _submitSearch(),
                    decoration: InputDecoration(
                      hintText: Translations.t(lang, 'describe_what_ate'),
                      hintStyle: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textPlaceholder,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  child: Text(
                    "Suggestions",
                    style: AppTextStyles.sectionHeader,
                  ),
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: _isSearching
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.screenPadding,
                          ),
                          itemCount: _searchResults.isEmpty ? 1 : _searchResults.length,
                          itemBuilder: (context, index) {
                            if (_searchResults.isEmpty) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: Text(
                                    'Search foods using the bar above.',
                                    style: TextStyle(color: AppColors.textPlaceholder),
                                  ),
                                ),
                              );
                            }
                            final item = _searchResults[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: _SuggestionRow(
                                name: item['name']?.toString() ?? 'Food',
                                cal: item['calories']?.toString() ?? '0',
                                unit: item['serving_size']?.toString() ?? '100 g',
                                imageUrl: item['image_url']?.toString(),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FoodDetailScreen(log: item),
                                    ),
                                  );
                                },
                                onAdd: () => _logFoodItem(item),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 80), // Padding for bottom actions
              ],
            ),
          ),

          // Fixed bottom action bar
          Positioned(
            bottom: safeBottom > 0 ? safeBottom : 16,
            left: 0,
            right: 0,
            child: Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _PillOutlineButton(
                      icon: LucideIcons.scanLine,
                      label: Translations.t(lang, 'scan'),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const ScanFoodScreen(initialMode: 'Scan Food'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PillOutlineButton(
                      icon: LucideIcons.barcode,
                      label: Translations.t(lang, 'barcode'),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const ScanFoodScreen(initialMode: 'Barcode'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PillOutlineButton(
                      icon: LucideIcons.image,
                      label: Translations.t(lang, 'gallery'),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const ScanFoodScreen(initialMode: 'Gallery'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  final String name;
  final String cal;
  final String unit;
  final String? imageUrl;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const _SuggestionRow({
    required this.name,
    required this.cal,
    required this.unit,
    this.imageUrl,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 48,
                height: 48,
                child: _buildImage(imageUrl),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.bodyBold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.flame,
                        size: 14,
                        color: AppColors.fire,
                      ),
                      const SizedBox(width: 4),
                      Text("$cal kcal · $unit", style: AppTextStyles.bodyRegular.copyWith(fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            // Add button
            GestureDetector(
              onTap: onAdd,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.plus,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        color: AppColors.inactive.withValues(alpha: 0.1),
        child: const Icon(LucideIcons.image, size: 20, color: AppColors.inactive),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.inactive.withValues(alpha: 0.1),
        child: const Icon(LucideIcons.image, size: 20, color: AppColors.inactive),
      ),
    );
  }
}

class _PillOutlineButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _PillOutlineButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.surface,
        elevation: 0,
        side: const BorderSide(color: AppColors.textPrimary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        minimumSize: const Size(double.infinity, 54),
        padding: EdgeInsets.zero,
      ),
      onPressed: onPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: AppColors.textPrimary),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
