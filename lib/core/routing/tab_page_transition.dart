import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum TabSlideDirection {
  /// Next tab (swipe left).
  forward,

  /// Previous tab (swipe right).
  backward,

  /// Soft cross-fade when direction is unknown.
  none,
}

TabSlideDirection pendingTabSlideDirection = TabSlideDirection.none;

void prepareTabSlide({required int fromIndex, required int toIndex}) {
  if (fromIndex < 0 || toIndex < 0 || fromIndex == toIndex) {
    pendingTabSlideDirection = TabSlideDirection.none;
    return;
  }
  pendingTabSlideDirection =
      toIndex > fromIndex ? TabSlideDirection.forward : TabSlideDirection.backward;
}

TabSlideDirection consumeTabSlideDirection() {
  final direction = pendingTabSlideDirection;
  pendingTabSlideDirection = TabSlideDirection.none;
  return direction;
}

/// Soft shared-axis transition for bottom-nav tabs.
CustomTransitionPage<void> tabTransitionPage({
  required GoRouterState state,
  required Widget child,
}) {
  final direction = consumeTabSlideDirection();

  final Offset enterBegin;
  final Offset exitEnd;
  switch (direction) {
    case TabSlideDirection.forward:
      enterBegin = const Offset(0.1, 0);
      exitEnd = const Offset(-0.06, 0);
      break;
    case TabSlideDirection.backward:
      enterBegin = const Offset(-0.1, 0);
      exitEnd = const Offset(0.06, 0);
      break;
    case TabSlideDirection.none:
      enterBegin = Offset.zero;
      exitEnd = Offset.zero;
      break;
  }

  return CustomTransitionPage<void>(
    key: state.pageKey,
    name: state.name,
    child: child,
    transitionDuration: const Duration(milliseconds: 360),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final enter = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final exit = CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: const Interval(0.0, 0.7)),
        ),
        child: SlideTransition(
          position: Tween<Offset>(begin: Offset.zero, end: exitEnd).animate(exit),
          child: SlideTransition(
            position:
                Tween<Offset>(begin: enterBegin, end: Offset.zero).animate(enter),
            child: child,
          ),
        ),
      );
    },
  );
}

/// Gentle rise + fade for pushed screens across the app.
CustomTransitionPage<void> smoothPushPage({
  required GoRouterState state,
  required Widget child,
  bool fullscreenDialog = false,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    name: state.name,
    child: child,
    fullscreenDialog: fullscreenDialog,
    transitionDuration: const Duration(milliseconds: 340),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.04, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
