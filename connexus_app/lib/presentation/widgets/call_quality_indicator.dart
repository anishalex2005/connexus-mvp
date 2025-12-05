/// Widget for displaying call quality indicators during active calls.
///
/// Shows a visual representation of call quality with icons and colors
/// that update in real-time based on WebRTC metrics.
library;

import 'package:flutter/material.dart';

import '../../data/models/call_quality_metrics.dart';

/// A widget that displays the current call quality level.
class CallQualityIndicator extends StatelessWidget {
  /// The current quality metrics to display.
  final CallQualityMetrics? metrics;

  /// Whether to show detailed metrics (RTT, jitter, loss).
  final bool showDetails;

  /// Size of the indicator icon.
  final double iconSize;

  /// Callback when the indicator is tapped (to show details).
  final VoidCallback? onTap;

  const CallQualityIndicator({
    super.key,
    required this.metrics,
    this.showDetails = false,
    this.iconSize = 24.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final CallQualityLevel level =
        metrics?.qualityLevel ?? CallQualityLevel.good;
    final int score = metrics?.qualityScore ?? 100;
    final Color color = Color(level.colorValue);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildSignalIcon(level, color),
            if (showDetails) ...<Widget>[
              const SizedBox(width: 8),
              _buildDetailsColumn(color),
            ] else ...<Widget>[
              const SizedBox(width: 4),
              Text(
                level.displayName,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '$score',
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSignalIcon(CallQualityLevel level, Color color) {
    return SizedBox(
      width: iconSize,
      height: iconSize,
      child: CustomPaint(
        painter: _SignalBarsPainter(
          level: level,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDetailsColumn(Color color) {
    final TextStyle textStyle = TextStyle(
      color: color,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (metrics?.roundTripTime != null)
          Text(
            'RTT: ${metrics!.roundTripTime!.toStringAsFixed(0)}ms',
            style: textStyle,
          ),
        if (metrics?.packetLossPercent != null)
          Text(
            'Loss: ${metrics!.packetLossPercent!.toStringAsFixed(1)}%',
            style: textStyle,
          ),
        if (metrics?.jitter != null)
          Text(
            'Jitter: ${metrics!.jitter!.toStringAsFixed(0)}ms',
            style: textStyle,
          ),
      ],
    );
  }
}

/// Custom painter for signal bars icon.
class _SignalBarsPainter extends CustomPainter {
  final CallQualityLevel level;
  final Color color;

  _SignalBarsPainter({
    required this.level,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;

    final double barWidth = size.width / 5;
    final double gap = barWidth * 0.3;
    final double actualBarWidth = barWidth - gap;

    // Determine how many bars to fill based on quality level.
    final int filledBars = switch (level) {
      CallQualityLevel.excellent => 4,
      CallQualityLevel.good => 3,
      CallQualityLevel.fair => 2,
      CallQualityLevel.poor => 1,
      CallQualityLevel.bad => 0,
    };

    for (int i = 0; i < 4; i++) {
      final double barHeight = size.height * (0.4 + (i * 0.2));
      final double x = i * barWidth + gap / 2;
      final double y = size.height - barHeight;

      paint.color = i < filledBars ? color : color.withOpacity(0.3);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, actualBarWidth, barHeight),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SignalBarsPainter oldDelegate) {
    return oldDelegate.level != level || oldDelegate.color != color;
  }
}

/// A more detailed quality metrics display card.
class CallQualityDetailsCard extends StatelessWidget {
  final CallQualityMetrics? metrics;

  const CallQualityDetailsCard({
    super.key,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    if (metrics == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No quality data available'),
        ),
      );
    }

    final CallQualityLevel level = metrics!.qualityLevel;
    final Color color = Color(level.colorValue);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                CallQualityIndicator(metrics: metrics),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Score: ${metrics!.qualityScore}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _buildMetricRow(
              'Round Trip Time',
              metrics!.roundTripTime != null
                  ? '${metrics!.roundTripTime!.toStringAsFixed(1)} ms'
                  : 'N/A',
              _getRttColor(metrics!.roundTripTime),
            ),
            _buildMetricRow(
              'Packet Loss',
              metrics!.packetLossPercent != null
                  ? '${metrics!.packetLossPercent!.toStringAsFixed(2)}%'
                  : 'N/A',
              _getLossColor(metrics!.packetLossPercent),
            ),
            _buildMetricRow(
              'Jitter',
              metrics!.jitter != null
                  ? '${metrics!.jitter!.toStringAsFixed(1)} ms'
                  : 'N/A',
              _getJitterColor(metrics!.jitter),
            ),
            _buildMetricRow(
              'Audio Bitrate',
              metrics!.audioBitrate != null
                  ? '${metrics!.audioBitrate!.toStringAsFixed(1)} kbps'
                  : 'N/A',
              null,
            ),
            _buildMetricRow(
              'Codec',
              metrics!.audioCodec ?? 'N/A',
              null,
            ),
            if (metrics!.localCandidateType != null)
              _buildMetricRow(
                'Connection Type',
                '${metrics!.localCandidateType} → '
                    '${metrics!.remoteCandidateType ?? "?"}',
                null,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color? valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRttColor(double? rtt) {
    if (rtt == null) return Colors.grey;
    if (rtt < 100) return Colors.green;
    if (rtt < 200) return Colors.lightGreen;
    if (rtt < 300) return Colors.orange;
    return Colors.red;
  }

  Color _getLossColor(double? loss) {
    if (loss == null) return Colors.grey;
    if (loss < 1) return Colors.green;
    if (loss < 3) return Colors.orange;
    return Colors.red;
  }

  Color _getJitterColor(double? jitter) {
    if (jitter == null) return Colors.grey;
    if (jitter < 30) return Colors.green;
    if (jitter < 50) return Colors.orange;
    return Colors.red;
  }
}
