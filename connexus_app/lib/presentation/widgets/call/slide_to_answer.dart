import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/call_colors.dart';

/// A slide-to-answer button that prevents accidental answers.
class SlideToAnswer extends StatefulWidget {
  final VoidCallback onAnswer;
  final double width;
  final double height;

  const SlideToAnswer({
    super.key,
    required this.onAnswer,
    this.width = 300,
    this.height = 64,
  });

  @override
  State<SlideToAnswer> createState() => _SlideToAnswerState();
}

class _SlideToAnswerState extends State<SlideToAnswer>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0;
  bool _isDragging = false;
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  double get _maxDrag => widget.width - widget.height;
  double get _dragPercent => (_dragPosition / _maxDrag).clamp(0.0, 1.0);
  bool get _isComplete => _dragPercent >= 0.95;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
    HapticFeedback.lightImpact();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, _maxDrag);
    });

    // Haptic feedback at 50% and 90%.
    if (_dragPercent >= 0.5 && _dragPercent < 0.52) {
      HapticFeedback.mediumImpact();
    } else if (_dragPercent >= 0.9 && _dragPercent < 0.92) {
      HapticFeedback.heavyImpact();
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (_isComplete) {
      // Trigger answer.
      HapticFeedback.heavyImpact();
      widget.onAnswer();
    } else {
      // Animate back to start.
      setState(() {
        _isDragging = false;
        _dragPosition = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: CallColors.slideTrack,
        borderRadius: BorderRadius.circular(widget.height / 2),
        border: Border.all(
          color: CallColors.answerGreen.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          // Shimmer effect text.
          Positioned.fill(
            child: Center(
              child: AnimatedBuilder(
                animation: _shimmerAnimation,
                builder: (context, child) {
                  return ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          CallColors.secondaryText,
                          CallColors.primaryText,
                          CallColors.secondaryText,
                        ],
                        stops: [
                          (_shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
                          _shimmerAnimation.value.clamp(0.0, 1.0),
                          (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
                        ],
                      ).createShader(bounds);
                    },
                    child: const Text(
                      'Slide to answer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Progress fill.
          AnimatedContainer(
            duration:
                _isDragging ? Duration.zero : const Duration(milliseconds: 200),
            width: _dragPosition + widget.height,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  CallColors.answerGreen.withOpacity(0.3),
                  CallColors.answerGreen.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(widget.height / 2),
            ),
          ),

          // Draggable thumb.
          AnimatedPositioned(
            duration:
                _isDragging ? Duration.zero : const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            left: _dragPosition,
            top: 0,
            child: GestureDetector(
              onHorizontalDragStart: _onDragStart,
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              child: Container(
                width: widget.height,
                height: widget.height,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isComplete
                      ? CallColors.answerGreenLight
                      : CallColors.answerGreen,
                  boxShadow: [
                    BoxShadow(
                      color: CallColors.answerGreen.withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  _isComplete ? Icons.check : Icons.phone,
                  color: CallColors.slideThumbIcon,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
