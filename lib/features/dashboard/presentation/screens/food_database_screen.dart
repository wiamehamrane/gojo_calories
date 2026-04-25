import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/selected_date_provider.dart';
import '../../../dashboard/providers/dashboard_provider.dart';
import '../../../dashboard/providers/history_provider.dart';
import 'package:go_router/go_router.dart';

class FoodDatabaseScreen extends ConsumerStatefulWidget {
  const FoodDatabaseScreen({super.key});

  @override
  ConsumerState<FoodDatabaseScreen> createState() => _FoodDatabaseScreenState();
}

class _FoodDatabaseScreenState extends ConsumerState<FoodDatabaseScreen> {
  final _ctrl = TextEditingController();
  String _query = '';
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;
  bool _logging = false;
  DateTime? _lastTyped;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() => _query = value);
    if (value.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    final typed = _lastTyped = DateTime.now();
    Future.delayed(const Duration(milliseconds: 420), () {
      if (typed == _lastTyped && mounted) _doSearch(value.trim());
    });
  }

  Future<void> _doSearch(String q) async {
    setState(() => _searching = true);
    try {
      final res = await ApiClient.instance.get(
        'food/search',
        queryParameters: {'query': q},
      );
      final data = res.data as Map<String, dynamic>?;
      final list = (data?['results'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      if (mounted) setState(() => _results = list);
    } catch (_) {
      if (mounted) setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _logFood(Map<String, dynamic> item) async {
    if (_logging) return;
    setState(() => _logging = true);
    try {
      final name = item['name'] as String? ?? 'Food';
      final calories = (item['calories'] as num? ?? 0).toInt();
      final protein = (item['protein'] as num? ?? 0).toInt();
      final carbs = (item['carbs'] as num? ?? 0).toInt();
      final fat = (item['fat'] as num? ?? 0).toInt();
      final selectedDate = ref.read(selectedDateProvider);
      final localDateStr =
          "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

      await ApiClient.instance.post(
        'food/analyze/log',
        data: {
          'name': name,
          'name_en': name,
          'calories': calories,
          'protein': protein,
          'carbs': carbs,
          'fat': fat,
        },
        queryParameters: {'local_date': localDateStr},
      );

      ref.read(dashboardProvider.notifier).logFood(
        name: name,
        nameEn: name,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
      );
      ref.invalidate(historyProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name logged!'),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
      context.go('/home');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to log food. Please try again.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _logging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Food Library',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ─── Search bar ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F4F6),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Icon(LucideIcons.search, size: 18, color: Color(0xFF888888)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      onChanged: _onChanged,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (v) { if (v.trim().length >= 2) _doSearch(v.trim()); },
                      style: const TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.w500),
                      decoration: const InputDecoration(
                        hintText: 'Search millions of foods…',
                        hintStyle: TextStyle(color: Color(0xFFAAAAAA), fontSize: 15),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  if (_searching)
                    const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  else if (_ctrl.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _ctrl.clear();
                        setState(() { _query = ''; _results = []; });
                      },
                      child: const Icon(LucideIcons.x, size: 16, color: Color(0xFF888888)),
                    ),
                ],
              ),
            ),
          ),

          // ─── Results ───────────────────────────────────────────────────
          Expanded(
            child: _query.trim().length < 2
                ? _buildEmptyState()
                : _results.isEmpty && !_searching
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.searchX, size: 40, color: Color(0xFFCCCCCC)),
                            const SizedBox(height: 12),
                            Text(
                              'No results for "$_query"',
                              style: const TextStyle(fontSize: 15, color: Color(0xFF888888)),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        itemCount: _results.length,
                        separatorBuilder: (_, i) => const Divider(
                          height: 1, color: Color(0xFFF0F0F0), indent: 16,
                        ),
                        itemBuilder: (context, i) => _FoodResultTile(
                          item: _results[i],
                          onLog: () => _logFood(_results[i]),
                          isLogging: _logging,
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: const BoxDecoration(color: Color(0xFFF4F4F6), shape: BoxShape.circle),
            child: const Icon(LucideIcons.database, size: 32, color: Color(0xFFBBBBBB)),
          ),
          const SizedBox(height: 20),
          const Text('Search 300,000+ foods', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black)),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Type a food name above to instantly find\ncalories and macros',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF888888), height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Food Result Tile ─────────────────────────────────────────────────────────

class _FoodResultTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onLog;
  final bool isLogging;

  const _FoodResultTile({required this.item, required this.onLog, required this.isLogging});

  @override
  Widget build(BuildContext context) {
    final name = item['name'] as String? ?? 'Food';
    final brand = item['brand'] as String? ?? '';
    final calories = (item['calories'] as num? ?? 0).toInt();
    final protein = (item['protein'] as num? ?? 0).toInt();
    final carbs = (item['carbs'] as num? ?? 0).toInt();
    final fat = (item['fat'] as num? ?? 0).toInt();
    final serving = item['serving_size'] as String? ?? '100g';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: const Color(0xFFF4F4F6), borderRadius: BorderRadius.circular(12)),
            child: const Icon(LucideIcons.utensils, size: 20, color: Color(0xFFAAAAAA)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                if (brand.isNotEmpty)
                  Text(brand, style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _Chip(label: '$calories cal', color: Colors.black),
                    const SizedBox(width: 4),
                    _Chip(label: '${protein}g P', color: AppColors.protein),
                    const SizedBox(width: 4),
                    _Chip(label: '${carbs}g C', color: AppColors.carbs),
                    const SizedBox(width: 4),
                    _Chip(label: '${fat}g F', color: AppColors.fats),
                  ],
                ),
                Text('per $serving', style: const TextStyle(fontSize: 10, color: Color(0xFFCCCCCC))),
              ],
            ),
          ),
          GestureDetector(
            onTap: isLogging ? null : onLog,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: isLogging ? const Color(0xFFF0F0F0) : Colors.black,
                shape: BoxShape.circle,
              ),
              child: isLogging
                  ? const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey)))
                  : const Icon(LucideIcons.plus, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
