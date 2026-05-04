import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/events_provider.dart';
import '../../theme/events_theme.dart';
import '../../domain/models/event.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final String eventId;

  const EventDetailScreen({
    super.key,
    required this.eventId,
  });

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  Event? _event;
  bool _isLoading = true;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    final event = await ref.read(eventsProvider.notifier).getEvent(widget.eventId);
    if (mounted) {
      setState(() {
        _event = event;
        _isLoading = false;
      });
    }
  }

  void _handleJoin() async {
    setState(() => _isActionLoading = true);
    final success = await ref.read(eventsProvider.notifier).joinEvent(widget.eventId);
    if (success) {
      await _loadEvent();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to join event')));
    }
    setState(() => _isActionLoading = false);
  }

  void _openWhatsApp() async {
    if (_event?.whatsappLink == null) return;
    final url = Uri.parse(_event!.whatsappLink!);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: EventsTheme.darkBackground,
        body: Center(child: CircularProgressIndicator(color: EventsTheme.primary)),
      );
    }

    if (_event == null) {
      return Scaffold(
        backgroundColor: EventsTheme.darkBackground,
        appBar: AppBar(backgroundColor: EventsTheme.darkBackground, elevation: 0),
        body: const Center(child: Text('Event not found', style: TextStyle(color: EventsTheme.darkForeground))),
      );
    }

    final dateFormat = DateFormat('EEEE, MMMM d • h:mm a');

    return Scaffold(
      backgroundColor: EventsTheme.darkBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: EventsTheme.darkBackground,
            expandedHeight: 250,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: EventsTheme.orangeGradient),
                child: Center(
                  child: Icon(LucideIcons.calendarDays, size: 80, color: Colors.white.withValues(alpha: 0.3)),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: EventsTheme.darkCardStroke,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _event!.eventType.toUpperCase(),
                    style: const TextStyle(
                      color: EventsTheme.darkForeground,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _event!.title,
                  style: const TextStyle(
                    color: EventsTheme.darkForeground,
                    fontFamily: EventsTheme.headingFont,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 24),
                
                _buildInfoRow(LucideIcons.clock, dateFormat.format(_event!.startTime)),
                if (_event!.locationName != null && _event!.locationName!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoRow(LucideIcons.mapPin, _event!.locationName!),
                ],
                const SizedBox(height: 16),
                _buildInfoRow(LucideIcons.users, '${_event!.participantsCount} Attending'),
                
                const SizedBox(height: 32),
                if (_event!.description != null && _event!.description!.isNotEmpty) ...[
                  const Text(
                    'About this event',
                    style: TextStyle(
                      color: EventsTheme.darkForeground,
                      fontFamily: EventsTheme.headingFont,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _event!.description!,
                    style: const TextStyle(
                      color: EventsTheme.darkMuted,
                      fontFamily: EventsTheme.bodyFont,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: EventsTheme.darkBackground,
          border: Border(top: BorderSide(color: EventsTheme.darkCardStroke)),
        ),
        child: SafeArea(
          child: _buildActionButton(),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: EventsTheme.darkCardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: EventsTheme.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: EventsTheme.darkForeground,
              fontFamily: EventsTheme.bodyFont,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    if (_event!.isJoined) {
      if (_event!.whatsappLink != null && _event!.whatsappLink!.isNotEmpty) {
        return ElevatedButton.icon(
          onPressed: _openWhatsApp,
          icon: const Icon(LucideIcons.messageCircle, color: Colors.white),
          label: const Text(
            'Open WhatsApp Group',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366), // WhatsApp Green
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      } else {
        return ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            disabledBackgroundColor: EventsTheme.darkCardStroke,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text(
            'You are going',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: EventsTheme.darkMuted),
          ),
        );
      }
    }

    return ElevatedButton(
      onPressed: _isActionLoading ? null : _handleJoin,
      style: ElevatedButton.styleFrom(
        backgroundColor: EventsTheme.primary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: _isActionLoading
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Text(
              'Join Event',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
            ),
    );
  }
}
