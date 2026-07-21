import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../routing/route_paths.dart';
import '../routing/tab_page_transition.dart';
import '../localization/locale_provider.dart';
import '../localization/translations.dart';

class MainScaffold extends ConsumerStatefulWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  double _dragDx = 0.0;

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/events')) return 1;
    if (location.startsWith('/profile')) return 2;
    return -1;
  }

  static bool _isScanRoute(BuildContext context) {
    return GoRouterState.of(context).uri.path.startsWith('/scan');
  }

  void _onItemTapped(int index, BuildContext context) {
    final from = _calculateSelectedIndex(context);
    if (index == from) return;
    HapticFeedback.selectionClick();
    prepareTabSlide(fromIndex: from, toIndex: index);
    switch (index) {
      case 0:
        context.go(RoutePaths.home);
        break;
      case 1:
        context.go(RoutePaths.events);
        break;
      case 2:
        context.go(RoutePaths.profile);
        break;
    }
  }

  void _showActionGrid(BuildContext context, double aboveOffset) {
    HapticFeedback.lightImpact();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 380),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(opacity: curved, child: child);
      },
      pageBuilder: (context, anim1, anim2) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                Positioned(
                  bottom: aboveOffset,
                  left: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {},
                    child: _ActionGrid(animation: anim1),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    final int currentIndex = _calculateSelectedIndex(context);
    final bool isScan = _isScanRoute(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    const pillHeight = 56.0;
    const pillHMargin = 16.0;
    const fabSize = 60.0;
    final bottomOffset = bottomPadding + 16.0;
    final bool isHome = currentIndex == 0;

    return Scaffold(
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: GestureDetector(
              onHorizontalDragStart: (_) => _dragDx = 0.0,
              onHorizontalDragUpdate: (d) => _dragDx += d.delta.dx,
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0.0;
                final goNext = velocity < -250 || _dragDx < -80;
                final goPrev = velocity > 250 || _dragDx > 80;
                if (goNext && currentIndex >= 0 && currentIndex < 2) {
                  _onItemTapped(currentIndex + 1, context);
                } else if (goPrev && currentIndex > 0) {
                  _onItemTapped(currentIndex - 1, context);
                }
                _dragDx = 0.0;
              },
              child: widget.child,
            ),
          ),

          if (!isScan)
            Positioned(
              bottom: bottomOffset,
              left: pillHMargin,
              right: pillHMargin,
              height: pillHeight,
              child: _FloatingNavBar(
                currentIndex: currentIndex,
                lang: lang,
                pillHeight: pillHeight,
                onTap: (i) => _onItemTapped(i, context),
              ),
            ),

          if (!isScan && isHome)
            Positioned(
              bottom: bottomOffset + pillHeight + 4,
              right: AppSpacing.screenPadding,
              child: _CenterFab(
                size: fabSize,
                onTap: () => _showActionGrid(
                  context,
                  bottomOffset + pillHeight + 4 + fabSize + 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final String lang;
  final double pillHeight;
  final void Function(int) onTap;

  const _FloatingNavBar({
    required this.currentIndex,
    required this.lang,
    required this.pillHeight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: pillHeight,
      decoration: _pillDecoration,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: _NavSlot(
              icon: LucideIcons.house,
              label: Translations.t(lang, 'nav_home'),
              isActive: currentIndex == 0,
              onTap: () => onTap(0),
            ),
          ),
          Expanded(
            child: _NavSlot(
              icon: LucideIcons.compass,
              label: Translations.t(lang, 'nav_events'),
              isActive: currentIndex == 1,
              onTap: () => onTap(1),
            ),
          ),
          Expanded(
            child: _NavSlot(
              icon: LucideIcons.user,
              label: Translations.t(lang, 'nav_profile'),
              isActive: currentIndex == 2,
              onTap: () => onTap(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavSlot extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavSlot({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavSlot> createState() => _NavSlotState();
}

class _NavSlotState extends State<_NavSlot> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = widget.isActive ? 1.04 : (_pressed ? 0.94 : 1.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: Center(
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: widget.isActive ? 8 : 6,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? AppColors.primary.withValues(alpha: 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      widget.icon,
                      key: ValueKey('${widget.label}_${widget.isActive}'),
                      size: 22,
                      color: widget.isActive
                          ? AppColors.primaryDark
                          : AppColors.inactive,
                    ),
                  ),
                  if (widget.isActive) ...[
                    const SizedBox(width: 6),
                    Text(
                      widget.label,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.fade,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterFab extends StatefulWidget {
  final double size;
  final VoidCallback onTap;

  const _CenterFab({required this.size, required this.onTap});

  @override
  State<_CenterFab> createState() => _CenterFabState();
}

class _CenterFabState extends State<_CenterFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      reverseDuration: const Duration(milliseconds: 220),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.88)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.88, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 60,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _controller.forward(from: 0);
    widget.onTap();
    if (mounted) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: _handleTap,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: AppColors.textPrimary,
            shape: BoxShape.circle,
            boxShadow: AppShadows.fabShadow,
            border: Border.all(color: AppColors.surface, width: 3),
          ),
          child: Icon(
            LucideIcons.plus,
            size: 28,
            color: AppColors.surface,
          ),
        ),
      ),
    );
  }
}

BoxDecoration get _pillDecoration => BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.all(Radius.circular(999)),
      boxShadow: [
        BoxShadow(
          color: Color(0x1A000000),
          blurRadius: 24,
          spreadRadius: 0,
          offset: Offset(0, 6),
        ),
        BoxShadow(
          color: Color(0x0F000000),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    );

class _ActionGrid extends ConsumerWidget {
  final Animation<double> animation;

  const _ActionGrid({required this.animation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final gridWidth = screenWidth - 48;
    final cellWidth = (gridWidth - 10) / 2;

    final items = [
      (
        LucideIcons.footprints,
        Translations.t(lang, 'action_log_exercise'),
        () {
          Navigator.pop(context);
          context.push('/log_exercise');
        },
      ),
      (
        LucideIcons.scanLine,
        Translations.t(lang, 'action_scan_food'),
        () {
          Navigator.pop(context);
          context.go(RoutePaths.scan);
        },
      ),
      (
        LucideIcons.squarePen,
        Translations.t(lang, 'action_add_food_manually'),
        () {
          Navigator.pop(context);
          context.push('/food_database');
        },
      ),
      (
        LucideIcons.listTodo,
        Translations.t(lang, 'action_tasks'),
        () {
          Navigator.pop(context);
          context.push(RoutePaths.tasks);
        },
      ),
      (
        LucideIcons.images,
        'Body Journal',
        () {
          Navigator.pop(context);
          context.push(RoutePaths.progressPhotos);
        },
      ),
    ];

    return SizedBox(
      width: gridWidth,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: [
          for (var i = 0; i < items.length; i++)
            _StaggeredActionCell(
              animation: animation,
              index: i,
              icon: items[i].$1,
              label: items[i].$2,
              width: cellWidth,
              onTap: items[i].$3,
            ),
        ],
      ),
    );
  }
}

class _StaggeredActionCell extends StatelessWidget {
  final Animation<double> animation;
  final int index;
  final IconData icon;
  final String label;
  final double width;
  final VoidCallback onTap;

  const _StaggeredActionCell({
    required this.animation,
    required this.index,
    required this.icon,
    required this.label,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final start = (0.08 * index).clamp(0.0, 0.55);
    final end = (start + 0.45).clamp(0.0, 1.0);
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(start, end, curve: Curves.easeOutBack),
      reverseCurve: Interval(0.0, 1.0 - start, curve: Curves.easeInCubic),
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.25),
          end: Offset.zero,
        ).animate(curved),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.86, end: 1.0).animate(curved),
          child: _ActionCell(
            icon: icon,
            label: label,
            width: width,
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}

class _ActionCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final double width;
  final VoidCallback onTap;

  const _ActionCell({
    required this.icon,
    required this.label,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 130,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: AppColors.primaryDark),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
