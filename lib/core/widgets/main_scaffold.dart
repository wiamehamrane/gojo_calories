import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../routing/route_paths.dart';
import '../localization/locale_provider.dart';
import '../localization/translations.dart';

class MainScaffold extends ConsumerWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

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
    if (index == _calculateSelectedIndex(context)) return;
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/events');
        break;
      case 2:
        context.go('/profile');
        break;
    }
  }

  void _showActionGrid(BuildContext context, double bottomOffset, double pillHeight) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: const Color(0x59000000),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                Positioned(
                  bottom: bottomOffset + pillHeight + 16,
                  left: 0,
                  right: 0,
                  child: ScaleTransition(
                    scale: CurvedAnimation(
                      parent: anim1,
                      curve: Curves.easeOutBack,
                    ),
                    child: FadeTransition(
                      opacity: anim1,
                      child: GestureDetector(
                        onTap: () {},
                        child: const Center(child: _ActionGrid()),
                      ),
                    ),
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
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    final int currentIndex = _calculateSelectedIndex(context);
    final bool isScan = _isScanRoute(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    const pillHeight = 56.0;
    const pillHMargin = 24.0;
    const fabSize = 60.0;
    final bottomOffset = bottomPadding + 16.0;
    final bool isHome = currentIndex == 0;

    return Scaffold(
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! < -300 && currentIndex < 2) {
                  _onItemTapped(currentIndex + 1, context);
                } else if (details.primaryVelocity! > 300 && currentIndex > 0) {
                  _onItemTapped(currentIndex - 1, context);
                }
              },
              child: child,
            ),
          ),

          if (!isScan)
            Positioned(
              bottom: bottomOffset,
              left: pillHMargin,
              right: pillHMargin,
              height: pillHeight + (isHome ? fabSize / 2 : 0),
              child: _FloatingNavBar(
                currentIndex: currentIndex,
                lang: lang,
                pillHeight: pillHeight,
                fabSize: fabSize,
                onTap: (i) => _onItemTapped(i, context),
                onPlusTap: () => _showActionGrid(context, bottomOffset, pillHeight),
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
  final double fabSize;
  final void Function(int) onTap;
  final VoidCallback onPlusTap;

  const _FloatingNavBar({
    required this.currentIndex,
    required this.lang,
    required this.pillHeight,
    required this.fabSize,
    required this.onTap,
    required this.onPlusTap,
  });

  bool get _isHome => currentIndex == 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          height: pillHeight,
          decoration: _pillDecoration,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _isHome ? _buildHomeRow() : _buildTabsRow(),
        ),
        if (_isHome)
          Positioned(
            bottom: pillHeight / 2 - fabSize / 2,
            child: _CenterFab(size: fabSize, onTap: onPlusTap),
          ),
      ],
    );
  }

  Widget _buildHomeRow() {
    return Row(
      children: [
        Expanded(
          child: _NavSlot(
            icon: LucideIcons.house,
            label: Translations.t(lang, 'nav_home'),
            isActive: true,
            onTap: () => onTap(0),
          ),
        ),
        SizedBox(width: fabSize + 4),
        Expanded(
          child: _NavSlot(
            icon: LucideIcons.user,
            label: Translations.t(lang, 'nav_profile'),
            isActive: false,
            onTap: () => onTap(2),
          ),
        ),
      ],
    );
  }

  Widget _buildTabsRow() {
    return Row(
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
            label: 'Events',
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
    );
  }
}

class _NavSlot extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isActive ? 16 : 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isActive ? AppColors.primaryDark : AppColors.inactive,
                ),
                if (isActive) ...[
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
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
    );
  }
}

class _CenterFab extends StatelessWidget {
  final double size;
  final VoidCallback onTap;

  const _CenterFab({required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
          boxShadow: AppShadows.fabShadow,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: const Icon(
          LucideIcons.plus,
          size: 28,
          color: Colors.white,
        ),
      ),
    );
  }
}

const _pillDecoration = BoxDecoration(
  color: Colors.white,
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
  const _ActionGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    final double screenWidth = MediaQuery.of(context).size.width;
    final double gridWidth = screenWidth - 48;
    final double cellWidth = (gridWidth - 10) / 2;

    return SizedBox(
      width: gridWidth,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: [
          _ActionCell(
            icon: LucideIcons.footprints,
            label: Translations.t(lang, 'action_log_exercise'),
            width: cellWidth,
            onTap: () {
              Navigator.pop(context);
              context.push('/log_exercise');
            },
          ),
          _ActionCell(
            icon: LucideIcons.bookmark,
            label: Translations.t(lang, 'action_saved_foods'),
            width: cellWidth,
            onTap: () {
              Navigator.pop(context);
              context.push('/saved_foods');
            },
          ),
          _ActionCell(
            icon: LucideIcons.search,
            label: Translations.t(lang, 'action_food_database'),
            width: cellWidth,
            onTap: () {
              Navigator.pop(context);
              context.push('/food_database');
            },
          ),
          _ActionCell(
            icon: LucideIcons.scanLine,
            label: Translations.t(lang, 'action_scan_food'),
            width: cellWidth,
            onTap: () {
              Navigator.pop(context);
              context.push('/scan');
            },
          ),
          _ActionCell(
            icon: LucideIcons.listTodo,
            label: Translations.t(lang, 'action_tasks'),
            width: cellWidth,
            onTap: () {
              Navigator.pop(context);
              context.push(RoutePaths.tasks);
            },
          ),
        ],
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
        color: Colors.white,
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
                style: const TextStyle(
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
