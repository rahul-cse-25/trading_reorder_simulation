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

class _SlideToConfirmState extends State<SlideToConfirm> with SingleTickerProviderStateMixin {
  double _position = 0.0;
  bool _isConfirmed = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void didUpdateWidget(SlideToConfirm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset the slider if it gets disabled (e.g., when quantity clears after a successful trade)
    if (oldWidget.isEnabled && !widget.isEnabled) {
      setState(() {
        _position = 0.0;
        _isConfirmed = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, double maxWidth) {
    if (!widget.isEnabled || _isConfirmed) return;

    setState(() {
      _position += details.delta.dx;
      if (_position < 0) _position = 0;
      if (_position > maxWidth - 60) _position = maxWidth - 60;
    });

    // Provide haptic feedback as it nears completion
    if (_position > (maxWidth - 60) * 0.8) {
      HapticFeedback.selectionClick();
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details, double maxWidth) {
    if (!widget.isEnabled || _isConfirmed) return;

    if (_position > maxWidth - 100) {
      setState(() {
        _position = maxWidth - 60;
        _isConfirmed = true;
      });
      HapticFeedback.mediumImpact();
      widget.onConfirm();
    } else {
      setState(() {
        _position = 0;
      });
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final color = widget.isEnabled ? widget.color : Colors.white10;

        return Opacity(
          opacity: widget.isEnabled ? 1.0 : 0.5,
          child: Container(
            height: 64,
            width: maxWidth,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white10),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.isEnabled ? Colors.white38 : Colors.white10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Positioned(
                  left: _position + 4,
                  top: 4,
                  bottom: 4,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragUpdate: (details) => _onHorizontalDragUpdate(details, maxWidth),
                    onHorizontalDragEnd: (details) => _onHorizontalDragEnd(details, maxWidth),
                    child: Container(
                      width: 56,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (widget.isEnabled)
                            BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                        ],
                      ),
                      child: Icon(
                        _isConfirmed ? Icons.check : Icons.keyboard_arrow_right_rounded,
                        color: Colors.black,
                        size: 32,
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
}
