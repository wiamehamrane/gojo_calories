import 'package:flutter/material.dart';
import '../../domain/models/event.dart';
import '../widgets/event_card.dart';

/// Swipeable image carousel for event photos.
class EventImageCarousel extends StatefulWidget {
  final Event event;
  final double? height;
  final double aspectRatio;
  final BorderRadius borderRadius;
  final Widget? placeholder;

  const EventImageCarousel({
    super.key,
    required this.event,
    this.height,
    this.aspectRatio = 4 / 3,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.placeholder,
  });

  @override
  State<EventImageCarousel> createState() => _EventImageCarouselState();
}

class _EventImageCarouselState extends State<EventImageCarousel> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urls = _uploadedUrls(widget.event);
    if (urls.isEmpty) {
      return ClipRRect(
        borderRadius: widget.borderRadius,
        child: widget.placeholder ??
            AspectRatio(
              aspectRatio: widget.aspectRatio,
              child: const ColoredBox(color: Color(0xFFF2F2F7)),
            ),
      );
    }

    if (urls.length == 1) {
      return ClipRRect(
        borderRadius: widget.borderRadius,
        child: _NetworkImage(
          url: urls.first,
          height: widget.height,
          aspectRatio: widget.aspectRatio,
        ),
      );
    }

    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          SizedBox(
            height: widget.height,
            child: AspectRatio(
              aspectRatio: widget.aspectRatio,
              child: PageView.builder(
                controller: _controller,
                itemCount: urls.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => _NetworkImage(
                  url: urls[i],
                  aspectRatio: widget.aspectRatio,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(urls.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: active ? 8 : 6,
                  height: active ? 8 : 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkImage extends StatelessWidget {
  final String url;
  final double? height;
  final double aspectRatio;

  const _NetworkImage({
    required this.url,
    this.height,
    required this.aspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    final image = Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, _, _) => const ColoredBox(color: Color(0xFFF2F2F7)),
    );

    if (height != null) {
      return SizedBox(height: height, width: double.infinity, child: image);
    }
    return AspectRatio(aspectRatio: aspectRatio, child: image);
  }
}

List<String> _uploadedUrls(Event event) {
  if (event.imageUrls.isNotEmpty) {
    return EventCard.resolveImageUrls(event);
  }
  if (event.imageUrl != null && event.imageUrl!.isNotEmpty) {
    return EventCard.resolveImageUrls(event);
  }
  return [];
}
