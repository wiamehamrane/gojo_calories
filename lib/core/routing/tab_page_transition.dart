import 'package:flutter/cupertino.dart';
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

/// Pushed screens: Cupertino slide + interactive swipe-to-go-back.
Page<void> smoothPushPage({
  required GoRouterState state,
  required Widget child,
  bool fullscreenDialog = false,
}) {
  return SmoothSwipePage(
    key: state.pageKey,
    name: state.name,
    fullscreenDialog: fullscreenDialog,
    child: child,
  );
}

/// Page that enables the interactive edge back-swipe on every platform.
class SmoothSwipePage<T> extends Page<T> {
  const SmoothSwipePage({
    required this.child,
    this.fullscreenDialog = false,
    this.maintainState = true,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final Widget child;
  final bool fullscreenDialog;
  final bool maintainState;

  @override
  Route<T> createRoute(BuildContext context) {
    return _SmoothSwipePageRoute<T>(this);
  }
}

class _SmoothSwipePageRoute<T> extends PageRoute<T>
    with CupertinoRouteTransitionMixin<T> {
  _SmoothSwipePageRoute(SmoothSwipePage<T> page)
      : _page = page,
        super(settings: page);

  final SmoothSwipePage<T> _page;

  @override
  Widget buildContent(BuildContext context) => _page.child;

  @override
  String? get title => _page.name;

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 380);

  @override
  Duration get reverseTransitionDuration =>
      const Duration(milliseconds: 340);

  /// Force enable edge swipe-back (normally iOS/macOS only).
  @override
  bool get popGestureEnabled {
    if (_page.fullscreenDialog) return false;
    if (isFirst) return false;
    if (willHandlePopInternally) return false;
    if (animation?.status != AnimationStatus.completed) return false;
    return true;
  }
}

/// Smooth Cupertino route for imperative Navigator.push calls.
Route<T> smoothMaterialRoute<T>({required WidgetBuilder builder}) {
  return CupertinoPageRoute<T>(builder: builder);
}
