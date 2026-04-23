import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_radius.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SwipableStatCard extends StatefulWidget {
  final Widget primaryView;
  final String title;
  final Color themeColor;

  const SwipableStatCard({
    super.key,
    required this.primaryView,
    required this.title,
    required this.themeColor,
  });

  @override
  State<SwipableStatCard> createState() => _SwipableStatCardState();
}

class _SwipableStatCardState extends State<SwipableStatCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Add extra padding requested: "more space in inside that means smallers content to be beautifully appear"
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
            height: 140, // Fixed height for the swipable content
            child: PageView(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentPage = i),
              children: [
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: widget.primaryView,
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildMiniChart(),
                ),
              ],
            ),
          ),
          // Page indicators
          Positioned(
            bottom: 6,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(2, (index) {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${widget.title} Trend",
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: const [
                    FlSpot(0, 10),
                    FlSpot(1, 15),
                    FlSpot(2, 8),
                    FlSpot(3, 20),
                    FlSpot(4, 18),
                  ], // Mocked for minichart view visual presentation
                  isCurved: true,
                  color: widget.themeColor,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        widget.themeColor.withValues(alpha: 0.3),
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
}
