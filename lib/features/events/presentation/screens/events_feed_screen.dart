import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/events_provider.dart';
import '../../theme/events_theme.dart';
import 'create_event_screen.dart';
import 'event_detail_screen.dart';
import 'package:intl/intl.dart';

class EventsFeedScreen extends ConsumerStatefulWidget {
  const EventsFeedScreen({super.key});

  @override
  ConsumerState<EventsFeedScreen> createState() => _EventsFeedScreenState();
}

class _EventsFeedScreenState extends ConsumerState<EventsFeedScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isDiscover = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(eventsProvider.notifier).fetchEvents(search: query);
  }

  @override
  Widget build(BuildContext context) {
    final eventsState = ref.watch(eventsProvider);

    return Scaffold(
      backgroundColor: EventsTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: 16),
              _buildSegmentedControl(),
              const SizedBox(height: 32),
              _buildHeroSection(),
              const SizedBox(height: 40),
              _buildCreateEventPrompt(context),
              const SizedBox(height: 48),
              _buildSectionTitle('Upcoming Events'),
              const SizedBox(height: 16),
              _buildEventsList(eventsState),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Icon(LucideIcons.menu, color: EventsTheme.foreground),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: EventsTheme.cardBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: EventsTheme.cardStroke),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(LucideIcons.search, color: EventsTheme.muted, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: TextStyle(color: EventsTheme.foreground, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Search events...',
                        hintStyle: TextStyle(color: EventsTheme.muted, fontFamily: EventsTheme.bodyFont),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 18,
            backgroundColor: EventsTheme.cardStroke,
            child: Text('ME', style: TextStyle(color: EventsTheme.foreground, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: EventsTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: EventsTheme.cardStroke),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSegmentButton('My Events', !_isDiscover),
            _buildSegmentButton('Discover', _isDiscover),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isDiscover = text == 'Discover';
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? EventsTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? EventsTheme.primary : EventsTheme.muted,
            fontFamily: EventsTheme.bodyFont,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Find your next marathon.',
            style: TextStyle(
              color: EventsTheme.foreground,
              fontFamily: EventsTheme.headingFont,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Join the community and get moving with over 1M+ members on GojoCalories.',
            style: TextStyle(
              color: EventsTheme.muted,
              fontFamily: EventsTheme.bodyFont,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateEventPrompt(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateEventScreen()));
        },
        child: Container(
          decoration: BoxDecoration(
            color: EventsTheme.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: EventsTheme.cardStroke, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Host a soccer match, marathon, or walk',
                style: TextStyle(
                  color: EventsTheme.muted,
                  fontFamily: EventsTheme.bodyFont,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: EventsTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.plus, color: Colors.white, size: 20),
                  ),
                  const Spacer(),
                  Icon(LucideIcons.mic, color: EventsTheme.muted.withValues(alpha: 0.5), size: 22),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: EventsTheme.foreground,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.arrowUp, color: Colors.white, size: 20),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        title,
        style: TextStyle(
          color: EventsTheme.foreground,
          fontFamily: EventsTheme.headingFont,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildEventsList(AsyncValue eventsState) {
    return eventsState.when(
      data: (events) {
        if (events.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("No events found.", style: TextStyle(color: EventsTheme.muted, fontSize: 15)),
          );
        }
        return SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return _buildEventCard(context, event);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: EventsTheme.primary)),
      error: (err, stack) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('Error loading events.', style: TextStyle(color: EventsTheme.destructive)),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, dynamic event) {
    final dateFormat = DateFormat('MMM d, h:mm a');
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id)));
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16, bottom: 8),
        decoration: BoxDecoration(
          gradient: EventsTheme.brandGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: EventsTheme.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    event.eventType.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      fontSize: 10,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(LucideIcons.arrowRight, color: Colors.white, size: 18),
              ],
            ),
            const Spacer(),
            Text(
              event.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontFamily: EventsTheme.headingFont,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(LucideIcons.calendar, color: Colors.white.withValues(alpha: 0.8), size: 14),
                const SizedBox(width: 6),
                Text(
                  dateFormat.format(event.startTime),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontFamily: EventsTheme.bodyFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(LucideIcons.users, color: Colors.white.withValues(alpha: 0.8), size: 14),
                const SizedBox(width: 6),
                Text(
                  '${event.participantsCount} joined',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontFamily: EventsTheme.bodyFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
