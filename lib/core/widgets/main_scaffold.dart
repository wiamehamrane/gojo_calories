import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_shadows.dart';
import '../providers/locale_provider.dart';
import '../localization/translations.dart';

class MainScaffold extends ConsumerWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  static int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/profile')) return 1;
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
        context.go('/profile');
        break;
    }
  }

  void _showActionGrid(BuildContext context) {
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
                  bottom:
                      AppSpacing.navHeight +
                      AppSpacing.fabMargin +
                      MediaQuery.of(context).padding.bottom,
                  right: Directionality.of(context) == TextDirection.rtl
                      ? null
                      : AppSpacing.fabMargin,
                  left: Directionality.of(context) == TextDirection.rtl
                      ? AppSpacing.fabMargin
                      : null,
                  child: ScaleTransition(
                    scale: CurvedAnimation(
                      parent: anim1,
                      curve: Curves.easeOutBack,
                    ),
                    child: FadeTransition(
                      opacity: anim1,
                      child: GestureDetector(
                        onTap: () {},
                        child: _ActionGrid(),
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

    // Nav pill height: 58 fixed + safe area
    const pillHeight = 58.0;
    const pillHMargin = 20.0;
    final bottomOffset = bottomPadding + 14.0;

    return Scaffold(
      body: Stack(
        children: [
          // ── Content fills whole screen ──────────────────────────────
          Positioned.fill(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! < -300 && currentIndex < 1) {
                  _onItemTapped(currentIndex + 1, context);
                } else if (details.primaryVelocity! > 300 && currentIndex > 0) {
                  _onItemTapped(currentIndex - 1, context);
                }
              },
              child: child,
            ),
          ),

          // ── Floating Pill Navbar ────────────────────────────────────
          if (!isScan)
            Positioned(
              bottom: bottomOffset,
              left: pillHMargin,
              right: pillHMargin,
              height: pillHeight,
              child: _FloatingNavBar(
                currentIndex: currentIndex,
                lang: lang,
                onTap: (i) => _onItemTapped(i, context),
              ),
            ),

          // ── FAB (only on home, not on scan) ────────────────────────
          if (currentIndex == 0 && !isScan)
            Positioned(
              bottom: bottomOffset + pillHeight / 2 - AppSpacing.fabSize / 2,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _showActionGrid(context),
                  child: Container(
                    width: AppSpacing.fabSize,
                    height: AppSpacing.fabSize,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.fabShadow,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.plus,
                      size: 26,
                      color: Colors.white,
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

// ─── Floating Nav Bar Widget ──────────────────────────────────────────────

class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final String lang;
  final void Function(int) onTap;

  const _FloatingNavBar({
    required this.currentIndex,
    required this.lang,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _PillNavItem(
            icon: LucideIcons.house,
            label: Translations.t(lang, 'nav_home'),
            isActive: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _PillNavItem(
            icon: LucideIcons.user,
            label: Translations.t(lang, 'nav_profile'),
            isActive: currentIndex == 1,
            onTap: () => onTap(1),
          ),
        ],
      ),
    );
  }
}

class _PillNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _PillNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? AppColors.primaryDark : AppColors.inactive,
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: isActive
                    ? Row(
                        children: [
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Action Grid ─────────────────────────────────────────────────────────

class _ActionGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    final double screenWidth = MediaQuery.of(context).size.width;
    final double cellWidth = (screenWidth - 32 - 10) / 2;

    return SizedBox(
      width: screenWidth - 32,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.end,
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
