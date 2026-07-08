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
          margin: const EdgeInsets.only(bottom: 12),
          height: 160,
          decoration: BoxDecoration(
            color: shimmerColor,
            borderRadius: BorderRadius.circular(EventsTheme.cardRadius),
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
