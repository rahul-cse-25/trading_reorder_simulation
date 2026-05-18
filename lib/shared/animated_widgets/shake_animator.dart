import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// =====================================================
/// HAPTIC TYPES
/// =====================================================
enum PremiumHapticType { none, selection, light, medium, heavy }

/// =====================================================
/// PremiumShake
/// =====================================================
class PremiumShake extends StatefulWidget {
  final Object? trigger;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? surfaceBorderRadius;
  final BorderSide? idleBorder;
  final BorderSide? premiumBorder;
  final LinearGradient? premiumGradient;
  final Color? negativeColor;
  final Color? positiveColor;
  final Color? idleColor;

  /// Glow config
  final Color? glowColor;
  final double glowBlurRadius;
  final double glowSpreadRadius;
  final double glowOpacity;

  final Color Function(double t)? childColorBuilder;

  /// Haptics
  final bool enableHaptic;
  final PremiumHapticType hapticType;

  /// Timing
  final Duration duration;
  final Duration? premiumHoldDuration;

  final Widget child;

  const PremiumShake._({
    super.key,
    required this.trigger,
    this.padding,
    this.surfaceBorderRadius,
    this.idleBorder,
    this.premiumBorder,
    this.premiumGradient,
    this.negativeColor,
    this.positiveColor,
    this.idleColor,
    this.glowColor,
    this.glowBlurRadius = 32,
    this.glowSpreadRadius = 8,
    this.glowOpacity = 0.45,
    this.childColorBuilder,
    this.enableHaptic = false,
    this.hapticType = PremiumHapticType.selection,
    this.duration = const Duration(milliseconds: 650),
    this.premiumHoldDuration,
    required this.child,
  });

  factory PremiumShake({
    Key? key,
    required Object? trigger,
    EdgeInsetsGeometry? padding,
    BorderRadius? surfaceBorderRadius,
    BorderSide? idleBorder,
    BorderSide? premiumBorder,
    LinearGradient? premiumGradient,
    Color? negativeColor,
    Color? positiveColor,
    Color? idleColor,
    Color? glowColor,
    double glowBlurRadius = 32,
    double glowSpreadRadius = 8,
    double glowOpacity = 0.45,
    Color Function(double t)? childColorBuilder,
    bool enableHaptic = false,
    PremiumHapticType hapticType = PremiumHapticType.selection,
    Duration duration = const Duration(milliseconds: 650),
    Duration? premiumHoldDuration,
    required Widget child,
  }) {
    return PremiumShake._(
      key: key,
      trigger: trigger,
      padding: padding,
      surfaceBorderRadius: surfaceBorderRadius,
      idleBorder: idleBorder,
      premiumBorder: premiumBorder,
      premiumGradient: premiumGradient,
      negativeColor: negativeColor,
      positiveColor: positiveColor,
      idleColor: idleColor,
      glowColor: glowColor,
      glowBlurRadius: glowBlurRadius,
      glowSpreadRadius: glowSpreadRadius,
      glowOpacity: glowOpacity,
      childColorBuilder: childColorBuilder,
      enableHaptic: enableHaptic,
      hapticType: hapticType,
      duration: duration,
      premiumHoldDuration: premiumHoldDuration,
      child: child,
    );
  }

  factory PremiumShake.card({
    Key? key,
    required Object? trigger,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 10,
    ),
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(24)),
    BorderSide idleBorder = const BorderSide(
      color: Color(0xFF6E6E6E),
      width: 1,
    ),
    BorderSide premiumBorder = const BorderSide(
      color: Color(0xFFFFE9A3),
      width: 1.4,
    ),
    LinearGradient gradient = const LinearGradient(
      colors: [Color(0xFF2B1055), Color(0xFFD4AF37)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    Color glowColor = const Color(0xFFD4AF37),
    double glowBlurRadius = 32,
    double glowSpreadRadius = 8,
    double glowOpacity = 0.45,
    bool enableHaptic = true,
    PremiumHapticType hapticType = PremiumHapticType.medium,
    Duration duration = const Duration(milliseconds: 650),
    Duration? premiumHoldDuration,
    required Widget child,
  }) {
    return PremiumShake._(
      key: key,
      trigger: trigger,
      padding: padding,
      surfaceBorderRadius: borderRadius,
      idleBorder: idleBorder,
      premiumBorder: premiumBorder,
      premiumGradient: gradient,
      glowColor: glowColor,
      glowBlurRadius: glowBlurRadius,
      glowSpreadRadius: glowSpreadRadius,
      glowOpacity: glowOpacity,
      enableHaptic: enableHaptic,
      hapticType: hapticType,
      duration: duration,
      premiumHoldDuration: premiumHoldDuration,
      child: child,
    );
  }

  @override
  State<PremiumShake> createState() => _PremiumShakeState();
}

/// =====================================================
/// STATE
/// =====================================================
class _PremiumShakeState extends State<PremiumShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shake;
  late final Animation<double> _rotation;
  late final Animation<double> _scale;
  late final Animation<double> _flash;

  Object? _lastTrigger;
  bool _isIncrease = false;
  bool _isDecrease = false;
  bool _hapticPlayed = false;

  @override
  void initState() {
    super.initState();
    _lastTrigger = widget.trigger;

    _controller = AnimationController(vsync: this, duration: widget.duration);

    _shake = _springShake(_controller);
    _rotation = _springRotation(_controller);
    _scale = _springScale(_controller);
    _flash = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void didUpdateWidget(covariant PremiumShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != _lastTrigger) {
      final oldTrigger = _lastTrigger;
      _lastTrigger = widget.trigger;

      if (widget.trigger is num && oldTrigger is num) {
        final current = widget.trigger as num;
        final last = oldTrigger;
        _isIncrease = current > last;
        _isDecrease = current < last;
      } else {
        _isIncrease = false;
        _isDecrease = false;
      }

      _play();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    if (_controller.isAnimating) return;
    await _controller.forward(from: 0);
    if (widget.premiumHoldDuration != null) {
      await Future.delayed(widget.premiumHoldDuration!);
    }
    if (mounted) await _controller.reverse();
  }

  void _triggerHaptic() {
    if (!widget.enableHaptic) return;
    switch (widget.hapticType) {
      case PremiumHapticType.light:
        HapticFeedback.lightImpact();
        break;
      case PremiumHapticType.medium:
        HapticFeedback.mediumImpact();
        break;
      case PremiumHapticType.heavy:
        HapticFeedback.heavyImpact();
        break;
      case PremiumHapticType.selection:
        HapticFeedback.selectionClick();
        break;
      case PremiumHapticType.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.surfaceBorderRadius ?? BorderRadius.zero;

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        final t = _flash.value;

        /// 🔔 Haptic once at peak
        if (widget.enableHaptic && !_hapticPlayed && t > 0.6) {
          _hapticPlayed = true;
          _triggerHaptic();
        }
        if (t == 0) _hapticPlayed = false;

        return Transform.translate(
          offset: Offset(_shake.value, 0),
          child: Transform.rotate(
            angle: _rotation.value,
            child: Transform.scale(
              scale: _scale.value,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  /// OUTER GLOW
                  if (widget.glowColor != null && t > 0)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: radius,
                            boxShadow: [
                              BoxShadow(
                                color: widget.glowColor!.withValues(
                                  alpha: widget.glowOpacity * t,
                                ),
                                blurRadius: widget.glowBlurRadius * t,
                                spreadRadius: widget.glowSpreadRadius * t,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  /// MAIN SURFACE
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      gradient:
                          widget.premiumGradient != null && t > 0
                              ? LinearGradient(
                                colors:
                                    widget.premiumGradient!.colors
                                        .map(
                                          (c) => c.withValues(alpha: 0.9 * t),
                                        )
                                        .toList(),
                                begin: widget.premiumGradient!.begin,
                                end: widget.premiumGradient!.end,
                              )
                              : null,
                      border: Border.fromBorderSide(
                        BorderSide.lerp(
                          widget.idleBorder ?? BorderSide.none,
                          widget.premiumBorder ?? BorderSide.none,
                          t,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: widget.padding ?? EdgeInsets.zero,
                      child: Padding(
                        padding: widget.padding ?? EdgeInsets.zero,
                        child:
                            (widget.childColorBuilder != null ||
                                    widget.positiveColor != null ||
                                    widget.negativeColor != null)
                                ? DefaultTextStyle.merge(
                                  style: TextStyle(
                                    color: () {
                                      if (widget.childColorBuilder != null) {
                                        return widget.childColorBuilder!(t);
                                      }

                                      final targetColor =
                                          _isIncrease
                                              ? widget.positiveColor
                                              : _isDecrease
                                              ? widget.negativeColor
                                              : null;

                                      final baseColor =
                                          widget.idleColor ??
                                          DefaultTextStyle.of(
                                            context,
                                          ).style.color ??
                                          const Color(
                                            0xFFD4AF37,
                                          ); // Fallback to Gold

                                      if (targetColor != null && t > 0) {
                                        return Color.lerp(
                                          baseColor,
                                          targetColor,
                                          t,
                                        );
                                      }

                                      return baseColor;
                                    }(),
                                  ),
                                  child: widget.child,
                                )
                                : widget.child,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// =====================================================
/// SPRING HELPERS
/// =====================================================
Animation<double> _springShake(AnimationController c) {
  return TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: -16), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -16, end: 14), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 14, end: -8), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -8, end: 4), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 4, end: 0), weight: 1),
  ]).animate(CurvedAnimation(parent: c, curve: Curves.easeOutCubic));
}

Animation<double> _springRotation(AnimationController c) {
  return TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.03), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -0.03, end: 0.0), weight: 2),
  ]).animate(CurvedAnimation(parent: c, curve: Curves.easeOutCubic));
}

Animation<double> _springScale(AnimationController c) {
  return TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.06), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 1.06, end: 1.0), weight: 2),
  ]).animate(CurvedAnimation(parent: c, curve: Curves.easeOut));
}
