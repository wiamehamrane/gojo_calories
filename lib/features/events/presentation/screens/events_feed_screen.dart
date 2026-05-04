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
      backgroundColor: EventsTheme.darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: 16),
              _buildSegmentedControl(),
              const SizedBox(height: 32),
              _buildHeroSection(),
              const SizedBox(height: 32),
              _buildCreateEventPrompt(context),
              const SizedBox(height: 48),
              _buildSectionTitle('Upcoming Events'),
              const SizedBox(height: 16),
              _buildEventsList(eventsState),
              const SizedBox(height: 40),
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
          Icon(LucideIcons.menu, color: EventsTheme.darkForeground),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: EventsTheme.darkCardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: EventsTheme.darkCardStroke),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(LucideIcons.search, color: EventsTheme.darkMuted, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: const TextStyle(color: EventsTheme.darkForeground),
                      decoration: InputDecoration(
                        hintText: 'Search events...',
                        hintStyle: TextStyle(color: EventsTheme.darkMuted, fontFamily: EventsTheme.bodyFont),
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
            backgroundColor: EventsTheme.darkCardStroke,
            child: Text('ME', style: TextStyle(color: EventsTheme.darkForeground, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: EventsTheme.darkCardBackground,
          borderRadius: BorderRadius.circular(20),
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? EventsTheme.darkCardStroke : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? EventsTheme.darkForeground : EventsTheme.darkMuted,
            fontFamily: EventsTheme.bodyFont,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Find your next marathon.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: EventsTheme.darkForeground,
              fontFamily: EventsTheme.headingFont,
              fontSize: 48,
              fontWeight: FontWeight.w700,
              height: 1.1,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Join the community and get moving with over 1M+ members on GojoCalories.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: EventsTheme.darkMuted,
              fontFamily: EventsTheme.bodyFont,
              fontSize: 16,
              height: 1.4,
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
            color: EventsTheme.darkCardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: EventsTheme.darkCardStroke, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Start a soccer match, marathon, or walk',
                style: TextStyle(
                  color: EventsTheme.darkMuted,
                  fontFamily: EventsTheme.bodyFont,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: EventsTheme.darkCardStroke,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(LucideIcons.plus, color: EventsTheme.darkForeground, size: 20),
                  ),
                  const Spacer(),
                  Icon(LucideIcons.mic, color: EventsTheme.darkMuted, size: 20),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: EventsTheme.darkCardStroke,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(LucideIcons.arrowUp, color: EventsTheme.darkForeground, size: 20),
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
          color: EventsTheme.darkForeground,
          fontFamily: EventsTheme.headingFont,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEventsList(AsyncValue eventsState) {
    return eventsState.when(
      data: (events) {
        if (events.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("No events found.", style: TextStyle(color: EventsTheme.darkMuted)),
          );
        }
        return SizedBox(
          height: 200,
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
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          gradient: EventsTheme.orangeGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.calendarDays, color: Colors.white.withValues(alpha: 0.9), size: 20),
                const SizedBox(width: 8),
                Text(
                  event.eventType.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    fontSize: 12,
                  ),
                ),
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
                fontSize: 28,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${dateFormat.format(event.startTime)} • ${event.participantsCount} joined',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontFamily: EventsTheme.bodyFont,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
