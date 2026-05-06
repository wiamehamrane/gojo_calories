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
        backgroundColor: EventsTheme.background,
        body: Center(child: CircularProgressIndicator(color: EventsTheme.primary)),
      );
    }

    if (_event == null) {
      return Scaffold(
        backgroundColor: EventsTheme.background,
        appBar: AppBar(backgroundColor: EventsTheme.background, elevation: 0),
        body: const Center(child: Text('Event not found', style: TextStyle(color: EventsTheme.foreground))),
      );
    }

    final dateFormat = DateFormat('EEEE, MMMM d • h:mm a');

    return Scaffold(
      backgroundColor: EventsTheme.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: EventsTheme.primary,
            expandedHeight: 200,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: EventsTheme.brandGradient),
                child: Center(
                  child: Icon(LucideIcons.calendar, size: 60, color: Colors.white.withValues(alpha: 0.2)),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: EventsTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _event!.eventType.toUpperCase(),
                    style: const TextStyle(
                      color: EventsTheme.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _event!.title,
                  style: const TextStyle(
                    color: EventsTheme.foreground,
                    fontFamily: EventsTheme.headingFont,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
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
                      color: EventsTheme.foreground,
                      fontFamily: EventsTheme.headingFont,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _event!.description!,
                    style: const TextStyle(
                      color: EventsTheme.muted,
                      fontFamily: EventsTheme.bodyFont,
                      fontSize: 15,
                      height: 1.6,
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: EventsTheme.cardBackground,
          border: Border(top: BorderSide(color: EventsTheme.cardStroke)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: EventsTheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: EventsTheme.primary, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: EventsTheme.foreground,
              fontFamily: EventsTheme.bodyFont,
              fontSize: 15,
              fontWeight: FontWeight.w600,
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
          icon: const Icon(LucideIcons.messageCircle, color: Colors.white, size: 20),
          label: const Text(
            'Join WhatsApp',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        return ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            disabledBackgroundColor: EventsTheme.cardStroke,
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text(
            'You are going',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: EventsTheme.muted),
          ),
        );
      }
    }

    return ElevatedButton(
      onPressed: _isActionLoading ? null : _handleJoin,
      style: ElevatedButton.styleFrom(
        backgroundColor: EventsTheme.primary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isActionLoading
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Text(
              'Join Event',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
            ),
    );
  }
}
