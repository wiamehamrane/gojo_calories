import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
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
    if (location.startsWith('/progress')) return 1;
    if (location.startsWith('/profile')) return 2;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    if (index == _calculateSelectedIndex(context)) return;
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/progress');
        break;
      case 2:
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
                        onTap:
                            () {}, // Blocks taps from closing the modal when clicking on the action grid itself
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
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final navBarHeight = AppSpacing.navHeight + bottomPadding;

    return Scaffold(
      body: Stack(
        children: [
          // Content
          Positioned.fill(
            bottom: navBarHeight,
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
          // Nav Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: navBarHeight,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                boxShadow: AppShadows.navShadow,
              ),
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavItem(
                    icon: LucideIcons.house,
                    label: Translations.t(lang, 'nav_home'),
                    isActive: currentIndex == 0,
                    isHomeTab: true,
                    onTap: () => _onItemTapped(0, context),
                  ),
                  _NavItem(
                    icon: LucideIcons.chartBar,
                    label: Translations.t(lang, 'nav_progress'),
                    isActive: currentIndex == 1,
                    onTap: () => _onItemTapped(1, context),
                  ),
                  _NavItem(
                    icon: LucideIcons.user,
                    label: Translations.t(lang, 'nav_profile'),
                    isActive: currentIndex == 2,
                    isProfileTab: true,
                    onTap: () => _onItemTapped(2, context),
                  ),
                ],
              ),
            ),
          ),
          // FAB
          if (currentIndex == 0)
            Positioned(
              bottom: navBarHeight + AppSpacing.fabMargin,
              right: Directionality.of(context) == TextDirection.rtl
                  ? null
                  : AppSpacing.fabMargin,
              left: Directionality.of(context) == TextDirection.rtl
                  ? AppSpacing.fabMargin
                  : null,
              child: GestureDetector(
                onTap: () => _showActionGrid(context),
                child: Container(
                  width: AppSpacing.fabSize,
                  height: AppSpacing.fabSize,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryDark,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.fabShadow,
                  ),
                  child: const Icon(
                    LucideIcons.plus,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isHomeTab;
  final bool isProfileTab;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    this.isHomeTab = false,
    this.isProfileTab = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget iconWidget;

    if (isProfileTab && isActive) {
      iconWidget = Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
        ),
      );
    } else {
      iconWidget = Icon(
        icon,
        size: 24,
        color: isActive ? AppColors.textPrimary : AppColors.inactive,
      );
    }

    if (isHomeTab && isActive) {
      iconWidget = Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(999),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: iconWidget,
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconWidget,
          const SizedBox(height: 4),
          Text(
            label,
            style: isActive
                ? AppTextStyles.navLabelActive
                : AppTextStyles.navLabelInactive,
          ),
        ],
      ),
    );
  }
}

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
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: AppColors.textPrimary),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
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
