import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:gojocalories/core/theme/app_colors.dart';
import 'package:gojocalories/core/theme/app_radius.dart';
import 'package:gojocalories/core/theme/app_shadows.dart';
import 'package:gojocalories/core/theme/app_spacing.dart';
import 'package:gojocalories/core/theme/app_text_styles.dart';
import '../../domain/models/event.dart';
import '../../theme/events_theme.dart';
import '../providers/events_provider.dart';
import '../widgets/event_card.dart';
import '../widgets/event_image_carousel.dart';

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
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _loadEvent();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadEvent() async {
    final event =
        await ref.read(eventsProvider.notifier).getEvent(widget.eventId);
    if (mounted) {
      setState(() {
        _event = event;
        _isLoading = false;
      });
      _fadeController.forward();
    }
  }

  Future<void> _handleJoin() async {
    HapticFeedback.lightImpact();
    setState(() => _isActionLoading = true);
    final success =
        await ref.read(eventsProvider.notifier).joinEvent(widget.eventId);
    if (success) {
      HapticFeedback.mediumImpact();
      await _loadEvent();
    } else if (mounted) {
      _showSnack('Failed to join event. Please try again.');
    }
    if (mounted) setState(() => _isActionLoading = false);
  }

  Future<void> _openWhatsApp() async {
    if (_event?.whatsappLink == null) return;
    HapticFeedback.selectionClick();
    final url = Uri.parse(_event!.whatsappLink!);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      _showSnack('Could not open WhatsApp');
    }
  }

  Future<void> _openMaps() async {
    if (_event?.locationName == null) return;
    HapticFeedback.selectionClick();
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
        backgroundColor: AppColors.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            const Center(
              child: CupertinoActivityIndicator(radius: 14),
            ),
            SafeArea(
              child: _BackButton(onTap: () => Navigator.pop(context)),
            ),
          ],
        ),
      );
    }

    if (_event == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _BackButton(onTap: () => Navigator.pop(context)),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      LucideIcons.calendarX,
                      size: 36,
                      color: AppColors.inactive,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Event not found',
                      style: AppTextStyles.bodyBold.copyWith(fontSize: 17),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'It may have been removed by its creator.',
                      style: AppTextStyles.bodyRegular,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    final event = _event!;
    final typeColor = EventsTheme.eventTypeColor(event.eventType);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _BackButton(
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  0,
                  AppSpacing.screenPadding,
                  24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SurfaceCard(child: _buildHeaderRow(event, typeColor)),
                    const SizedBox(height: 12),
                    _buildInfoCard(event, typeColor),
                    const SizedBox(height: 20),
                    _buildAboutSection(event),
                    const SizedBox(height: 16),
                    _buildHeroImage(event, typeColor),
                  ],
                ),
              ),
            ),
            _buildActionBar(event),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────

  Widget _buildHeaderRow(Event event, Color typeColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildThumb(event, typeColor),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: AppTextStyles.bodyBold.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _briefSubtitle(event),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyRegular.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
        
      ],
    );
  }

  Widget _buildThumb(Event event, Color typeColor) {
    final imageUrl = EventCard.resolveImageUrl(event);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.thumb),
      child: SizedBox(
        width: 56,
        height: 56,
        child: imageUrl != null
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _thumbFallback(typeColor),
              )
            : _thumbFallback(typeColor),
      ),
    );
  }

  Widget _thumbFallback(Color typeColor) {
    return ColoredBox(
      color: typeColor.withValues(alpha: 0.12),
      child: Icon(
        LucideIcons.calendar,
        size: 24,
        color: typeColor,
      ),
    );
  }

  Widget _buildAttendeeStat(Event event, Color typeColor) {
    final count = event.maxParticipants != null
        ? '${event.participantsCount}/${event.maxParticipants}'
        : '${event.participantsCount}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          count,
          style: AppTextStyles.bodyBold.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: typeColor,
            height: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'attending',
          style: AppTextStyles.bodyRegular.copyWith(fontSize: 11),
        ),
      ],
    );
  }

  String _briefSubtitle(Event event) {
    final parts = <String>[
      _capitalize(event.eventType),
      _audienceLabel(event.audience),
    ];
    if (event.locationName != null && event.locationName!.isNotEmpty) {
      parts.add(event.locationName!);
    }
    return parts.join(' · ');
  }

  // ── Info card (iOS grouped rows) ─────────────────────────────

  Widget _buildInfoCard(Event event, Color typeColor) {
    final rows = <_InfoRowData>[
      _InfoRowData(
        icon: LucideIcons.calendar,
        label: 'Date',
        value: DateFormat('EEE, MMM d').format(event.startTime),
        color: typeColor,
      ),
      _InfoRowData(
        icon: LucideIcons.clock,
        label: 'Time',
        value: DateFormat('h:mm a').format(event.startTime),
        color: typeColor,
      ),
      if (event.locationName != null && event.locationName!.isNotEmpty)
        _InfoRowData(
          icon: LucideIcons.mapPin,
          label: 'Location',
          value: event.locationName!,
          color: typeColor,
          trailingIcon: LucideIcons.chevronRight,
          onTap: _openMaps,
        ),
      _InfoRowData(
        icon: _audienceIcon(event.audience),
        label: 'Who can attend',
        value: _audienceLabel(event.audience),
        color: AppColors.primaryDark,
      ),
    ];

    return _InfoCard(rows: rows);
  }

  // ── About ────────────────────────────────────────────────────

  Widget _buildAboutSection(Event event) {
    final description = event.description?.trim();
    final hasDescription = description != null && description.isNotEmpty;
    final isLong = hasDescription && description.length > 180;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About this event',
          style: AppTextStyles.sectionHeader.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 10),
        _SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasDescription)
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  alignment: Alignment.topCenter,
                  child: Text(
                    description,
                    maxLines: _descExpanded || !isLong ? null : 5,
                    overflow: _descExpanded || !isLong
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: AppTextStyles.bodyRegular.copyWith(
                      fontSize: 15,
                      height: 1.55,
                      color: AppColors.textPrimary,
                    ),
                  ),
                )
              else
                Text(
                  'No description yet. Join to connect with the group.',
                  style: AppTextStyles.bodyRegular.copyWith(
                    fontSize: 15,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              if (isLong)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _descExpanded = !_descExpanded);
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      _descExpanded ? 'Show less' : 'Read more',
                      style: AppTextStyles.bodyBold.copyWith(
                        fontSize: 14,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Hero image ───────────────────────────────────────────────

  Widget _buildHeroImage(Event event, Color typeColor) {
    return Hero(
      tag: 'event-hero-${event.id}',
      child: EventImageCarousel(
        event: event,
        aspectRatio: 4 / 3,
        borderRadius: BorderRadius.circular(AppRadius.card),
        placeholder: _imageFallback(typeColor),
      ),
    );
  }

  Widget _imageFallback(Color typeColor) {
    return ColoredBox(
      color: AppColors.surfaceMuted,
      child: Center(
        child: Icon(
          LucideIcons.image,
          size: 48,
          color: typeColor.withValues(alpha: 0.35),
        ),
      ),
    );
  }

  // ── Bottom action bar ────────────────────────────────────────

  Widget _buildActionBar(Event event) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            12,
            AppSpacing.screenPadding,
            0,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.92),
            border: const Border(
              top: BorderSide(color: AppColors.border, width: 0.5),
            ),
          ),
          child: SafeArea(
            top: false,
            child: _buildActionButton(event),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(Event event) {
    if (event.isJoined) {
      if (event.whatsappLink != null && event.whatsappLink!.isNotEmpty) {
        return _CtaButton(
          onPressed: _openWhatsApp,
          background: AppColors.primary,
          label: 'Join now',
        );
      }
      return const _CtaButton(
        onPressed: null,
        background: Color(0xFF4CAF50),
        icon: LucideIcons.circleCheck,
        label: "You're going!",
      );
    }

    return _CtaButton(
      onPressed: _isActionLoading ? null : _handleJoin,
      background: AppColors.primaryDark,
      label: 'Join now',
      loading: _isActionLoading,
    );
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  static String _audienceLabel(String audience) {
    switch (audience.toLowerCase()) {
      case 'female':
        return 'Females only';
      case 'male':
        return 'Males only';
      default:
        return 'Everyone';
    }
  }

  static IconData _audienceIcon(String audience) {
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

// ── Shared widgets ─────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              boxShadow: AppShadows.cardShadow,
            ),
            child: const Icon(
              LucideIcons.chevronLeft,
              size: 22,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;

  const _SurfaceCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.cardShadow,
      ),
      child: child,
    );
  }
}

class _InfoRowData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final IconData? trailingIcon;
  final VoidCallback? onTap;

  const _InfoRowData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.trailingIcon,
    this.onTap,
  });
}

class _InfoCard extends StatelessWidget {
  final List<_InfoRowData> rows;

  const _InfoCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            _buildRow(rows[i]),
            if (i != rows.length - 1)
              const Padding(
                padding: EdgeInsets.only(left: 66),
                child: Divider(
                  height: 1,
                  thickness: 0.5,
                  color: AppColors.border,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(_InfoRowData row) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: row.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(row.icon, color: row.color, size: 17),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.label,
                  style: AppTextStyles.bodyRegular.copyWith(
                    fontSize: 12,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  row.value,
                  style: AppTextStyles.bodyBold.copyWith(fontSize: 15),
                ),
              ],
            ),
          ),
          if (row.trailingIcon != null)
            Icon(row.trailingIcon, size: 18, color: AppColors.inactive),
        ],
      ),
    );

    if (row.onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: row.onTap, child: content),
    );
  }
}

class _CtaButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color background;
  final String label;
  final IconData? icon;
  final bool loading;

  const _CtaButton({
    required this.onPressed,
    required this.background,
    required this.label,
    this.icon,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          disabledBackgroundColor: background.withValues(alpha: 0.85),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.cta),
          ),
        ),
        child: loading
            ? const CupertinoActivityIndicator(color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(label, style: AppTextStyles.buttonLabel),
                ],
              ),
      ),
    );
  }
}
