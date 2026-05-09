import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/events_provider.dart';
import '../../theme/events_theme.dart';
import '../../domain/models/event.dart';
import '../widgets/event_shimmer.dart';
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

class _EventDetailScreenState extends ConsumerState<EventDetailScreen>
    with SingleTickerProviderStateMixin {
  Event? _event;
  bool _isLoading = true;
  bool _isActionLoading = false;
  bool _descExpanded = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _loadEvent();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadEvent() async {
    final event = await ref.read(eventsProvider.notifier).getEvent(widget.eventId);
    if (mounted) {
      setState(() {
        _event = event;
        _isLoading = false;
      });
      _fadeController.forward();
    }
  }

  void _handleJoin() async {
    setState(() => _isActionLoading = true);
    final success = await ref.read(eventsProvider.notifier).joinEvent(widget.eventId);
    if (success) {
      await _loadEvent();
    } else if (mounted) {
      _showSnack('Failed to join event. Please try again.');
    }
    if (mounted) setState(() => _isActionLoading = false);
  }

  void _openWhatsApp() async {
    if (_event?.whatsappLink == null) return;
    final url = Uri.parse(_event!.whatsappLink!);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      _showSnack('Could not open WhatsApp');
    }
  }

  void _openMaps() async {
    if (_event?.locationName == null) return;
    final query = Uri.encodeComponent(_event!.locationName!);
    final url = Uri.parse('https://maps.google.com/?q=$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: EventsTheme.foreground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: EventsTheme.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(EventsTheme.pagePadding),
            child: Column(
              children: [
                // Back button placeholder
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: EventsTheme.cardBackground,
                          shape: BoxShape.circle,
                          border: Border.all(color: EventsTheme.cardStroke),
                        ),
                        child: const Icon(LucideIcons.arrowLeft, size: 18, color: EventsTheme.foreground),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const EventShimmerList(count: 1),
              ],
            ),
          ),
        ),
      );
    }

    if (_event == null) {
      return Scaffold(
        backgroundColor: EventsTheme.background,
        appBar: AppBar(
          backgroundColor: EventsTheme.background,
          elevation: 0,
          iconTheme: const IconThemeData(color: EventsTheme.foreground),
        ),
        body: const Center(
          child: Text('Event not found', style: TextStyle(color: EventsTheme.foreground)),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    final typeColor = EventsTheme.eventTypeColor(_event!.eventType);
    final dateFormat = DateFormat('EEEE, MMMM d');
    final timeFormat = DateFormat('h:mm a');

    return Scaffold(
      backgroundColor: EventsTheme.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero Sliver App Bar ─────────────────────────────
          SliverAppBar(
            backgroundColor: typeColor,
            expandedHeight: 260,
            pinned: true,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'event-hero-${_event!.id}',
                child: _buildHeroImage(typeColor),
              ),
            ),
            leading: _buildBackButton(),
            actions: [
              _buildShareButton(),
            ],
          ),

          // ── Content ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(EventsTheme.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: EventsTheme.eventTypeLightColor(_event!.eventType),
                      borderRadius: BorderRadius.circular(EventsTheme.chipRadius),
                    ),
                    child: Text(
                      _event!.eventType.toUpperCase(),
                      style: TextStyle(
                        color: typeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Title
                  Text(
                    _event!.title,
                    style: const TextStyle(
                      color: EventsTheme.foreground,
                      fontFamily: EventsTheme.headingFont,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Info Cards ───────────────────────────────
                  _buildInfoCard([
                    _InfoRow(
                      icon: LucideIcons.calendar,
                      label: 'Date',
                      value: dateFormat.format(_event!.startTime),
                      color: typeColor,
                    ),
                    _InfoRow(
                      icon: LucideIcons.clock,
                      label: 'Time',
                      value: timeFormat.format(_event!.startTime),
                      color: typeColor,
                    ),
                  ]),
                  const SizedBox(height: 12),

                  if (_event!.locationName != null && _event!.locationName!.isNotEmpty)
                    GestureDetector(
                      onTap: _openMaps,
                      child: _buildInfoCard([
                        _InfoRow(
                          icon: LucideIcons.mapPin,
                          label: 'Location',
                          value: _event!.locationName!,
                          color: typeColor,
                          trailingIcon: LucideIcons.externalLink,
                        ),
                      ]),
                    ),
                  const SizedBox(height: 12),

                  _buildInfoCard([
                    _InfoRow(
                      icon: LucideIcons.users,
                      label: 'Attendees',
                      value: '${_event!.participantsCount} going${_event!.maxParticipants != null ? ' · ${_event!.maxParticipants} spots' : ''}',
                      color: typeColor,
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // ── Description ─────────────────────────────
                  if (_event!.description != null && _event!.description!.isNotEmpty) ...[
                    const Text(
                      'About this event',
                      style: TextStyle(
                        color: EventsTheme.foreground,
                        fontFamily: EventsTheme.headingFont,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 220),
                      crossFadeState: _descExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: Text(
                        _event!.description!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: EventsTheme.muted,
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                      secondChild: Text(
                        _event!.description!,
                        style: const TextStyle(
                          color: EventsTheme.muted,
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                    ),
                    if (_event!.description!.length > 120)
                      GestureDetector(
                        onTap: () => setState(() => _descExpanded = !_descExpanded),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _descExpanded ? 'Show less' : 'Read more',
                            style: TextStyle(
                              color: typeColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],

                  // Bottom spacing for action bar
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildActionBar(typeColor),
    );
  }

  Widget _buildHeroImage(Color typeColor) {
    if (_event!.imageUrl != null && _event!.imageUrl!.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _event!.imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildGradientHero(typeColor),
          ),
          // Scrim for text readability
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.4),
                ],
              ),
            ),
          ),
        ],
      );
    }
    return _buildGradientHero(typeColor);
  }

  Widget _buildGradientHero(Color typeColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [typeColor, typeColor.withValues(alpha: 0.65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          LucideIcons.calendar,
          size: 72,
          color: Colors.white.withValues(alpha: 0.18),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Widget _buildShareButton() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: const Icon(LucideIcons.share2, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildInfoCard(List<_InfoRow> rows) {
    return Container(
      decoration: BoxDecoration(
        color: EventsTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EventsTheme.cardStroke),
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final isLast = entry.key == rows.length - 1;
          final row = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: row.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(row.icon, color: row.color, size: 18),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.label,
                            style: const TextStyle(
                              color: EventsTheme.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            row.value,
                            style: const TextStyle(
                              color: EventsTheme.foreground,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (row.trailingIcon != null)
                      Icon(row.trailingIcon!, size: 16, color: EventsTheme.muted),
                  ],
                ),
              ),
              if (!isLast)
                Divider(height: 1, thickness: 1, color: EventsTheme.cardStroke, indent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionBar(Color typeColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      decoration: BoxDecoration(
        color: EventsTheme.cardBackground,
        border: Border(top: BorderSide(color: EventsTheme.cardStroke)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: _buildActionButton(typeColor),
      ),
    );
  }

  Widget _buildActionButton(Color typeColor) {
    if (_event!.isJoined) {
      if (_event!.whatsappLink != null && _event!.whatsappLink!.isNotEmpty) {
        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _openWhatsApp,
            icon: const Icon(LucideIcons.messageCircle, color: Colors.white, size: 20),
            label: const Text(
              'Join WhatsApp Group',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        );
      }
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: null,
          icon: Icon(LucideIcons.circleCheck, color: Colors.white.withValues(alpha: 0.7), size: 20),
          label: Text(
            'You\'re Going!',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.7)),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            disabledBackgroundColor: const Color(0xFF4CAF50),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isActionLoading ? null : _handleJoin,
        style: ElevatedButton.styleFrom(
          backgroundColor: EventsTheme.primary,
          disabledBackgroundColor: EventsTheme.primary.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isActionLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : const Text(
                'Join Event',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
              ),
      ),
    );
  }
}

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final IconData? trailingIcon;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.trailingIcon,
  });
}
