import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../storage/storage_keys.dart';

enum AppFloatingDismissDirection { rtl, ltr, ttb, btt }

class AppFloatingOptions {
  const AppFloatingOptions({
    this.showDuration = const Duration(seconds: 3),
    this.forwardDuration = const Duration(milliseconds: 520),
    this.reverseDuration = const Duration(milliseconds: 220),
    this.horizontalMargin = 16,
    this.topOffset = 8,
    this.allowedDirections = const {AppFloatingDismissDirection.rtl},
    this.enableHapticOnAppear = false,
  });

  final Duration showDuration;
  final Duration forwardDuration;
  final Duration reverseDuration;
  final double horizontalMargin;
  final double topOffset;
  final Set<AppFloatingDismissDirection> allowedDirections;
  final bool enableHapticOnAppear;
}

/// Global singleton manager for top floating overlays (one-at-a-time).
abstract final class AppFloating {
  AppFloating._();

  static OverlayEntry? _currentEntry;
  static AnimationController? _controller;
  static int _version = 0;

  static Set<AppFloatingDismissDirection> _defaultDirections = {
    AppFloatingDismissDirection.rtl,
  };
  static bool _defaultHapticOnAppear = false;

  static Set<AppFloatingDismissDirection> get defaultAllowedDirections =>
      Set<AppFloatingDismissDirection>.from(_defaultDirections);

  static void setDefaultAllowedDirections(
    Set<AppFloatingDismissDirection> directions,
  ) {
    if (directions.isEmpty) return;
    _defaultDirections = Set<AppFloatingDismissDirection>.from(directions);
  }

  static bool get defaultHapticOnAppear => _defaultHapticOnAppear;

  static void setDefaultHapticOnAppear(bool enabled) {
    _defaultHapticOnAppear = enabled;
  }

  static Future<void> show({
    required Widget child,
    AppFloatingOptions options = const AppFloatingOptions(),
  }) async {
    final navState = AppKeys.instance.navigatorKey.currentState;
    if (navState == null || !navState.mounted) return;
    final overlay = navState.overlay;
    if (overlay == null) return;
    final overlayContext = overlay.context;
    final myVersion = ++_version;
    final allowed = options.allowedDirections.isEmpty
        ? Set<AppFloatingDismissDirection>.from(_defaultDirections)
        : Set<AppFloatingDismissDirection>.from(options.allowedDirections);
    final hapticEnabled =
        options.enableHapticOnAppear || _defaultHapticOnAppear;

    await dismiss();

    final controller = AnimationController(
      vsync: navState,
      duration: options.forwardDuration,
      reverseDuration: options.reverseDuration,
    );
    _controller = controller;

    final curved = CurvedAnimation(
      parent: controller,
      curve: Curves.elasticOut,
      reverseCurve: Curves.easeInCubic,
    );
    final fade = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      reverseCurve: Curves.easeInCubic,
    );

    final dragOffset = ValueNotifier<Offset>(Offset.zero);
    final lockedDirection = ValueNotifier<AppFloatingDismissDirection?>(null);

    _currentEntry = OverlayEntry(
      builder: (_) {
        return Positioned(
          top: MediaQuery.of(overlayContext).padding.top + options.topOffset,
          left: options.horizontalMargin,
          right: options.horizontalMargin,
          child: ValueListenableBuilder<Offset>(
            valueListenable: dragOffset,
            builder: (context, drag, _) {
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanUpdate: (details) {
                  var locked = lockedDirection.value;
                  if (locked == null) {
                    locked = _pickDirectionLock(details.delta, allowed);
                    if (locked != null) lockedDirection.value = locked;
                  }
                  if (locked == null) return;
                  dragOffset.value = _projectInDirection(
                    drag + details.delta,
                    locked,
                  );
                },
                onPanCancel: () {
                  dragOffset.value = Offset.zero;
                  lockedDirection.value = null;
                },
                onPanEnd: (details) async {
                  final locked = lockedDirection.value;
                  if (locked == null) {
                    dragOffset.value = Offset.zero;
                    return;
                  }
                  final shouldDismiss = _shouldDismissByDistanceOrVelocity(
                    drag: dragOffset.value,
                    velocity: details.velocity.pixelsPerSecond,
                    direction: locked,
                  );
                  if (shouldDismiss) {
                    await dismiss(removeWithReverse: false);
                    return;
                  }
                  dragOffset.value = Offset.zero;
                  lockedDirection.value = null;
                },
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) {
                    final t = curved.value;
                    final scaleX = 0.15 + (0.85 * t);
                    final scaleY = 0.86 + (0.14 * t);
                    final y = -20.0 * (1 - t);
                    return Opacity(
                      opacity: fade.value.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(drag.dx, y + drag.dy),
                        child: Transform(
                          alignment: Alignment.topCenter,
                          transform: Matrix4.identity()
                            ..scaleByDouble(scaleX, scaleY, 1.0, 1.0),
                          child: Material(
                            color: Colors.transparent,
                            child: child,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );

    overlay.insert(_currentEntry!);
    try {
      await controller.forward(from: 0);
      if (hapticEnabled) {
        await HapticFeedback.lightImpact();
      }
    } catch (_) {}

    Future<void>.delayed(options.showDuration, () async {
      if (_version != myVersion) return;
      await dismiss();
    });
  }

  static Future<void> dismiss({bool removeWithReverse = true}) async {
    final ctrl = _controller;
    final entry = _currentEntry;
    if (ctrl == null || entry == null) return;
    _controller = null;
    _currentEntry = null;
    try {
      if (removeWithReverse && ctrl.status != AnimationStatus.dismissed) {
        await ctrl.reverse();
      }
    } catch (_) {
    } finally {
      entry.remove();
      ctrl.dispose();
    }
  }

  static AppFloatingDismissDirection? _pickDirectionLock(
    Offset delta,
    Set<AppFloatingDismissDirection> allowed,
  ) {
    if (delta.dx.abs() < 1 && delta.dy.abs() < 1) return null;
    if (allowed.isEmpty) return null;
    final horizontalDominant = delta.dx.abs() >= delta.dy.abs();
    if (horizontalDominant) {
      if (delta.dx < 0 && allowed.contains(AppFloatingDismissDirection.rtl)) {
        return AppFloatingDismissDirection.rtl;
      }
      if (delta.dx > 0 && allowed.contains(AppFloatingDismissDirection.ltr)) {
        return AppFloatingDismissDirection.ltr;
      }
    } else {
      if (delta.dy < 0 && allowed.contains(AppFloatingDismissDirection.btt)) {
        return AppFloatingDismissDirection.btt;
      }
      if (delta.dy > 0 && allowed.contains(AppFloatingDismissDirection.ttb)) {
        return AppFloatingDismissDirection.ttb;
      }
    }
    if (delta.dx < 0 && allowed.contains(AppFloatingDismissDirection.rtl)) {
      return AppFloatingDismissDirection.rtl;
    }
    if (delta.dx > 0 && allowed.contains(AppFloatingDismissDirection.ltr)) {
      return AppFloatingDismissDirection.ltr;
    }
    if (delta.dy < 0 && allowed.contains(AppFloatingDismissDirection.btt)) {
      return AppFloatingDismissDirection.btt;
    }
    if (delta.dy > 0 && allowed.contains(AppFloatingDismissDirection.ttb)) {
      return AppFloatingDismissDirection.ttb;
    }
    return null;
  }

  static Offset _projectInDirection(
    Offset raw,
    AppFloatingDismissDirection direction,
  ) {
    switch (direction) {
      case AppFloatingDismissDirection.rtl:
        return Offset(raw.dx.clamp(-1000.0, 0.0), 0);
      case AppFloatingDismissDirection.ltr:
        return Offset(raw.dx.clamp(0.0, 1000.0), 0);
      case AppFloatingDismissDirection.ttb:
        return Offset(0, raw.dy.clamp(0.0, 1000.0));
      case AppFloatingDismissDirection.btt:
        return Offset(0, raw.dy.clamp(-1000.0, 0.0));
    }
  }

  static bool _shouldDismissByDistanceOrVelocity({
    required Offset drag,
    required Offset velocity,
    required AppFloatingDismissDirection direction,
  }) {
    switch (direction) {
      case AppFloatingDismissDirection.rtl:
        return drag.dx <= -108.0 || velocity.dx <= -900.0;
      case AppFloatingDismissDirection.ltr:
        return drag.dx >= 108.0 || velocity.dx >= 900.0;
      case AppFloatingDismissDirection.ttb:
        return drag.dy >= 80.0 || velocity.dy >= 580.0;
      case AppFloatingDismissDirection.btt:
        return drag.dy <= -80.0 || velocity.dy <= -580.0;
    }
  }
}
