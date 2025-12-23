import 'package:flutter/material.dart';

import '../../../domain/models/active_call_state_model.dart';

/// Visual indicator showing current call quality.
/// Displays signal bars similar to cellular signal strength.
class CallQualityIndicator extends StatelessWidget {
  final CallQuality quality;
  final bool showLabel;
  final double barWidth;
  final double maxBarHeight;

  const CallQualityIndicator({
    super.key,
    required this.quality,
    this.showLabel = false,
    this.barWidth = 4.0,
    this.maxBarHeight = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = _getColorForQuality(quality);
    final int activeBars = quality.signalBars;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        // Signal bars
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List<Widget>.generate(4, (int index) {
            final double barHeight =
                maxBarHeight * (0.4 + (index * 0.2));
            final bool isActive = index < activeBars;

            return Padding(
              padding:
                  EdgeInsets.only(right: index < 3 ? 2 : 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: barWidth,
                height: barHeight,
                decoration: BoxDecoration(
                  color: isActive
                      ? color
                      : Colors.white.withOpacity(0.2),
                  borderRadius:
                      BorderRadius.circular(barWidth / 2),
                ),
              ),
            );
          }),
        ),
        // Optional label
        if (showLabel) ...<Widget>[
          const SizedBox(width: 8),
          Text(
            quality.displayName,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Color _getColorForQuality(CallQuality quality) {
    switch (quality) {
      case CallQuality.excellent:
        return Colors.green;
      case CallQuality.good:
        return Colors.lightGreen;
      case CallQuality.fair:
        return Colors.orange;
      case CallQuality.poor:
        return Colors.red;
    }
  }
}

/// Animated pulse indicator for active call status.
class ActiveCallPulse extends StatefulWidget {
  final Color color;
  final double size;

  const ActiveCallPulse({
    super.key,
    this.color = Colors.green,
    this.size = 12.0,
  });

  @override
  State<ActiveCallPulse> createState() => _ActiveCallPulseState();
}

class _ActiveCallPulseState extends State<ActiveCallPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (BuildContext context, Widget? child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: widget.color
                    .withOpacity(_animation.value * 0.6),
                blurRadius:
                    widget.size * _animation.value,
                spreadRadius:
                    widget.size *
                        0.3 *
                        _animation.value,
              ),
            ],
          ),
        );
      },
    );
  }
}


