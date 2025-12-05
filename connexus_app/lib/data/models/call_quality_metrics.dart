/// Call quality metrics collected from WebRTC statistics.
///
/// These metrics are gathered periodically during an active call
/// to monitor and report on call quality in real-time.
library;

import 'package:flutter/foundation.dart';

/// Represents a snapshot of call quality metrics at a point in time.
@immutable
class CallQualityMetrics {
  /// Timestamp when these metrics were collected.
  final DateTime timestamp;

  /// Round-trip time in milliseconds (network latency).
  final double? roundTripTime;

  /// Jitter in milliseconds (variation in packet arrival time).
  final double? jitter;

  /// Packet loss percentage (0-100).
  final double? packetLossPercent;

  /// Audio bitrate in kbps.
  final double? audioBitrate;

  /// Video bitrate in kbps (if video call).
  final double? videoBitrate;

  /// Audio codec being used (e.g., "opus", "PCMU").
  final String? audioCodec;

  /// Video codec being used (e.g., "VP8", "H264").
  final String? videoCodec;

  /// Total bytes sent.
  final int? bytesSent;

  /// Total bytes received.
  final int? bytesReceived;

  /// Total packets sent.
  final int? packetsSent;

  /// Total packets received.
  final int? packetsReceived;

  /// Total packets lost.
  final int? packetsLost;

  /// Local candidate type (host, srflx, relay).
  final String? localCandidateType;

  /// Remote candidate type.
  final String? remoteCandidateType;

  /// Available outgoing bitrate estimated by the browser.
  final double? availableOutgoingBitrate;

  const CallQualityMetrics({
    required this.timestamp,
    this.roundTripTime,
    this.jitter,
    this.packetLossPercent,
    this.audioBitrate,
    this.videoBitrate,
    this.audioCodec,
    this.videoCodec,
    this.bytesSent,
    this.bytesReceived,
    this.packetsSent,
    this.packetsReceived,
    this.packetsLost,
    this.localCandidateType,
    this.remoteCandidateType,
    this.availableOutgoingBitrate,
  });

  /// Creates an empty metrics snapshot.
  factory CallQualityMetrics.empty() => CallQualityMetrics(
        timestamp: DateTime.now(),
      );

  /// Calculate overall quality score (0-100).
  ///
  /// Based on a simplified ITU-T G.107 E-model style approach.
  int get qualityScore {
    double score = 100.0;

    // Penalize for packet loss (major impact).
    if (packetLossPercent != null) {
      score -= packetLossPercent! * 2.5; // 1% loss = -2.5 points.
    }

    // Penalize for high latency.
    if (roundTripTime != null) {
      if (roundTripTime! > 300) {
        score -= 30; // Very high latency.
      } else if (roundTripTime! > 150) {
        score -= (roundTripTime! - 150) * 0.15;
      }
    }

    // Penalize for jitter.
    if (jitter != null) {
      if (jitter! > 50) {
        score -= 15;
      } else if (jitter! > 30) {
        score -= (jitter! - 30) * 0.5;
      }
    }

    return score.clamp(0, 100).round();
  }

  /// Get quality level based on score.
  CallQualityLevel get qualityLevel {
    final int score = qualityScore;
    if (score >= 80) return CallQualityLevel.excellent;
    if (score >= 60) return CallQualityLevel.good;
    if (score >= 40) return CallQualityLevel.fair;
    if (score >= 20) return CallQualityLevel.poor;
    return CallQualityLevel.bad;
  }

  /// Convert to JSON for logging/analytics.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'timestamp': timestamp.toIso8601String(),
        'roundTripTime': roundTripTime,
        'jitter': jitter,
        'packetLossPercent': packetLossPercent,
        'audioBitrate': audioBitrate,
        'videoBitrate': videoBitrate,
        'audioCodec': audioCodec,
        'videoCodec': videoCodec,
        'bytesSent': bytesSent,
        'bytesReceived': bytesReceived,
        'packetsSent': packetsSent,
        'packetsReceived': packetsReceived,
        'packetsLost': packetsLost,
        'localCandidateType': localCandidateType,
        'remoteCandidateType': remoteCandidateType,
        'availableOutgoingBitrate': availableOutgoingBitrate,
        'qualityScore': qualityScore,
        'qualityLevel': qualityLevel.name,
      };

  /// Create from JSON.
  factory CallQualityMetrics.fromJson(Map<String, dynamic> json) {
    return CallQualityMetrics(
      timestamp: DateTime.parse(json['timestamp'] as String),
      roundTripTime: (json['roundTripTime'] as num?)?.toDouble(),
      jitter: (json['jitter'] as num?)?.toDouble(),
      packetLossPercent: (json['packetLossPercent'] as num?)?.toDouble(),
      audioBitrate: (json['audioBitrate'] as num?)?.toDouble(),
      videoBitrate: (json['videoBitrate'] as num?)?.toDouble(),
      audioCodec: json['audioCodec'] as String?,
      videoCodec: json['videoCodec'] as String?,
      bytesSent: json['bytesSent'] as int?,
      bytesReceived: json['bytesReceived'] as int?,
      packetsSent: json['packetsSent'] as int?,
      packetsReceived: json['packetsReceived'] as int?,
      packetsLost: json['packetsLost'] as int?,
      localCandidateType: json['localCandidateType'] as String?,
      remoteCandidateType: json['remoteCandidateType'] as String?,
      availableOutgoingBitrate:
          (json['availableOutgoingBitrate'] as num?)?.toDouble(),
    );
  }

  @override
  String toString() =>
      'CallQualityMetrics(score: $qualityScore, rtt: ${roundTripTime?.toStringAsFixed(1)}ms, '
      'loss: ${packetLossPercent?.toStringAsFixed(2)}%, jitter: ${jitter?.toStringAsFixed(1)}ms)';

  CallQualityMetrics copyWith({
    DateTime? timestamp,
    double? roundTripTime,
    double? jitter,
    double? packetLossPercent,
    double? audioBitrate,
    double? videoBitrate,
    String? audioCodec,
    String? videoCodec,
    int? bytesSent,
    int? bytesReceived,
    int? packetsSent,
    int? packetsReceived,
    int? packetsLost,
    String? localCandidateType,
    String? remoteCandidateType,
    double? availableOutgoingBitrate,
  }) {
    return CallQualityMetrics(
      timestamp: timestamp ?? this.timestamp,
      roundTripTime: roundTripTime ?? this.roundTripTime,
      jitter: jitter ?? this.jitter,
      packetLossPercent: packetLossPercent ?? this.packetLossPercent,
      audioBitrate: audioBitrate ?? this.audioBitrate,
      videoBitrate: videoBitrate ?? this.videoBitrate,
      audioCodec: audioCodec ?? this.audioCodec,
      videoCodec: videoCodec ?? this.videoCodec,
      bytesSent: bytesSent ?? this.bytesSent,
      bytesReceived: bytesReceived ?? this.bytesReceived,
      packetsSent: packetsSent ?? this.packetsSent,
      packetsReceived: packetsReceived ?? this.packetsReceived,
      packetsLost: packetsLost ?? this.packetsLost,
      localCandidateType: localCandidateType ?? this.localCandidateType,
      remoteCandidateType: remoteCandidateType ?? this.remoteCandidateType,
      availableOutgoingBitrate:
          availableOutgoingBitrate ?? this.availableOutgoingBitrate,
    );
  }
}

/// Quality level enumeration.
enum CallQualityLevel {
  excellent,
  good,
  fair,
  poor,
  bad;

  String get displayName {
    switch (this) {
      case CallQualityLevel.excellent:
        return 'Excellent';
      case CallQualityLevel.good:
        return 'Good';
      case CallQualityLevel.fair:
        return 'Fair';
      case CallQualityLevel.poor:
        return 'Poor';
      case CallQualityLevel.bad:
        return 'Bad';
    }
  }

  /// Get color for UI display (returns color value as int for platform independence).
  int get colorValue {
    switch (this) {
      case CallQualityLevel.excellent:
        return 0xFF4CAF50; // Green.
      case CallQualityLevel.good:
        return 0xFF8BC34A; // Light Green.
      case CallQualityLevel.fair:
        return 0xFFFFEB3B; // Yellow.
      case CallQualityLevel.poor:
        return 0xFFFF9800; // Orange.
      case CallQualityLevel.bad:
        return 0xFFF44336; // Red.
    }
  }
}
