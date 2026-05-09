import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
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

  @override
  Widget build(BuildContext context) {
    final typeColor = EventsTheme.eventTypeColor(event.eventType);
    final typeLightColor = EventsTheme.eventTypeLightColor(event.eventType);
    final dateFormat = DateFormat('EEE, MMM d • h:mm a');

    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: 'event-hero-${event.id}',
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: EventsTheme.cardBackground,
              borderRadius: BorderRadius.circular(EventsTheme.cardRadius),
              border: Border.all(color: EventsTheme.cardStroke, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cover image / gradient ──
                _buildCover(typeColor),
                // ── Content ────────────────
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: typeLightColor,
                          borderRadius: BorderRadius.circular(EventsTheme.chipRadius),
                        ),
                        child: Text(
                          _typeLabel(event.eventType),
                          style: TextStyle(
                            color: typeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Title
                      Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: EventsTheme.foreground,
                          fontFamily: EventsTheme.headingFont,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Date row
                      _buildMetaRow(
                        LucideIcons.calendar,
                        dateFormat.format(event.startTime),
                        typeColor,
                      ),
                      if (event.locationName != null && event.locationName!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _buildMetaRow(
                          LucideIcons.mapPin,
                          event.locationName!,
                          typeColor,
                        ),
                      ],
                      const SizedBox(height: 12),
                      // Footer row
                      Row(
                        children: [
                          // Participants
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: EventsTheme.surfaceMuted,
                              borderRadius: BorderRadius.circular(EventsTheme.chipRadius),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.users, size: 13, color: EventsTheme.muted),
                                const SizedBox(width: 5),
                                Text(
                                  '${event.participantsCount} going',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: EventsTheme.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Arrow CTA
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              LucideIcons.arrowRight,
                              color: typeColor,
                              size: 16,
                            ),
                          ),
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

  Widget _buildCover(Color typeColor) {
    if (event.imageUrl != null && event.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(EventsTheme.cardRadius)),
        child: Image.network(
          event.imageUrl!,
          height: 160,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildGradientCover(typeColor),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildGradientCover(typeColor);
          },
        ),
      );
    }
    return _buildGradientCover(typeColor);
  }

  Widget _buildGradientCover(Color typeColor) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [typeColor, typeColor.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(EventsTheme.cardRadius)),
      ),
      child: Center(
        child: Icon(
          _typeIcon(event.eventType),
          size: 56,
          color: Colors.white.withValues(alpha: 0.25),
        ),
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String text, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor.withValues(alpha: 0.7)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: EventsTheme.muted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  String _typeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'running': return 'RUNNING';
      case 'walking': return 'WALKING';
      case 'soccer': return 'SOCCER';
      case 'cycling': return 'CYCLING';
      case 'swimming': return 'SWIMMING';
      default: return type.toUpperCase();
    }
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'running': return LucideIcons.timer;
      case 'walking': return LucideIcons.footprints;
      case 'soccer': return LucideIcons.activity;
      case 'cycling': return LucideIcons.bike;
      case 'swimming': return LucideIcons.waves;
      default: return LucideIcons.calendar;
    }
  }
}
