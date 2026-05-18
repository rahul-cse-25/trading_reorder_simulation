import 'package:flutter/material.dart';

enum AnimationType {
  none,
  slide,
  fade,
}

enum NavSlideDirection {
  ltr,
  rtl,
  ttb,
  btt,
}

/// =====================================================
/// NAVIGATION EXTENSION
/// =====================================================

extension NavigationEx on BuildContext {

  Future<T?> push<T>(
      Widget screen, {
        AnimationType animation = AnimationType.none,
        NavSlideDirection direction = NavSlideDirection.rtl,
        Duration duration = const Duration(milliseconds: 200),
        bool replace = false,
        bool clearStack = false,
        bool useRootNavigator = false,
        bool fullscreenDialog = false,
      }) {
    final Route<T> route = _staticBuildRoute<T>(
      screen,
      animation,
      direction,
      duration,
      fullscreenDialog: fullscreenDialog,
    );

    final navigator = Navigator.of(this, rootNavigator: useRootNavigator);

    if (clearStack) {
      return navigator.pushAndRemoveUntil<T>(route, (_) => false);
    }

    if (replace) {
      return navigator.pushReplacement<T, T?>(route);
    }

    return navigator.push<T>(route);
  }

  void pop<T extends Object?>([T? result, bool useRootNavigator = false]) {
    Navigator.of(this, rootNavigator: useRootNavigator).pop<T>(result);
  }

  /// =====================================================
  /// BUY/SELL MODAL SHORTCUT
  /// =====================================================
  ///
  /// Static version for cases where you only have [NavigatorState] (e.g. SessionService)
  static Route<T> buildRoute<T>(
      Widget screen, {
        AnimationType animation = AnimationType.none,
        NavSlideDirection direction = NavSlideDirection.rtl,
        Duration duration = const Duration(milliseconds: 200),
        bool fullscreenDialog = false,
      }) {
    return _staticBuildRoute<T>(
      screen,
      animation,
      direction,
      duration,
      fullscreenDialog: fullscreenDialog,
    );
  }

  static Route<T> _staticBuildRoute<T>(
      Widget screen,
      AnimationType animation,
      NavSlideDirection direction,
      Duration duration, {
        bool fullscreenDialog = false,
      }) {
    final settings = RouteSettings(
      name: screen.runtimeType.toString(),
    );

    if (animation == AnimationType.none) {
      return PageRouteBuilder<T>(
        settings: settings,
        transitionDuration: duration,
        reverseTransitionDuration: const Duration(milliseconds: 150),
        fullscreenDialog: fullscreenDialog,
        pageBuilder: (_, _, _) => screen,
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: child,
          );
        },
      );
    }

    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: const Duration(milliseconds: 150),
      fullscreenDialog: fullscreenDialog,
      pageBuilder: (_, _, _) => screen,
      transitionsBuilder: (_, anim, _, child) {
        switch (animation) {
          case AnimationType.fade:
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: anim,
                curve: Curves.easeOut,
              ),
              child: child,
            );

          case AnimationType.slide:
            return SlideTransition(
              position: anim.drive(
                Tween<Offset>(
                  begin: _staticSlideOffset(direction),
                  end: Offset.zero,
                ).chain(
                  CurveTween(curve: Curves.fastOutSlowIn),
                ),
              ),
              child: child,
            );

          case AnimationType.none:
            return child;
        }
      },
    );
  }

  static Offset _staticSlideOffset(NavSlideDirection direction) {
    switch (direction) {
      case NavSlideDirection.ltr:
        return const Offset(-1, 0);
      case NavSlideDirection.rtl:
        return const Offset(1, 0);
      case NavSlideDirection.ttb:
        return const Offset(0, -1);
      case NavSlideDirection.btt:
        return const Offset(0, 1);
    }
  }
}