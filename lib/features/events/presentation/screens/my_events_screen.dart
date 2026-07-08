import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/error_handler.dart';
import '../../domain/models/event.dart';
import '../../theme/events_theme.dart';
import '../providers/events_provider.dart';
import '../widgets/event_card.dart';

/// Manage events created by the current user: open, edit, or delete them.
class MyEventsScreen extends ConsumerWidget {
  const MyEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myEventsAsync = ref.watch(myEventsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.chevronLeft,
            size: 24,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            HapticFeedback.selectionClick();
            context.pop();
          },
        ),
        title: const Text(
          'My Events',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () =>
            ref.read(myEventsProvider.notifier).fetchMyEvents(),
        child: myEventsAsync.when(
          loading: () =>
              const Center(child: CupertinoActivityIndicator(radius: 14)),
          error: (e, _) => _MessageState(
            icon: LucideIcons.wifiOff,
            title: 'Couldn\'t load your events',
            message: AppErrorHandler.message(e),
            actionLabel: 'Retry',
            onAction: () =>
                ref.read(myEventsProvider.notifier).fetchMyEvents(),
          ),
          data: (events) {
            if (events.isEmpty) {
              return _MessageState(
                icon: LucideIcons.calendarPlus,
                title: 'No events yet',
                message:
                    'Events you create will show up here,\nready to edit or delete.',
                actionLabel: 'Create event',
                onAction: () => context.push(RoutePaths.createEvent),
              );
            }
            return ListView.builder(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                8,
                AppSpacing.screenPadding,
                40,
              ),
              itemCount: events.length,
              itemBuilder: (context, index) =>
                  _MyEventTile(event: events[index]),
            );
          },
        ),
      ),
    );
  }
}

class _MyEventTile extends ConsumerWidget {
  final Event event;

  const _MyEventTile({required this.event});

  bool get _isPast => event.startTime.isBefore(DateTime.now());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typeColor = EventsTheme.eventTypeColor(event.eventType);
    final imageUrl = EventCard.resolveImageUrl(event);

    return GestureDetector(
      onTap: () => context.push('/events/detail/${event.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadows.cardShadow,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.thumb),
              child: SizedBox(
                width: 64,
                height: 64,
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            _thumbFallback(typeColor),
                      )
                    : _thumbFallback(typeColor),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyBold.copyWith(fontSize: 15),
                        ),
                      ),
                      if (_isPast) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius:
                                BorderRadius.circular(AppRadius.chip),
                          ),
                          child: Text(
                            'PAST',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('EEE, MMM d • h:mm a').format(event.startTime),
                    style: AppTextStyles.bodyRegular.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.users,
                        size: 11,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${event.participantsCount} going',
                        style:
                            AppTextStyles.bodyRegular.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _showActions(context, ref),
              icon: const Icon(
                LucideIcons.ellipsis,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbFallback(Color typeColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [typeColor, typeColor.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        LucideIcons.calendar,
        size: 22,
        color: Colors.white.withValues(alpha: 0.5),
      ),
    );
  }

  void _showActions(BuildContext context, WidgetRef ref) {
    HapticFeedback.selectionClick();
    showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        title: Text(event.title),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(sheetContext);
              context.push(RoutePaths.editEvent, extra: event);
            },
            child: const Text('Edit Event'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(sheetContext);
              _confirmDelete(context, ref);
            },
            child: const Text('Delete Event'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(sheetContext),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        title: const Text('Delete Event?'),
        content: Text(
          '"${event.title}" will be removed for everyone who joined. This cannot be undone.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(myEventsProvider.notifier).deleteEvent(event.id);
      HapticFeedback.mediumImpact();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Event deleted'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.textPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppErrorHandler.message(e)),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.danger,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 100, 40, 0),
          child: Column(
            children: [
              Icon(icon, size: 36, color: AppColors.inactive),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyBold.copyWith(fontSize: 17),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyRegular.copyWith(height: 1.45),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: onAction,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Text(
                    actionLabel,
                    style: AppTextStyles.bodyBold.copyWith(
                      color: AppColors.primaryDark,
                      fontSize: 14,
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
}
