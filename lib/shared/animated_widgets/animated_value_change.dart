import 'package:flutter/material.dart';

typedef AnimatedValueBuilder =
    Widget Function(BuildContext context, double value, Color? color);

class AnimatedValue extends StatefulWidget {
  final double value;
  final Duration duration;
  final Duration colorDuration;
  final Curve curve;

  /// Optional colors → if null, color animation is disabled
  final Color? increaseColor;
  final Color? decreaseColor;
  final Color? idleColor;

  final AnimatedValueBuilder builder;

  const AnimatedValue({
    super.key,
    required this.value,
    required this.builder,
    this.duration = const Duration(milliseconds: 500),
    this.colorDuration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOut,
    this.increaseColor,
    this.decreaseColor,
    this.idleColor,
  });

  bool get _enableColor =>
      increaseColor != null && decreaseColor != null && idleColor != null;

  @override
  State<AnimatedValue> createState() => _AnimatedValueState();
}

class _AnimatedValueState extends State<AnimatedValue>
    with TickerProviderStateMixin {
  late AnimationController _valueController;
  AnimationController? _colorController;

  late Animation<double> _valueAnimation;
  Animation<Color?>? _colorAnimation;

  double _previousValue = 0;

  bool get _useColor => widget._enableColor;

  @override
  void initState() {
    super.initState();

    _previousValue = widget.value;

    _valueController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _valueAnimation = AlwaysStoppedAnimation(widget.value);

    if (_useColor) {
      _colorController = AnimationController(
        vsync: this,
        duration: widget.colorDuration,
      );

      _colorAnimation = AlwaysStoppedAnimation(widget.idleColor);

      _valueController.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _fadeBackToIdle();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedValue oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value) {
      _animate(widget.value);
    }
  }

  void _animate(double newValue) {
    final currentValue = _valueAnimation.value;

    // 🔥 VALUE ANIMATION
    _valueAnimation = Tween<double>(
      begin: currentValue,
      end: newValue,
    ).animate(CurvedAnimation(parent: _valueController, curve: widget.curve));

    _valueController
      ..stop()
      ..reset()
      ..forward();

    if (!_useColor) return;

    _colorController?.stop();

    // 🔥 DIRECTION DETECTION
    Color targetColor;
    if (newValue > _previousValue) {
      targetColor = widget.increaseColor!;
    } else if (newValue < _previousValue) {
      targetColor = widget.decreaseColor!;
    } else {
      targetColor = widget.idleColor!;
    }

    final currentColor = _colorAnimation?.value ?? widget.idleColor!;

    _colorAnimation = ColorTween(
      begin: currentColor,
      end: targetColor,
    ).animate(_colorController!);

    _colorController!
      ..reset()
      ..forward();

    _previousValue = newValue;
  }

  void _fadeBackToIdle() {
    if (!_useColor) return;

    final currentColor = _colorAnimation?.value ?? widget.idleColor!;

    _colorAnimation = ColorTween(
      begin: currentColor,
      end: widget.idleColor!,
    ).animate(_colorController!);

    _colorController!
      ..stop()
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final listenable =
        _useColor
            ? Listenable.merge([_valueController, _colorController!])
            : _valueController;

    return AnimatedBuilder(
      animation: listenable,
      builder: (_, _) {
        return widget.builder(
          context,
          _valueAnimation.value,
          _useColor ? _colorAnimation?.value : null,
        );
      },
    );
  }

  @override
  void dispose() {
    _valueController.dispose();
    _colorController?.dispose();
    super.dispose();
  }
}
