import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_radius.dart';
import 'package:fl_chart/fl_chart.dart';

class SwipableStatCard extends StatefulWidget {
  final Widget primaryView;
  final String title;
  final Color themeColor;
  final List<FlSpot>? chartData;
  /// If non-null, a 3rd page with this widget will be shown (e.g. BMI panel)
  final Widget? extraPage;

  const SwipableStatCard({
    super.key,
    required this.primaryView,
    required this.title,
    required this.themeColor,
    this.chartData,
    this.extraPage,
  });

  @override
  State<SwipableStatCard> createState() => _SwipableStatCardState();
}

class _SwipableStatCardState extends State<SwipableStatCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  int get _pageCount => widget.extraPage != null ? 3 : 2;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          SizedBox(
            height: 140,
            child: PageView(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentPage = i),
              children: [
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: widget.primaryView,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: _buildMiniChart(),
                ),
                if (widget.extraPage != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: widget.extraPage!,
                  ),
              ],
            ),
          ),
          // Page indicator dots
          Positioned(
            bottom: 6,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pageCount, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 4,
                  width: _currentPage == index ? 12 : 4,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? widget.themeColor
                        : AppColors.inactive.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChart() {
    final spots = widget.chartData;
    final hasRealData = spots != null && spots.isNotEmpty;

    // Use real data or a placeholder flat line
    final List<FlSpot> displaySpots;
    if (hasRealData) {
      if (spots.length == 1) {
        // If only 1 day, show a flat line starting from "yesterday"
        displaySpots = [FlSpot(spots[0].x - 1, spots[0].y), spots[0]];
      } else {
        displaySpots = spots;
      }
    } else {
      displaySpots = [const FlSpot(0, 0), const FlSpot(1, 0), const FlSpot(2, 0)];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "${widget.title} Trend",
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              "7d",
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                drawVerticalLine: false,
                horizontalInterval: _computeInterval(displaySpots),
                getDrawingHorizontalLine: (_) => FlLine(
                  color: AppColors.border.withValues(alpha: 0.5),
                  strokeWidth: 0.6,
                ),
              ),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              minY: 0,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => AppColors.textPrimary,
                  getTooltipItems: (spots) => spots
                      .map((s) => LineTooltipItem(
                            s.y.toInt().toString(),
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ))
                      .toList(),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: displaySpots,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: widget.themeColor,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) =>
                        FlDotCirclePainter(
                      radius: hasRealData ? 2.5 : 0,
                      color: widget.themeColor,
                      strokeWidth: 0,
                      strokeColor: Colors.transparent,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        widget.themeColor.withValues(alpha: 0.22),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  double _computeInterval(List<FlSpot> spots) {
    if (spots.isEmpty) return 10;
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    if (maxY <= 0) return 10;
    return (maxY / 3).ceilToDouble();
  }
}
