import 'package:flutter/material.dart';
import '../../theme/events_theme.dart';

class EventShimmerCard extends StatefulWidget {
  const EventShimmerCard({super.key});

  @override
  State<EventShimmerCard> createState() => _EventShimmerCardState();
}

class _EventShimmerCardState extends State<EventShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final shimmerColor = Color.lerp(
          EventsTheme.shimmerBase,
          EventsTheme.shimmerHighlight,
          _animation.value,
        )!;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: EventsTheme.cardBackground,
            borderRadius: BorderRadius.circular(EventsTheme.cardRadius),
            border: Border.all(color: EventsTheme.cardStroke),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(EventsTheme.cardRadius),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge
                    Container(
                      height: 22,
                      width: 72,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(EventsTheme.chipRadius),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Title line 1
                    Container(
                      height: 18,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Title line 2
                    Container(
                      height: 18,
                      width: 200,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Meta rows
                    Container(
                      height: 14,
                      width: 180,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 14,
                      width: 140,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class EventShimmerList extends StatelessWidget {
  final int count;
  const EventShimmerList({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (_) => const EventShimmerCard()),
    );
  }
}
