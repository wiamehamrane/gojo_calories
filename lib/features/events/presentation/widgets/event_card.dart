import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/config/env_config.dart';
import '../../domain/models/event.dart';
import '../../theme/events_theme.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
  });

  static const _cardHeight = 160.0;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, MMM d • h:mm a');
    final typeColor = EventsTheme.eventTypeColor(event.eventType);

    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: 'event-hero-${event.id}',
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: _cardHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(EventsTheme.cardRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildBackground(typeColor),
                _buildGradientOverlay(),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _AudienceBadge(audience: event.audience),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.calendar,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            dateFormat.format(event.startTime),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (event.locationName != null &&
                              event.locationName!.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            const Icon(
                              LucideIcons.mapPin,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                event.locationName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackground(Color typeColor) {
    final imageUrl = resolveImageUrl(event);
    if (imageUrl != null) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildGradientFallback(typeColor),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _buildGradientFallback(typeColor);
        },
      );
    }
    return _buildGradientFallback(typeColor);
  }

  /// Image to show for [event]: uploaded cover when set, otherwise a stock
  /// photo per event type. Relative API paths are resolved to full URLs.
  static String? resolveImageUrl(Event event) {
    if (event.imageUrl != null && event.imageUrl!.isNotEmpty) {
      return EnvConfig.resolveMediaUrl(event.imageUrl);
    }
    return _placeholderForType(event.eventType);
  }

  Widget _buildGradientFallback(Color typeColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            typeColor,
            typeColor.withValues(alpha: 0.55),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          _typeIcon(event.eventType),
          size: 56,
          color: Colors.white.withValues(alpha: 0.18),
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.08),
            Colors.black.withValues(alpha: 0.25),
            Colors.black.withValues(alpha: 0.78),
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
    );
  }

  static String? _placeholderForType(String type) {
    switch (type.toLowerCase()) {
      case 'running':
        return 'https://images.unsplash.com/photo-1552674605-db6ffd4facb5?q=80&w=800&auto=format&fit=crop';
      case 'walking':
        return 'https://images.unsplash.com/photo-1476480862126-209bfaa8efa8?q=80&w=800&auto=format&fit=crop';
      case 'soccer':
        return 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?q=80&w=800&auto=format&fit=crop';
      case 'cycling':
        return 'https://images.unsplash.com/photo-1517649763962-0c62306601b7?q=80&w=800&auto=format&fit=crop';
      case 'swimming':
        return 'https://images.unsplash.com/photo-1530549387789-4c1017266635?q=80&w=800&auto=format&fit=crop';
      default:
        return 'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?q=80&w=800&auto=format&fit=crop';
    }
  }

  static IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'running':
        return LucideIcons.timer;
      case 'walking':
        return LucideIcons.footprints;
      case 'soccer':
        return LucideIcons.activity;
      case 'cycling':
        return LucideIcons.bike;
      case 'swimming':
        return LucideIcons.waves;
      default:
        return LucideIcons.calendar;
    }
  }
}

class _AudienceBadge extends StatelessWidget {
  final String audience;

  const _AudienceBadge({required this.audience});

  @override
  Widget build(BuildContext context) {
    final label = audience.toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(EventsTheme.chipRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconForAudience(audience), size: 10, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconForAudience(String audience) {
    switch (audience.toLowerCase()) {
      case 'female':
        return LucideIcons.venus;
      case 'male':
        return LucideIcons.mars;
      default:
        return LucideIcons.users;
    }
  }
}
