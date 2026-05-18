import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SlideToConfirm extends StatefulWidget {
  final String label;
  final VoidCallback onConfirm;
  final Color color;
  final bool isEnabled;

  const SlideToConfirm({
    super.key,
    required this.label,
    required this.onConfirm,
    this.color = Colors.greenAccent,
    this.isEnabled = true,
  });

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm>
    with TickerProviderStateMixin {
  // Thumb position as a fraction [0.0, 1.0] of the available travel distance
  double _progress = 0.0;
  bool _isConfirmed = false;
  bool _isDragging = false;
  bool _hapticFired = false;

  // For snap-back spring animation after releasing below threshold
  late AnimationController _snapBackController;
  late Animation<double> _snapBackAnimation;

  // For snap-forward + lock animation on confirm
  late AnimationController _snapForwardController;
  late Animation<double> _snapForwardAnimation;

  static const double _thumbSize = 52.0;
  static const double _trackHeight = 64.0;
  static const double _padding = 6.0;

  // Travel = track width - thumb - 2*padding  (computed per layout)
  static const double _confirmThreshold = 0.82; // fire confirm at 82% travel
  static const double _hapticThreshold = 0.70; // haptic hint at 70%

  @override
  void initState() {
    super.initState();

    _snapBackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _snapForwardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _snapBackAnimation = CurvedAnimation(
      parent: _snapBackController,
      curve: Curves.elasticOut,
    );

    _snapForwardAnimation = CurvedAnimation(
      parent: _snapForwardController,
      curve: Curves.easeOut,
    );

    _snapBackController.addListener(() {
      if (!mounted) return;
      setState(() {
        _progress = (1.0 - _snapBackAnimation.value) * _progress;
      });
    });

    _snapForwardController.addListener(() {
      if (!mounted) return;
      setState(() {
        _progress = _snapForwardAnimation.value;
      });
    });
  }

  @override
  void didUpdateWidget(SlideToConfirm oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reset fully when disabled or color changed (trade type switched)
    final shouldReset =
        (oldWidget.isEnabled && !widget.isEnabled) ||
        oldWidget.color != widget.color ||
        (!oldWidget.isEnabled && widget.isEnabled && _isConfirmed);

    if (shouldReset) {
      _reset();
    }

    // Also reset when re-enabled after confirm (e.g. qty was cleared and re-entered)
    if (_isConfirmed && widget.isEnabled && !oldWidget.isEnabled) {
      _reset();
    }
  }

  void _reset() {
    _snapBackController.stop();
    _snapForwardController.stop();
    if (mounted) {
      setState(() {
        _progress = 0.0;
        _isConfirmed = false;
        _isDragging = false;
        _hapticFired = false;
      });
    }
  }

  @override
  void dispose() {
    _snapBackController.dispose();
    _snapForwardController.dispose();
    super.dispose();
  }

  double _travelWidth(double trackWidth) =>
      trackWidth - _thumbSize - _padding * 2;

  void _onDragStart(DragStartDetails details) {
    if (!widget.isEnabled || _isConfirmed) return;
    _snapBackController.stop();
    _snapForwardController.stop();
    setState(() => _isDragging = true);
  }

  void _onDragUpdate(DragUpdateDetails details, double trackWidth) {
    if (!widget.isEnabled || _isConfirmed) return;
    final travel = _travelWidth(trackWidth);
    if (travel <= 0) return;

    setState(() {
      _progress = (_progress + details.primaryDelta! / travel).clamp(0.0, 1.0);
    });

    // One-shot haptic as thumb nears confirm
    if (_progress >= _hapticThreshold && !_hapticFired) {
      _hapticFired = true;
      HapticFeedback.selectionClick();
    }
    if (_progress < _hapticThreshold) {
      _hapticFired = false;
    }
  }

  void _onDragEnd(DragEndDetails details, double trackWidth) {
    if (!widget.isEnabled || _isConfirmed) return;
    setState(() => _isDragging = false);

    if (_progress >= _confirmThreshold) {
      _confirmAction();
    } else {
      _snapBack();
    }
  }

  void _confirmAction() {
    // Snap thumb to 100% visually, lock, then fire callback
    final startProgress = _progress;
    _snapForwardAnimation = Tween<double>(begin: startProgress, end: 1.0)
        .animate(
          CurvedAnimation(
            parent: _snapForwardController,
            curve: Curves.easeOut,
          ),
        );
    _snapForwardController.addListener(() {
      if (!mounted) return;
      setState(() => _progress = _snapForwardAnimation.value);
    });
    _snapForwardController.forward(from: 0).then((_) {
      if (!mounted) return;
      setState(() => _isConfirmed = true);
      HapticFeedback.mediumImpact();
      widget.onConfirm();
    });
  }

  void _snapBack() {
    // Spring-back to 0 from current position
    final startProgress = _progress;
    _snapBackAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _snapBackController, curve: Curves.elasticOut),
    );
    _snapBackController.addListener(() {
      if (!mounted) return;
      setState(
        () => _progress = startProgress * (1.0 - _snapBackAnimation.value),
      );
    });
    _snapBackController.forward(from: 0);
    _hapticFired = false;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        final travel = _travelWidth(trackWidth);
        final thumbLeft = _padding + (_progress * travel);

        final isActive = widget.isEnabled;
        final thumbColor = isActive ? widget.color : Colors.white12;
        final trackColor = isActive
            ? widget.color.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.04);
        final labelColor = isActive
            ? (_progress > 0.15 ? Colors.transparent : Colors.white38)
            : Colors.white12;

        return SizedBox(
          height: _trackHeight,
          width: trackWidth,
          child: Stack(
            alignment: Alignment.centerLeft,
            clipBehavior: Clip.none,
            children: [
              // ── Track background ──
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: trackColor,
                    borderRadius: BorderRadius.circular(_trackHeight / 2),
                    border: Border.all(
                      color: isActive
                          ? widget.color.withValues(
                              alpha: _isConfirmed ? 0.5 : 0.2,
                            )
                          : Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
              ),

              // ── Label (fades as thumb moves) ──
              Positioned.fill(
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _isConfirmed
                        ? 0.0
                        : (1.0 - (_progress / 0.3).clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 80),
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        color: labelColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

              // ── Confirm label (fades in on success) ──
              if (_isConfirmed)
                Positioned.fill(
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_rounded,
                          color: widget.color,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ORDER PLACED',
                          style: TextStyle(
                            color: widget.color,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Draggable Thumb ──
              Positioned(
                left: thumbLeft,
                top: _padding,
                bottom: _padding,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: _onDragStart,
                  onHorizontalDragUpdate: (d) => _onDragUpdate(d, trackWidth),
                  onHorizontalDragEnd: (d) => _onDragEnd(d, trackWidth),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: _thumbSize,
                    decoration: BoxDecoration(
                      color: thumbColor,
                      borderRadius: BorderRadius.circular(_thumbSize / 2),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: widget.color.withValues(
                                  alpha: _isDragging ? 0.45 : 0.25,
                                ),
                                blurRadius: _isDragging ? 18 : 10,
                                spreadRadius: _isDragging ? 1 : 0,
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _isConfirmed
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.black,
                              size: 22,
                              key: ValueKey('check'),
                            )
                          : Icon(
                              Icons.keyboard_double_arrow_right_rounded,
                              color: isActive ? Colors.black87 : Colors.white24,
                              size: 22,
                              key: const ValueKey('arrow'),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
