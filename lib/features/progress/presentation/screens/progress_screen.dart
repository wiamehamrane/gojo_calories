import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_shadows.dart';
import '../providers/progress_provider.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  int _selectedTab = 0;
  final List<String> _tabs = ["90 Days", "6 Months", "1 Year", "All time"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: const Text('Progress', style: AppTextStyles.screenTitle),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(progressProvider.notifier).refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildWeightCard(context)),
                  const SizedBox(width: AppSpacing.cardGap),
                  Expanded(child: _buildStreakCard(context)),
                ],
              ),
              const SizedBox(height: 24),
              _buildChartCard(context),
              const SizedBox(height: 100), // padding for Nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeightCard(BuildContext context) {
    final asyncData = ref.watch(progressProvider);
    double currentWeight = 0.0;
    
    if (asyncData.hasValue && asyncData.value!.isNotEmpty) {
      currentWeight = asyncData.value!.last.weight;
    }
    
    final double goalWeight = 75.0; // fallback hardcode for now
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.cardShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text("My Weight", style: AppTextStyles.cardHeading),
          const SizedBox(height: 6),
          Text("${currentWeight.toStringAsFixed(1)} kg", style: AppTextStyles.cardValue),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: currentWeight > 0 ? (currentWeight / goalWeight).clamp(0.0, 1.0) : 0,
              backgroundColor: AppColors.ringTrack,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 3,
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Goal  ", style: TextStyle(fontSize: 13, color: AppColors.inactive)),
              Text("Target", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 10),
          const Text("Next weigh-in: 5d", style: TextStyle(fontSize: 12, color: AppColors.textPlaceholder)),
        ],
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context) {
    final List<String> days = ["S","M","T","W","T","F","S"];
    final List<bool> completedDays = [true, true, false, false, false, false, false];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.cardShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              SvgPicture.asset('assets/icons/flame_gradient.svg', width: 48, height: 52),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text("12", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.fire)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text("Day streak", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.fire)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (i) {
              return Column(
                children: [
                  Text(days[i], style: const TextStyle(fontSize: 11, color: AppColors.inactive)),
                  const SizedBox(height: 4),
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: completedDays[i] ? AppColors.fireLight : AppColors.streakInactive,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(BuildContext context) {
    final asyncData = ref.watch(progressProvider);
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.cardShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Time range tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final bool selected = i == _selectedTab;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTab = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.surfaceMuted : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _tabs[i],
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                        color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: asyncData.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, st) => const Center(child: Text('Could not load data')),
              data: (weighIns) {
                if (weighIns.isEmpty) {
                  return const Center(child: Text("No weigh-ins yet."));
                }
                
                return LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      drawHorizontalLine: true,
                      getDrawingHorizontalLine: (_) => const FlLine(
                        color: AppColors.border, strokeWidth: 1, dashArray: [4, 4],
                      ),
                      drawVerticalLine: false,
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true, reservedSize: 36,
                          getTitlesWidget: (val, _) => Text(val.toStringAsFixed(1), style: const TextStyle(fontSize: 12, color: AppColors.inactive)),
                        ),
                      ),
                      bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _getChartData(weighIns),
                        color: AppColors.primaryDark,
                        barWidth: 2,
                        isCurved: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [AppColors.primary.withValues(alpha: 0.15), Colors.transparent],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                    lineTouchData: const LineTouchData(enabled: true),
                  ),
                );
              }
            )
          ),
        ],
      ),
    );
  }
  
  List<FlSpot> _getChartData(List<WeighInEntry> weighIns) {
    if (weighIns.isEmpty) return const [];
    
    // Simplistic rendering based on index to show progression
    List<FlSpot> spots = [];
    for (int i = 0; i < weighIns.length; i++) {
      spots.add(FlSpot(i.toDouble(), weighIns[i].weight));
    }
    return spots;
  }

}
