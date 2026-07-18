import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Private body progress journal — a light, editorial experience with a guided
/// daily 4-angle capture and three ways to travel through time: side-by-side
/// Compare, a Calendar picker, and a Scrub slider.
class ProgressPhotosScreen extends ConsumerStatefulWidget {
  const ProgressPhotosScreen({super.key});

  @override
  ConsumerState<ProgressPhotosScreen> createState() =>
      _ProgressPhotosScreenState();
}

class _ProgressPhotosScreenState extends ConsumerState<ProgressPhotosScreen> {
  int _tab = 0;
  static const _tabs = ['Journal', 'Compare', 'Calendar', 'Scrub'];

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
          content: Text('Today\'s photos saved privately.'),
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
            _topBar(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Eyebrow('Private to you', color: kAccent),
                  const SizedBox(height: 8),
                  Text('Your body journal',
                      style: serif(
                          size: 32, weight: FontWeight.w600, height: 1.02, spacing: -0.5)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
              child: _tabBar(),
            ),
            const Divider(height: 1, thickness: 1, color: kHair),
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
                data: (_) => _body(days, todayDone),
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
      case 3:
        return _ScrubView(days: days);
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
          const Expanded(
            child: Text('Progress',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600, color: kInk)),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _tabBar() {
    return Row(
      children: List.generate(_tabs.length, (i) {
        final on = i == _tab;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _tab = i);
            },
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    _tabs[i],
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                      color: on ? kInk : kMuted,
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 2,
                  width: on ? 26 : 0,
                  decoration: BoxDecoration(
                    color: kAccent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
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
      title: Text('Delete photo?', style: serif(size: 19, weight: FontWeight.w600)),
      content: const Text('This cannot be undone.',
          style: TextStyle(color: kInkSoft)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel', style: TextStyle(color: kInkSoft)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete', style: TextStyle(color: kDanger)),
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

/// Small compact pose switch used by Compare and Scrub.
class _PoseSwitch extends StatelessWidget {
  final BodyPose value;
  final ValueChanged<BodyPose> onChanged;
  const _PoseSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EFE9),
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
              onTap: () => onChanged(p),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: on ? kSurface : null,
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
                child: Text(short,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: on ? kInk : kMuted)),
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
          _TodayCard(done: todayDone, onStart: onStart),
          const SizedBox(height: 30),
          if (days.isEmpty)
            const _EmptyState()
          else ...[
            const Eyebrow('Timeline'),
            const SizedBox(height: 16),
            ...days.asMap().entries.map((e) => Padding(
                  padding: EdgeInsets.only(top: e.key == 0 ? 0 : 26),
                  child: _DaySection(
                    day: e.value,
                    onTap: (p) => _openViewer(
                        context, ref, e.value.photos, e.value.photos.indexOf(p)),
                    onLongPress: (p) => _confirmDelete(context, ref, p),
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
              _Ring(count: count, total: total),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(complete ? 'Today is complete' : 'Today',
                        style: serif(size: 22, weight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      complete
                          ? 'All four angles captured. See you tomorrow.'
                          : '$count of $total angles done — front, sides & back.',
                      style: const TextStyle(
                          color: kInkSoft, fontSize: 13, height: 1.4),
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
          GestureDetector(
            onTap: onStart,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: kInk,
                borderRadius: BorderRadius.circular(14),
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
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  final int count;
  final int total;
  const _Ring({required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              value: total == 0 ? 0 : count / total,
              strokeWidth: 3,
              backgroundColor: kHair,
              valueColor: const AlwaysStoppedAnimation(kAccent),
            ),
          ),
          Text('$count/$total',
              style: serif(size: 16, weight: FontWeight.w600)),
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
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: done ? kAccent : kSurface,
            shape: BoxShape.circle,
            border: Border.all(color: done ? kAccent : kHair, width: 1.4),
          ),
          child: Icon(done ? LucideIcons.check : pose.icon,
              size: 18, color: done ? Colors.white : kMuted),
        ),
        const SizedBox(height: 7),
        Text(short,
            style: TextStyle(
                color: done ? kInk : kMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(label,
                style: serif(
                    size: 17,
                    weight: FontWeight.w600,
                    color: isToday ? kAccent : kInk)),
            const SizedBox(width: 8),
            Text(DateFormat.MMMd().format(day.date),
                style: const TextStyle(color: kMuted, fontSize: 12.5)),
            const Spacer(),
            Text('${day.completedCount}/${kRequiredPoses.length}',
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: complete ? kAccent : kMuted)),
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
          children: kRequiredPoses.map((pose) {
            final photo = day.photoFor(pose);
            return _PoseTile(
              pose: pose,
              photo: photo,
              onTap: photo != null ? () => onTap(photo) : null,
              onLongPress: photo != null ? () => onLongPress(photo) : null,
            );
          }).toList(),
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
    if (photo == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF4F2EC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kHair),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(pose?.icon ?? LucideIcons.image, size: 22, color: kMuted),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: kInkSoft)),
            const SizedBox(height: 2),
            const Text('Not taken',
                style: TextStyle(fontSize: 11, color: kMuted)),
          ],
        ),
      );
    }
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedFoodImage(
              imageUrl: photo!.imageUrl,
              fit: BoxFit.cover,
              memCacheWidth: 700,
              placeholder: const ColoredBox(color: Color(0xFFF1EFE9)),
            ),
            Positioned(
              left: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(label,
                    style: const TextStyle(
                        color: kInk,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
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
          const Icon(LucideIcons.camera, size: 30, color: kAccent),
          const SizedBox(height: 16),
          Text('Start your timeline',
              style: serif(size: 20, weight: FontWeight.w600)),
          const SizedBox(height: 10),
          const Text(
            'Take the same four angles each day. Over time you\'ll see the change clearly.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.5, color: kInkSoft),
          ),
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
  static const _ranges = [
    ('1 week', 7),
    ('1 month', 30),
    ('3 months', 90),
    ('6 months', 180),
    ('1 year', 365),
  ];
  int _range = 2;
  BodyPose _pose = BodyPose.front;

  @override
  Widget build(BuildContext context) {
    final timeline = _timelineFor(widget.days, _pose);
    final weighIns = ref.watch(progressProvider).value ?? const <WeighInEntry>[];

    final ProgressDay? newestDay = timeline.isNotEmpty ? timeline.last : null;
    ProgressDay? olderCalc;
    if (newestDay != null) {
      final target =
          newestDay.date.subtract(Duration(days: _ranges[_range].$2));
      Duration bestDiff = const Duration(days: 100000);
      for (final d in timeline) {
        if (d.date.isAfter(newestDay.date)) continue;
        final diff = (d.date.difference(target)).abs();
        if (diff < bestDiff) {
          bestDiff = diff;
          olderCalc = d;
        }
      }
    }
    final ProgressDay? olderDay = olderCalc;

    return ListView(
      physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
      children: [
        const Text('See how far you\'ve come — pick a range.',
            style: TextStyle(color: kInkSoft, fontSize: 14)),
        const SizedBox(height: 16),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _ranges.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final on = i == _range;
              return GestureDetector(
                onTap: () => setState(() => _range = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: on ? kInk : kSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: on ? kInk : kHair),
                  ),
                  child: Text(_ranges[i].$1,
                      style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: on ? Colors.white : kInkSoft)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        if (newestDay == null)
          _hint('Take a few days of ${_pose.label.toLowerCase()} photos to compare.')
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: _CompareFrame(
                day: olderDay,
                pose: _pose,
                tag: olderDay == null || olderDay == newestDay
                    ? 'Earliest'
                    : _relativeLabel(olderDay.date),
                highlight: false,
                onTap: olderDay == null
                    ? null
                    : () => _openViewer(context, ref, olderDay.photos,
                        olderDay.photos.indexOf(olderDay.photoFor(_pose)!)),
              )),
              const SizedBox(width: 14),
              Expanded(
                  child: _CompareFrame(
                day: newestDay,
                pose: _pose,
                tag: 'Now',
                highlight: true,
                onTap: () => _openViewer(context, ref, newestDay.photos,
                    newestDay.photos.indexOf(newestDay.photoFor(_pose)!)),
              )),
            ],
          ),
        const SizedBox(height: 20),
        _PoseSwitch(value: _pose, onChanged: (p) => setState(() => _pose = p)),
        const SizedBox(height: 18),
        if (newestDay != null && olderDay != null && olderDay != newestDay)
          _deltaCard(olderDay, newestDay, weighIns),
      ],
    );
  }

  Widget _deltaCard(
      ProgressDay older, ProgressDay newest, List<WeighInEntry> weighIns) {
    final wOld = _nearestWeight(weighIns, older.date);
    final wNew = _nearestWeight(weighIns, newest.date);
    final gapDays = newest.date.difference(older.date).inDays;

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
          'Between these two photos. Log weigh-ins to see your weight change here.';
    }

    return EditorialCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Text(big, style: serif(size: 26, weight: FontWeight.w600, color: kAccent)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(lab,
                style: const TextStyle(
                    color: kInkSoft, fontSize: 13, height: 1.4)),
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
              style: const TextStyle(color: kInkSoft, height: 1.45)),
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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 3 / 4.3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (photo != null)
                    CachedFoodImage(
                      imageUrl: photo.imageUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: 800,
                      placeholder: const ColoredBox(color: Color(0xFFF1EFE9)),
                    )
                  else
                    const ColoredBox(color: Color(0xFFF1EFE9)),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
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
          if (day != null) ...[
            const SizedBox(height: 8),
            Text(DateFormat.yMMMd().format(day!.date),
                style: const TextStyle(
                    color: kInkSoft, fontSize: 12.5, fontWeight: FontWeight.w500)),
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
        const Text('Tap any day to view that day\'s photos.',
            style: TextStyle(color: kInkSoft, fontSize: 14)),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _navBtn(LucideIcons.chevronLeft, () {
              setState(() => _month = DateTime(_month.year, _month.month - 1));
            }),
            Text(DateFormat.yMMMM().format(_month),
                style: serif(size: 18, weight: FontWeight.w600)),
            _navBtn(LucideIcons.chevronRight, () {
              final next = DateTime(_month.year, _month.month + 1);
              if (!next.isAfter(
                  DateTime(DateTime.now().year, DateTime.now().month))) {
                setState(() => _month = next);
              }
            }),
          ],
        ),
        const SizedBox(height: 16),
        Row(
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
        const SizedBox(height: 10),
        GridView.count(
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
        const SizedBox(height: 24),
        const Divider(height: 1, thickness: 1, color: kHair),
        const SizedBox(height: 20),
        if (selectedDay != null)
          _DaySection(
            day: selectedDay,
            onTap: (p) => _openViewer(context, ref, selectedDay.photos,
                selectedDay.photos.indexOf(p)),
            onLongPress: (p) => _confirmDelete(context, ref, p),
          )
        else if (_selected != null)
          Column(children: [
            const Icon(LucideIcons.calendarOff, size: 26, color: kMuted),
            const SizedBox(height: 10),
            Text('No photos on ${DateFormat.yMMMd().format(_selected!)}.',
                style: const TextStyle(color: kInkSoft)),
          ]),
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

    return GestureDetector(
      onTap: () => setState(() => _selected = date),
      child: Container(
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

// ─────────────────────────── SCRUB ─────────────────────────────────────────

class _ScrubView extends ConsumerStatefulWidget {
  final List<ProgressDay> days;
  const _ScrubView({required this.days});

  @override
  ConsumerState<_ScrubView> createState() => _ScrubViewState();
}

class _ScrubViewState extends ConsumerState<_ScrubView> {
  BodyPose _pose = BodyPose.front;
  double _value = 1e9; // starts at latest; clamps down to maxIdx

  @override
  Widget build(BuildContext context) {
    final timeline = _timelineFor(widget.days, _pose);
    if (timeline.isEmpty) {
      return ListView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
        children: [
          const Text('Drag to travel through time.',
              style: TextStyle(color: kInkSoft, fontSize: 14)),
          const SizedBox(height: 16),
          _PoseSwitch(value: _pose, onChanged: _switchPose),
          const SizedBox(height: 18),
          EditorialCard(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            child: Column(children: [
              const Icon(LucideIcons.slidersHorizontal, size: 26, color: kAccent),
              const SizedBox(height: 14),
              Text(
                  'No ${_pose.label.toLowerCase()} photos yet. Capture a few days to scrub through them.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: kInkSoft, height: 1.45)),
            ]),
          ),
        ],
      );
    }

    final maxIdx = timeline.length - 1;
    final idx = _value.round().clamp(0, maxIdx);
    final day = timeline[idx];
    final photo = day.photoFor(_pose)!;

    return ListView(
      physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
      children: [
        Text('Drag to travel through time — ${_pose.label.toLowerCase()}.',
            style: const TextStyle(color: kInkSoft, fontSize: 14)),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () =>
              _openViewer(context, ref, day.photos, day.photos.indexOf(photo)),
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedFoodImage(
                    imageUrl: photo.imageUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 1000,
                    placeholder: const ColoredBox(color: Color(0xFFF1EFE9)),
                  ),
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(DateFormat.yMMMd().format(day.date),
                              style: serif(size: 14, weight: FontWeight.w600)),
                          Text(_relativeLabel(day.date),
                              style: const TextStyle(
                                  color: kAccent,
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
        const SizedBox(height: 16),
        if (maxIdx == 0)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text('One photo so far — capture more days to scrub.',
                  style: TextStyle(color: kMuted, fontSize: 12)),
            ),
          )
        else ...[
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              activeTrackColor: kAccent,
              inactiveTrackColor: kHair,
              thumbColor: kSurface,
              overlayColor: kAccent.withValues(alpha: 0.14),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              min: 0,
              max: maxIdx.toDouble(),
              divisions: maxIdx,
              value: idx.toDouble(),
              onChanged: (v) {
                HapticFeedback.selectionClick();
                setState(() => _value = v);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat.MMMd().format(timeline.first.date),
                    style: const TextStyle(color: kMuted, fontSize: 11.5)),
                Text(DateFormat.MMMd().format(timeline.last.date),
                    style: const TextStyle(color: kMuted, fontSize: 11.5)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 22),
        _PoseSwitch(value: _pose, onChanged: _switchPose),
      ],
    );
  }

  void _switchPose(BodyPose p) => setState(() {
        _pose = p;
        _value = 1e9; // snap to latest for the new pose
      });
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
