import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/widgets/cached_food_image.dart';
import '../../../stats/presentation/providers/progress_provider.dart';
import '../../domain/models/progress_photo.dart';
import '../providers/progress_photos_provider.dart';
import '../widgets/progress_glass.dart';
import 'guided_capture_screen.dart';

DateTime _dk(DateTime d) => DateTime(d.year, d.month, d.day);

/// Body progress journal — guided daily 4-angle capture with Compare
/// and Calendar ways to travel through time.
class ProgressPhotosScreen extends ConsumerStatefulWidget {
  const ProgressPhotosScreen({super.key});

  @override
  ConsumerState<ProgressPhotosScreen> createState() =>
      _ProgressPhotosScreenState();
}

class _ProgressPhotosScreenState extends ConsumerState<ProgressPhotosScreen> {
  int _tab = 0;
  static const _tabs = ['Journal', 'Compare', 'Calendar'];

  Future<void> _startGuidedCapture(Set<BodyPose> done) async {
    HapticFeedback.selectionClick();
    final remaining = kRequiredPoses.where((p) => !done.contains(p)).toList();
    final poses = remaining.isEmpty ? kRequiredPoses : remaining;
    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => GuidedCaptureScreen(poses: poses),
      ),
    );
    if (completed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photos saved to your journal.'),
          backgroundColor: kAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final photosAsync = ref.watch(progressPhotosProvider);
    final days = ref.watch(progressDaysProvider);
    final todayDone = ref.watch(todayCompletedPosesProvider);

    return Scaffold(
      backgroundColor: kPaper,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SoftEntrance(child: _topBar(context)),
            SoftEntrance(
              delay: 40.ms,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My body journal',
                      style: display(
                        size: 28,
                        weight: FontWeight.w700,
                        height: 1.1,
                        spacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Front, sides & back — track how you change.',
                      style: body(size: 14, color: kInkSoft, height: 1.35),
                    ),
                  ],
                ),
              ),
            ),
            SoftEntrance(
              delay: 80.ms,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                child: _tabBar(),
              ),
            ),
            Expanded(
              child: photosAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator(color: kAccent)),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(LucideIcons.wifiOff, size: 32, color: kMuted),
                        SizedBox(height: 12),
                        Text('Couldn\'t load your photos. Pull to retry.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: kInkSoft)),
                      ],
                    ),
                  ),
                ),
                data: (_) => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, anim) {
                    final offset = Tween<Offset>(
                      begin: const Offset(0, 0.03),
                      end: Offset.zero,
                    ).animate(anim);
                    return FadeTransition(
                      opacity: anim,
                      child: SlideTransition(position: offset, child: child),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey(_tab),
                    child: _body(days, todayDone),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(List<ProgressDay> days, Set<BodyPose> todayDone) {
    switch (_tab) {
      case 1:
        return _CompareView(days: days);
      case 2:
        return _CalendarView(days: days);
      default:
        return _JournalView(
          days: days,
          todayDone: todayDone,
          onStart: () => _startGuidedCapture(todayDone),
        );
    }
  }

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.chevronLeft, size: 24, color: kInk),
            onPressed: () {
              HapticFeedback.selectionClick();
              context.pop();
            },
          ),
          Expanded(
            child: Text(
              'Progress',
              textAlign: TextAlign.center,
              style: body(size: 15, weight: FontWeight.w700, color: kInk),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _tabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kHair),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final on = i == _tab;
          return Expanded(
            child: ProgressPressable(
              onTap: () => setState(() => _tab = i),
              scale: 0.98,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: on ? kAccent : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: on
                      ? [
                          BoxShadow(
                            color: kAccent.withValues(alpha: 0.28),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  _tabs[i],
                  textAlign: TextAlign.center,
                  style: body(
                    size: 12.5,
                    weight: FontWeight.w700,
                    color: on ? Colors.white : kMuted,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────── shared helpers ────────────────────────────────

List<ProgressDay> _timelineFor(List<ProgressDay> days, BodyPose pose) {
  final list = days.where((d) => d.photoFor(pose) != null).toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  return list;
}

String _relativeLabel(DateTime date) {
  final today = _dk(DateTime.now());
  final day = _dk(date);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return '$diff days ago';
  if (diff < 60) return '${(diff / 7).round()} weeks ago';
  return '${(diff / 30).round()} months ago';
}

Future<void> _confirmDelete(
    BuildContext context, WidgetRef ref, ProgressPhoto photo) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: kSurface,
      title: Text('Delete photo?', style: display(size: 19, weight: FontWeight.w700)),
      content: Text('This cannot be undone.',
          style: body(size: 14, color: kInkSoft)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('Cancel', style: body(size: 14, color: kInkSoft)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text('Delete', style: body(size: 14, color: kDanger, weight: FontWeight.w700)),
        ),
      ],
    ),
  );
  if (ok == true) {
    await ref.read(progressPhotosProvider.notifier).deletePhoto(photo.id);
  }
}

void _openViewer(BuildContext context, WidgetRef ref,
    List<ProgressPhoto> photos, int index) {
  HapticFeedback.selectionClick();
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      pageBuilder: (c, a, b) => FadeTransition(
        opacity: a,
        child: _PhotoViewer(
          photos: photos,
          initialIndex: index,
          onDelete: (p) {
            Navigator.of(c).pop();
            _confirmDelete(context, ref, p);
          },
        ),
      ),
    ),
  );
}

/// Small compact pose switch used by Compare.
class _PoseSwitch extends StatelessWidget {
  final BodyPose value;
  final ValueChanged<BodyPose> onChanged;
  const _PoseSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: kAccentSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: kRequiredPoses.map((p) {
          final on = p == value;
          final short = p == BodyPose.left
              ? 'Left'
              : p == BodyPose.right
                  ? 'Right'
                  : p.label;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(p);
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: on ? kSurface : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: on
                      ? [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2))
                        ]
                      : null,
                ),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: on ? kInk : kMuted),
                  child: Text(short, textAlign: TextAlign.center),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────── JOURNAL ───────────────────────────────────────

class _JournalView extends ConsumerWidget {
  final List<ProgressDay> days;
  final Set<BodyPose> todayDone;
  final VoidCallback onStart;
  const _JournalView(
      {required this.days, required this.todayDone, required this.onStart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return RefreshIndicator(
      color: kAccent,
      backgroundColor: kSurface,
      onRefresh: () => ref.read(progressPhotosProvider.notifier).fetchPhotos(),
      child: ListView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        padding: EdgeInsets.fromLTRB(22, 20, 22, 40 + bottomInset),
        children: [
          SoftEntrance(
            child: _TodayCard(done: todayDone, onStart: onStart),
          ),
          const SizedBox(height: 30),
          if (days.where((d) => d.photos.isNotEmpty).isEmpty)
            SoftEntrance(delay: 120.ms, child: const _EmptyState())
          else ...[
            SoftEntrance(
              delay: 80.ms,
              child: const Eyebrow('Timeline', color: kAccent),
            ),
            const SizedBox(height: 16),
            ...days
                .where((d) => d.photos.isNotEmpty)
                .toList()
                .asMap()
                .entries
                .map((e) => SoftEntrance(
                      delay: (100 + e.key * 50).ms,
                      child: Padding(
                        padding: EdgeInsets.only(top: e.key == 0 ? 0 : 26),
                        child: _DaySection(
                          day: e.value,
                          onTap: (p) => _openViewer(context, ref, e.value.photos,
                              e.value.photos.indexOf(p)),
                          onLongPress: (p) => _confirmDelete(context, ref, p),
                        ),
                      ),
                    )),
          ],
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  final Set<BodyPose> done;
  final VoidCallback onStart;
  const _TodayCard({required this.done, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final count = done.length;
    final total = kRequiredPoses.length;
    final complete = count >= total;

    return EditorialCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedProgressRing(count: count, total: total),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(complete ? 'Today is complete' : 'Today',
                        style: display(size: 21, weight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      complete
                          ? 'All four angles captured. See you tomorrow.'
                          : '$count of $total angles done — front, sides & back.',
                      style: body(size: 13, color: kInkSoft, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: kRequiredPoses
                .map((p) => Expanded(
                    child: _PoseDot(pose: p, done: done.contains(p))))
                .toList(),
          ),
          const SizedBox(height: 22),
          SoftPulse(
            enabled: !complete,
            child: ProgressPressable(
              onTap: onStart,
              haptic: false,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: complete
                      ? null
                      : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [kAccentBright, kAccent],
                        ),
                  color: complete ? kInk : null,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: complete
                      ? null
                      : [
                          BoxShadow(
                            color: kAccent.withValues(alpha: 0.32),
                            blurRadius: 18,
                            spreadRadius: -2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(complete ? LucideIcons.rotateCw : LucideIcons.camera,
                          size: 18, color: Colors.white),
                      const SizedBox(width: 10),
                      Text(
                        complete
                            ? 'Retake today\'s photos'
                            : count == 0
                                ? 'Start today\'s photos'
                                : 'Continue (${total - count} left)',
                        style: body(
                          size: 15,
                          weight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PoseDot extends StatelessWidget {
  final BodyPose pose;
  final bool done;
  const _PoseDot({required this.pose, required this.done});

  @override
  Widget build(BuildContext context) {
    final short = pose == BodyPose.left
        ? 'Left'
        : pose == BodyPose.right
            ? 'Right'
            : pose.label;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: done ? kAccent : kSurface,
            shape: BoxShape.circle,
            border: Border.all(color: done ? kAccent : kHair, width: 1.4),
            boxShadow: done
                ? [
                    BoxShadow(
                      color: kAccent.withValues(alpha: 0.28),
                      blurRadius: 10,
                      spreadRadius: -2,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: Icon(
              done ? LucideIcons.check : pose.icon,
              key: ValueKey(done),
              size: 18,
              color: done ? Colors.white : kMuted,
            ),
          ),
        ),
        const SizedBox(height: 7),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: body(
            size: 11,
            weight: FontWeight.w600,
            color: done ? kInk : kMuted,
          ),
          child: Text(short),
        ),
      ],
    );
  }
}

class _DaySection extends StatelessWidget {
  final ProgressDay day;
  final ValueChanged<ProgressPhoto> onTap;
  final ValueChanged<ProgressPhoto> onLongPress;
  const _DaySection(
      {required this.day, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final label = _relativeLabel(day.date);
    final isToday = label == 'Today';
    final complete = day.completedCount >= kRequiredPoses.length;

    // Only real photos — never empty "Not taken" placeholders.
    final taken = <(BodyPose?, ProgressPhoto)>[
      for (final pose in kRequiredPoses)
        if (day.photoFor(pose) != null) (pose, day.photoFor(pose)!),
      // Legacy shots without a pose still appear in the journal.
      for (final p in day.photos)
        if (p.pose == null) (null, p),
    ];
    if (taken.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(label,
                style: display(
                    size: 17,
                    weight: FontWeight.w700,
                    color: isToday ? kAccent : kInk)),
            const SizedBox(width: 8),
            Text(DateFormat.MMMd().format(day.date),
                style: body(size: 12.5, color: kMuted)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: complete ? kAccentSoft : kHair.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${day.completedCount}/${kRequiredPoses.length}',
                style: body(
                  size: 12,
                  weight: FontWeight.w700,
                  color: complete ? kAccent : kMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Divider(height: 1, thickness: 1, color: kHair),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.8,
          children: [
            for (var i = 0; i < taken.length; i++)
              SoftEntrance(
                delay: (40 * i).ms,
                child: _PoseTile(
                  pose: taken[i].$1,
                  photo: taken[i].$2,
                  onTap: () => onTap(taken[i].$2),
                  onLongPress: () => onLongPress(taken[i].$2),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _PoseTile extends StatelessWidget {
  final BodyPose? pose;
  final ProgressPhoto? photo;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  const _PoseTile(
      {required this.pose, required this.photo, this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final label = pose?.label ?? 'Photo';
    if (photo == null) return const SizedBox.shrink();

    return ProgressPressable(
      onTap: onTap,
      onLongPress: onLongPress,
      scale: 0.96,
      haptic: false,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedFoodImage(
              imageUrl: photo!.imageUrl,
              fit: BoxFit.cover,
              memCacheWidth: 700,
              placeholder: const ColoredBox(color: kAccentSoft),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.45),
                    ],
                  ),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return EditorialCard(
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
      child: Column(
        children: [
          const Icon(LucideIcons.camera, size: 30, color: kAccent)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.06, 1.06),
                duration: 1600.ms,
                curve: Curves.easeInOut,
              )
              .then()
              .fade(begin: 0.85, end: 1, duration: 1600.ms),
          const SizedBox(height: 16),
          Text('Start your timeline',
                  style: display(size: 20, weight: FontWeight.w700))
              .animate()
              .fadeIn(delay: 80.ms, duration: 400.ms)
              .slideY(begin: 0.08, end: 0, duration: 400.ms),
          const SizedBox(height: 10),
          Text(
            'Capture front, sides & back. Your shots stay in your journal so you can compare over time.',
            textAlign: TextAlign.center,
            style: body(size: 14, height: 1.5, color: kInkSoft),
          ).animate().fadeIn(delay: 160.ms, duration: 450.ms),
        ],
      ),
    );
  }
}

// ─────────────────────────── COMPARE ───────────────────────────────────────

class _CompareView extends ConsumerStatefulWidget {
  final List<ProgressDay> days;
  const _CompareView({required this.days});

  @override
  ConsumerState<_CompareView> createState() => _CompareViewState();
}

class _CompareViewState extends ConsumerState<_CompareView> {
  BodyPose _pose = BodyPose.front;
  DateTime? _leftKey;
  DateTime? _rightKey;

  List<ProgressDay> get _timeline => _timelineFor(widget.days, _pose);

  ProgressDay? _dayFor(DateTime? key) {
    if (key == null) return null;
    for (final d in _timeline) {
      if (_dk(d.date) == _dk(key)) return d;
    }
    return null;
  }

  void _ensureDefaults() {
    final timeline = _timeline;
    if (timeline.isEmpty) {
      _leftKey = null;
      _rightKey = null;
      return;
    }
    final keys = timeline.map((d) => _dk(d.date)).toList();
    if (_leftKey == null || !keys.contains(_dk(_leftKey!))) {
      _leftKey = keys.first;
    }
    if (_rightKey == null || !keys.contains(_dk(_rightKey!))) {
      _rightKey = keys.length > 1 ? keys.last : keys.first;
    }
    // Prefer oldest on the left, newest on the right when first landing.
    if (_leftKey != null &&
        _rightKey != null &&
        _dk(_leftKey!).isAfter(_dk(_rightKey!))) {
      final tmp = _leftKey;
      _leftKey = _rightKey;
      _rightKey = tmp;
    }
  }

  @override
  void initState() {
    super.initState();
    _ensureDefaults();
  }

  @override
  void didUpdateWidget(_CompareView old) {
    super.didUpdateWidget(old);
    _ensureDefaults();
  }

  Future<void> _pickDay({required bool isLeft}) async {
    final timeline = _timeline;
    if (timeline.isEmpty) return;
    final current = isLeft ? _leftKey : _rightKey;
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: kSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        final maxH = MediaQuery.sizeOf(ctx).height * 0.55;
        return SafeArea(
          child: SizedBox(
            height: maxH,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 4),
                  child: Text(
                    isLeft ? 'Compare from' : 'Compare to',
                    style: display(size: 18, weight: FontWeight.w700),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
                  child: Text(
                    'Days with a ${_pose.label.toLowerCase()} photo',
                    style: body(size: 13, color: kInkSoft),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: timeline.length,
                    itemBuilder: (_, i) {
                      // Newest first in the picker.
                      final day = timeline[timeline.length - 1 - i];
                      final key = _dk(day.date);
                      final on = current != null && _dk(current) == key;
                      return ListTile(
                        onTap: () => Navigator.pop(ctx, key),
                        leading: Icon(
                          on ? LucideIcons.circleCheck : LucideIcons.calendar,
                          color: on ? kAccent : kMuted,
                          size: 20,
                        ),
                        title: Text(
                          DateFormat.yMMMEd().format(day.date),
                          style: body(
                            size: 15,
                            weight: FontWeight.w600,
                            color: kInk,
                          ),
                        ),
                        subtitle: Text(
                          _relativeLabel(day.date),
                          style: body(size: 12.5, color: kMuted),
                        ),
                        trailing: on
                            ? const Icon(LucideIcons.check,
                                color: kAccent, size: 18)
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (picked == null || !mounted) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (isLeft) {
        _leftKey = picked;
      } else {
        _rightKey = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final weighIns = ref.watch(progressProvider).value ?? const <WeighInEntry>[];
    final leftDay = _dayFor(_leftKey);
    final rightDay = _dayFor(_rightKey);
    final timeline = _timeline;

    return ListView(
      physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
      children: [
        SoftEntrance(
          child: Text(
            'Pick two days to compare side by side.',
            style: body(size: 14, color: kInkSoft),
          ),
        ),
        const SizedBox(height: 16),
        SoftEntrance(
          delay: 40.ms,
          child: _PoseSwitch(
            value: _pose,
            onChanged: (p) => setState(() {
              _pose = p;
              _leftKey = null;
              _rightKey = null;
              _ensureDefaults();
            }),
          ),
        ),
        const SizedBox(height: 18),
        if (timeline.isEmpty)
          SoftEntrance(
            delay: 80.ms,
            child: _hint(
              'Take ${_pose.label.toLowerCase()} photos on different days to compare them.',
            ),
          )
        else if (timeline.length == 1)
          SoftEntrance(
            delay: 80.ms,
            child: _hint(
              'Only one day has a ${_pose.label.toLowerCase()} photo so far. Capture another day to compare.',
            ),
          )
        else ...[
          SoftEntrance(
            delay: 80.ms,
            child: Row(
              children: [
                Expanded(
                  child: _DayPickChip(
                    label: 'From',
                    date: leftDay?.date,
                    onTap: () => _pickDay(isLeft: true),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ProgressPressable(
                    onTap: () {
                      setState(() {
                        final tmp = _leftKey;
                        _leftKey = _rightKey;
                        _rightKey = tmp;
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: kAccentSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(LucideIcons.arrowLeftRight,
                          size: 18, color: kAccent),
                    ),
                  ),
                ),
                Expanded(
                  child: _DayPickChip(
                    label: 'To',
                    date: rightDay?.date,
                    onTap: () => _pickDay(isLeft: false),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SoftEntrance(
            delay: 120.ms,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _CompareFrame(
                    day: leftDay,
                    pose: _pose,
                    tag: leftDay == null
                        ? 'From'
                        : _relativeLabel(leftDay.date),
                    highlight: false,
                    onTap: leftDay == null
                        ? null
                        : () => _openViewer(
                              context,
                              ref,
                              leftDay.photos,
                              leftDay.photos
                                  .indexOf(leftDay.photoFor(_pose)!),
                            ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _CompareFrame(
                    day: rightDay,
                    pose: _pose,
                    tag: rightDay == null
                        ? 'To'
                        : _relativeLabel(rightDay.date),
                    highlight: true,
                    onTap: rightDay == null
                        ? null
                        : () => _openViewer(
                              context,
                              ref,
                              rightDay.photos,
                              rightDay.photos
                                  .indexOf(rightDay.photoFor(_pose)!),
                            ),
                  ),
                ),
              ],
            ),
          ),
          if (leftDay != null &&
              rightDay != null &&
              _dk(leftDay.date) != _dk(rightDay.date)) ...[
            const SizedBox(height: 18),
            SoftEntrance(
              delay: 160.ms,
              child: _deltaCard(leftDay, rightDay, weighIns),
            ),
          ],
        ],
      ],
    );
  }

  Widget _deltaCard(
      ProgressDay older, ProgressDay newer, List<WeighInEntry> weighIns) {
    // Order by date so the gap / weight delta read correctly.
    final a = older.date.isBefore(newer.date) ? older : newer;
    final b = older.date.isBefore(newer.date) ? newer : older;
    final wOld = _nearestWeight(weighIns, a.date);
    final wNew = _nearestWeight(weighIns, b.date);
    final gapDays = b.date.difference(a.date).inDays;

    String big;
    String lab;
    if (wOld != null && wNew != null) {
      final delta = wNew - wOld;
      final sign = delta > 0 ? '+' : '−';
      big = '$sign${delta.abs().toStringAsFixed(1)} kg';
      lab =
          '${wOld.toStringAsFixed(1)} → ${wNew.toStringAsFixed(1)} kg over ${_gapLabel(gapDays)}.';
    } else {
      big = _gapLabel(gapDays);
      lab =
          'Between these two days. Log weigh-ins to see your weight change here.';
    }

    return EditorialCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Text(big,
              style: display(size: 26, weight: FontWeight.w700, color: kAccent)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(lab,
                style: body(size: 13, color: kInkSoft, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _hint(String text) => EditorialCard(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(children: [
          const Icon(LucideIcons.gitCompare, size: 28, color: kAccent),
          const SizedBox(height: 14),
          Text(text,
              textAlign: TextAlign.center,
              style: body(size: 14, color: kInkSoft, height: 1.45)),
        ]),
      );

  static String _gapLabel(int days) {
    if (days < 14) return '$days days';
    if (days < 60) return '${(days / 7).round()} weeks';
    return '${(days / 30).round()} months';
  }

  static double? _nearestWeight(List<WeighInEntry> entries, DateTime date) {
    if (entries.isEmpty) return null;
    WeighInEntry? best;
    Duration bestDiff = const Duration(days: 100000);
    for (final e in entries) {
      final diff = e.date.difference(date).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        best = e;
      }
    }
    if (best == null || bestDiff > const Duration(days: 21)) return null;
    return best.weight;
  }
}

class _DayPickChip extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  const _DayPickChip({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ProgressPressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kHair),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: body(size: 11, weight: FontWeight.w700, color: kMuted)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    date == null
                        ? 'Choose day'
                        : DateFormat.MMMd().format(date!),
                    style: display(size: 15, weight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(LucideIcons.chevronDown, size: 16, color: kMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompareFrame extends StatelessWidget {
  final ProgressDay? day;
  final BodyPose pose;
  final String tag;
  final bool highlight;
  final VoidCallback? onTap;
  const _CompareFrame({
    required this.day,
    required this.pose,
    required this.tag,
    required this.highlight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final photo = day?.photoFor(pose);
    return ProgressPressable(
      onTap: onTap,
      scale: 0.97,
      haptic: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 3 / 4.3,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: highlight
                    ? Border.all(
                        color: kAccent.withValues(alpha: 0.35), width: 1.5)
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      child: photo != null
                          ? CachedFoodImage(
                              key: ValueKey(photo.imageUrl),
                              imageUrl: photo.imageUrl,
                              fit: BoxFit.cover,
                              memCacheWidth: 800,
                              placeholder:
                                  const ColoredBox(color: kAccentSoft),
                            )
                          : const ColoredBox(
                              key: ValueKey('empty'), color: kAccentSoft),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (highlight) ...[
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                    color: kAccent, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 5),
                            ],
                            Text(tag,
                                style: const TextStyle(
                                    color: kInk,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (day != null) ...[
            const SizedBox(height: 8),
            Text(DateFormat.yMMMd().format(day!.date),
                style: body(size: 12.5, color: kInkSoft)),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────── CALENDAR ──────────────────────────────────────

class _CalendarView extends ConsumerStatefulWidget {
  final List<ProgressDay> days;
  const _CalendarView({required this.days});

  @override
  ConsumerState<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<_CalendarView> {
  late DateTime _month;
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _selected = _dk(now);
  }

  @override
  Widget build(BuildContext context) {
    final byDay = <String, ProgressDay>{
      for (final d in widget.days) _key(d.date): d
    };
    final first = _month;
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leading = first.weekday % 7; // Sunday-first
    final selectedDay = _selected == null ? null : byDay[_key(_selected!)];

    return ListView(
      physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
      children: [
        SoftEntrance(
          child: const Text('Tap any day to view that day\'s photos.',
              style: TextStyle(color: kInkSoft, fontSize: 14)),
        ),
        const SizedBox(height: 18),
        SoftEntrance(
          delay: 40.ms,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _navBtn(LucideIcons.chevronLeft, () {
                HapticFeedback.selectionClick();
                setState(
                    () => _month = DateTime(_month.year, _month.month - 1));
              }),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                child: Text(
                  DateFormat.yMMMM().format(_month),
                  key: ValueKey('${_month.year}-${_month.month}'),
                  style: display(size: 18, weight: FontWeight.w700),
                ),
              ),
              _navBtn(LucideIcons.chevronRight, () {
                final next = DateTime(_month.year, _month.month + 1);
                if (!next.isAfter(
                    DateTime(DateTime.now().year, DateTime.now().month))) {
                  HapticFeedback.selectionClick();
                  setState(() => _month = next);
                }
              }),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SoftEntrance(
          delay: 80.ms,
          child: Row(
            children: const ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: const TextStyle(
                                color: kMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 10),
        SoftEntrance(
          delay: 100.ms,
          child: GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              for (int i = 0; i < leading; i++) const SizedBox.shrink(),
              for (int d = 1; d <= daysInMonth; d++)
                _dayCell(DateTime(_month.year, _month.month, d), byDay),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Divider(height: 1, thickness: 1, color: kHair),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: selectedDay != null
              ? KeyedSubtree(
                  key: ValueKey(_key(selectedDay.date)),
                  child: _DaySection(
                    day: selectedDay,
                    onTap: (p) => _openViewer(context, ref, selectedDay.photos,
                        selectedDay.photos.indexOf(p)),
                    onLongPress: (p) => _confirmDelete(context, ref, p),
                  ),
                )
              : _selected != null
                  ? KeyedSubtree(
                      key: ValueKey('empty-${_key(_selected!)}'),
                      child: Column(children: [
                        const Icon(LucideIcons.calendarOff,
                            size: 26, color: kMuted),
                        const SizedBox(height: 10),
                        Text(
                            'No photos on ${DateFormat.yMMMd().format(_selected!)}.',
                            style: const TextStyle(color: kInkSoft)),
                      ]),
                    )
                  : const SizedBox.shrink(key: ValueKey('none')),
        ),
      ],
    );
  }

  Widget _navBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kHair),
          ),
          child: Icon(icon, size: 18, color: kInk),
        ),
      );

  Widget _dayCell(DateTime date, Map<String, ProgressDay> byDay) {
    final entry = byDay[_key(date)];
    final count = entry?.completedCount ?? 0;
    final has = entry != null && entry.photos.isNotEmpty;
    final sel = _selected != null && _key(_selected!) == _key(date);

    return ProgressPressable(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selected = date);
      },
      haptic: false,
      scale: 0.9,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: sel
              ? kInk
              : has
                  ? kAccentSoft
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
              color: sel ? kInk : (has ? Colors.transparent : kHair)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text('${date.day}',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: sel
                        ? Colors.white
                        : has
                            ? kInk
                            : kMuted)),
            if (has && !sel)
              Positioned(
                bottom: 6,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        count >= kRequiredPoses.length ? kAccent : kMuted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

// ─────────────────────────── VIEWER ────────────────────────────────────────

class _PhotoViewer extends StatefulWidget {
  final List<ProgressPhoto> photos;
  final int initialIndex;
  final ValueChanged<ProgressPhoto> onDelete;
  const _PhotoViewer({
    required this.photos,
    required this.initialIndex,
    required this.onDelete,
  });

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.photos.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photos[_index];
    final poseLabel = photo.pose?.label;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x, color: Colors.white),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(DateFormat.yMMMMd().format(photo.photoDate),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                        if (poseLabel != null)
                          Text(poseLabel,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => widget.onDelete(photo),
                    icon: const Icon(LucideIcons.trash2, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.photos.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => InteractiveViewer(
                  child: Center(
                    child: CachedFoodImage(
                      imageUrl: widget.photos[i].imageUrl,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      memCacheWidth: 1600,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 8),
              child: Text('${_index + 1} / ${widget.photos.length}',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
