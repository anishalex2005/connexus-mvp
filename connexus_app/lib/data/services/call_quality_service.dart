/// Service for collecting, processing, and reporting WebRTC call quality metrics.
///
/// This service periodically gathers statistics from the WebRTC peer connection
/// and provides real-time quality indicators and historical data for analysis.
library;

import 'dart:async';
import 'dart:collection';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';

import '../../core/constants/quality_thresholds.dart';
import '../models/call_quality_metrics.dart';

/// Callback type for quality change notifications.
typedef QualityChangeCallback = void Function(
  CallQualityLevel oldLevel,
  CallQualityLevel newLevel,
);

/// Service that monitors and reports call quality metrics from WebRTC.
class CallQualityService {
  final Logger _logger;

  /// Stream controller for broadcasting metrics updates.
  final BehaviorSubject<CallQualityMetrics> _metricsController =
      BehaviorSubject<CallQualityMetrics>();

  /// Stream controller for quality level changes.
  final BehaviorSubject<CallQualityLevel> _qualityLevelController =
      BehaviorSubject<CallQualityLevel>();

  /// Timer for periodic metrics collection.
  Timer? _collectionTimer;

  /// The current peer connection being monitored.
  RTCPeerConnection? _peerConnection;

  /// Historical metrics for the current call.
  final Queue<CallQualityMetrics> _metricsHistory = Queue<CallQualityMetrics>();

  /// Previous timestamp for bitrate calculations.
  DateTime? _previousTimestamp;

  /// Previous bytes received for calculating bitrate.
  int? _previousBytesReceived;

  /// Previous bytes sent for calculating bitrate.
  // Currently tracked for potential future use in more detailed metrics, but
  // not read anywhere, so we explicitly ignore the unused_field lint.
  // ignore: unused_field
  int? _previousBytesSent;

  /// Callback for quality level changes.
  QualityChangeCallback? onQualityChange;

  /// Track consecutive poor quality samples.
  int _consecutivePoorSamples = 0;

  /// Current call ID for logging.
  String? _currentCallId;

  CallQualityService({Logger? logger}) : _logger = logger ?? Logger();

  /// Stream of real-time quality metrics.
  Stream<CallQualityMetrics> get metricsStream => _metricsController.stream;

  /// Stream of quality level changes.
  Stream<CallQualityLevel> get qualityLevelStream =>
      _qualityLevelController.stream;

  /// Get the most recent metrics snapshot.
  CallQualityMetrics? get currentMetrics => _metricsController.valueOrNull;

  /// Get current quality level.
  CallQualityLevel? get currentQualityLevel =>
      _qualityLevelController.valueOrNull;

  /// Get metrics history for the current call.
  List<CallQualityMetrics> get metricsHistory =>
      _metricsHistory.toList(growable: false);

  /// Check if currently monitoring.
  bool get isMonitoring =>
      _collectionTimer != null && _collectionTimer!.isActive;

  /// Start monitoring call quality for a peer connection.
  ///
  /// [peerConnection] - The WebRTC peer connection to monitor.
  /// [callId] - Optional call identifier for logging purposes.
  void startMonitoring(RTCPeerConnection peerConnection, {String? callId}) {
    _logger.i(
      'Starting call quality monitoring'
      '${callId != null ? ' for call: $callId' : ''}',
    );

    // Stop any existing monitoring.
    stopMonitoring();

    _peerConnection = peerConnection;
    _currentCallId = callId;
    _metricsHistory.clear();
    _previousTimestamp = null;
    _previousBytesReceived = null;
    _previousBytesSent = null;
    _consecutivePoorSamples = 0;

    // Start periodic collection.
    _collectionTimer = Timer.periodic(
      Duration(milliseconds: QualityThresholds.metricsCollectionIntervalMs),
      (_) => _collectMetrics(),
    );

    // Collect initial metrics immediately.
    // ignore: discarded_futures
    _collectMetrics();
  }

  /// Stop monitoring call quality.
  void stopMonitoring() {
    _logger.i('Stopping call quality monitoring');

    _collectionTimer?.cancel();
    _collectionTimer = null;
    _peerConnection = null;

    // Log final summary if we have history.
    if (_metricsHistory.isNotEmpty) {
      _logCallQualitySummary();
    }
  }

  /// Collect metrics from the peer connection.
  Future<void> _collectMetrics() async {
    final RTCPeerConnection? pc = _peerConnection;
    if (pc == null) {
      _logger.w('Cannot collect metrics: no peer connection');
      return;
    }

    try {
      final dynamic stats = await pc.getStats();
      final CallQualityMetrics? metrics = _parseStats(stats);

      if (metrics != null) {
        _processMetrics(metrics);
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Error collecting metrics',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Parse WebRTC stats into [CallQualityMetrics].
  CallQualityMetrics? _parseStats(dynamic stats) {
    double? rtt;
    double? jitter;
    double? packetLossPercent;
    double? audioBitrate;
    String? audioCodec;
    String? videoCodec;
    int? bytesSent;
    int? bytesReceived;
    int? packetsSent;
    int? packetsReceived;
    int? packetsLost;
    String? localCandidateType;
    String? remoteCandidateType;
    double? availableOutgoingBitrate;

    final DateTime now = DateTime.now();

    if (stats is Map) {
      for (final dynamic entry in stats.values) {
        if (entry is! Map) continue;
        final Map<String, dynamic> report = entry.cast<String, dynamic>();
        final String? type = report['type'] as String?;
        final Map<String, dynamic> values =
            (report['values'] as Map?)?.cast<String, dynamic>() ??
                <String, dynamic>{};

        // Extract RTT from candidate-pair / transport stats.
        if (type == 'candidate-pair' || type == 'transport') {
          final double? currentRtt =
              _extractDouble(values, 'currentRoundTripTime');
          if (currentRtt != null) {
            rtt = currentRtt * 1000; // Convert to ms.
          }

          final double? availableBitrate =
              _extractDouble(values, 'availableOutgoingBitrate');
          if (availableBitrate != null) {
            availableOutgoingBitrate = availableBitrate;
          }

          final dynamic nominated = values['nominated'];
          if (nominated == true || nominated == 'true') {
            localCandidateType = values['localCandidateType'] as String?;
            remoteCandidateType = values['remoteCandidateType'] as String?;
          }
        }

        // Extract audio inbound stats.
        if (type == 'inbound-rtp') {
          final dynamic mediaType = values['mediaType'] ?? values['kind'];
          if (mediaType == 'audio') {
            final double? rawJitter = _extractDouble(values, 'jitter');
            if (rawJitter != null) {
              jitter = rawJitter * 1000; // Convert to ms.
            }

            packetsReceived = _extractInt(values, 'packetsReceived');
            packetsLost = _extractInt(values, 'packetsLost');
            bytesReceived = _extractInt(values, 'bytesReceived');

            // Calculate packet loss percentage.
            if (packetsReceived != null && packetsLost != null) {
              final int received = packetsReceived;
              final int lost = packetsLost;
              final int totalPackets = received + lost;
              if (totalPackets > 0) {
                packetLossPercent = (lost / totalPackets) * 100;
              }
            }
          }
        }

        // Extract audio outbound stats.
        if (type == 'outbound-rtp') {
          final dynamic mediaType = values['mediaType'] ?? values['kind'];
          if (mediaType == 'audio') {
            packetsSent = _extractInt(values, 'packetsSent');
            bytesSent = _extractInt(values, 'bytesSent');
          }
        }

        // Extract codec info.
        if (type == 'codec') {
          final String? mimeType = values['mimeType'] as String?;
          if (mimeType != null) {
            if (mimeType.startsWith('audio/')) {
              audioCodec = mimeType.substring('audio/'.length);
            } else if (mimeType.startsWith('video/')) {
              videoCodec = mimeType.substring('video/'.length);
            }
          }
        }
      }
    }

    // Calculate bitrate from bytes delta (received).
    if (_previousTimestamp != null &&
        _previousBytesReceived != null &&
        bytesReceived != null) {
      final int timeDeltaMs =
          now.difference(_previousTimestamp!).inMilliseconds;
      if (timeDeltaMs > 0) {
        final int bytesDelta = bytesReceived - _previousBytesReceived!;
        if (bytesDelta >= 0) {
          final double bitsPerSecond =
              bytesDelta * 8 * 1000 / timeDeltaMs.toDouble();
          audioBitrate = bitsPerSecond / 1000; // kbps.
        }
      }
    }

    // Update previous values for next calculation.
    _previousTimestamp = now;
    _previousBytesReceived = bytesReceived;
    _previousBytesSent = bytesSent;

    return CallQualityMetrics(
      timestamp: now,
      roundTripTime: rtt,
      jitter: jitter,
      packetLossPercent: packetLossPercent,
      audioBitrate: audioBitrate,
      audioCodec: audioCodec,
      videoCodec: videoCodec,
      bytesSent: bytesSent,
      bytesReceived: bytesReceived,
      packetsSent: packetsSent,
      packetsReceived: packetsReceived,
      packetsLost: packetsLost,
      localCandidateType: localCandidateType,
      remoteCandidateType: remoteCandidateType,
      availableOutgoingBitrate: availableOutgoingBitrate,
    );
  }

  /// Process collected metrics.
  void _processMetrics(CallQualityMetrics metrics) {
    // Add to history.
    _metricsHistory.addLast(metrics);

    // Trim history if needed.
    while (_metricsHistory.length > QualityThresholds.maxMetricsSamples) {
      _metricsHistory.removeFirst();
    }

    // Broadcast metrics.
    _metricsController.add(metrics);

    // Check for quality level changes.
    final CallQualityLevel? previousLevel = _qualityLevelController.valueOrNull;
    final CallQualityLevel currentLevel = metrics.qualityLevel;

    if (previousLevel != currentLevel) {
      _qualityLevelController.add(currentLevel);
      onQualityChange?.call(previousLevel ?? currentLevel, currentLevel);

      _logger.i(
        'Quality level changed: ${previousLevel?.name ?? "none"} '
        '-> ${currentLevel.name} (score: ${metrics.qualityScore})',
      );
    }

    // Track consecutive poor samples for alerts.
    if (metrics.qualityScore < QualityThresholds.qualityScoreWarning) {
      _consecutivePoorSamples++;

      if (_consecutivePoorSamples >=
          QualityThresholds.consecutivePoorSamplesForAlert) {
        _logger.w(
          'Quality warning: $_consecutivePoorSamples consecutive poor samples. '
          'RTT: ${metrics.roundTripTime?.toStringAsFixed(0)}ms, '
          'Loss: ${metrics.packetLossPercent?.toStringAsFixed(2)}%, '
          'Jitter: ${metrics.jitter?.toStringAsFixed(1)}ms',
        );
      }
    } else {
      _consecutivePoorSamples = 0;
    }

    // Debug logging (can be reduced in production).
    _logger.d(metrics.toString());
  }

  /// Log a summary of call quality at the end of a call.
  void _logCallQualitySummary() {
    if (_metricsHistory.isEmpty) return;

    final List<CallQualityMetrics> samples = _metricsHistory.toList();

    // Calculate averages.
    double avgRtt = 0;
    double avgJitter = 0;
    double avgLoss = 0;
    int rttCount = 0;
    int jitterCount = 0;
    int lossCount = 0;

    for (final CallQualityMetrics m in samples) {
      if (m.roundTripTime != null) {
        avgRtt += m.roundTripTime!;
        rttCount++;
      }
      if (m.jitter != null) {
        avgJitter += m.jitter!;
        jitterCount++;
      }
      if (m.packetLossPercent != null) {
        avgLoss += m.packetLossPercent!;
        lossCount++;
      }
    }

    avgRtt = rttCount > 0 ? avgRtt / rttCount : 0;
    avgJitter = jitterCount > 0 ? avgJitter / jitterCount : 0;
    avgLoss = lossCount > 0 ? avgLoss / lossCount : 0;

    // Calculate average quality score.
    final double avgScore = samples
            .map((CallQualityMetrics m) => m.qualityScore)
            .fold<int>(0, (int a, int b) => a + b) /
        samples.length;

    _logger.i(
      'Call Quality Summary'
      '${_currentCallId != null ? ' (Call: $_currentCallId)' : ''}:\n'
      '  Samples: ${samples.length}\n'
      '  Avg RTT: ${avgRtt.toStringAsFixed(1)}ms\n'
      '  Avg Jitter: ${avgJitter.toStringAsFixed(1)}ms\n'
      '  Avg Packet Loss: ${avgLoss.toStringAsFixed(2)}%\n'
      '  Avg Quality Score: ${avgScore.toStringAsFixed(1)}/100',
    );
  }

  /// Get average metrics over a time window.
  CallQualityMetrics? getAverageMetrics({Duration? window}) {
    if (_metricsHistory.isEmpty) return null;

    List<CallQualityMetrics> samples;

    if (window != null) {
      final DateTime cutoff = DateTime.now().subtract(window);
      samples = _metricsHistory
          .where((CallQualityMetrics m) => m.timestamp.isAfter(cutoff))
          .toList();
    } else {
      samples = _metricsHistory.toList();
    }

    if (samples.isEmpty) return null;

    double? avgRtt;
    double? avgJitter;
    double? avgLoss;
    double? avgBitrate;
    int rttCount = 0;
    int jitterCount = 0;
    int lossCount = 0;
    int bitrateCount = 0;

    for (final CallQualityMetrics m in samples) {
      if (m.roundTripTime != null) {
        avgRtt = (avgRtt ?? 0) + m.roundTripTime!;
        rttCount++;
      }
      if (m.jitter != null) {
        avgJitter = (avgJitter ?? 0) + m.jitter!;
        jitterCount++;
      }
      if (m.packetLossPercent != null) {
        avgLoss = (avgLoss ?? 0) + m.packetLossPercent!;
        lossCount++;
      }
      if (m.audioBitrate != null) {
        avgBitrate = (avgBitrate ?? 0) + m.audioBitrate!;
        bitrateCount++;
      }
    }

    return CallQualityMetrics(
      timestamp: DateTime.now(),
      roundTripTime: rttCount > 0 ? avgRtt! / rttCount : null,
      jitter: jitterCount > 0 ? avgJitter! / jitterCount : null,
      packetLossPercent: lossCount > 0 ? avgLoss! / lossCount : null,
      audioBitrate: bitrateCount > 0 ? avgBitrate! / bitrateCount : null,
      audioCodec: samples.last.audioCodec,
    );
  }

  /// Export metrics history as JSON.
  List<Map<String, dynamic>> exportMetricsAsJson() {
    return _metricsHistory.map((CallQualityMetrics m) => m.toJson()).toList();
  }

  /// Helper to extract double from stats values.
  double? _extractDouble(Map<String, dynamic> values, String key) {
    final dynamic value = values[key];
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Helper to extract int from stats values.
  int? _extractInt(Map<String, dynamic> values, String key) {
    final dynamic value = values[key];
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Dispose of resources.
  void dispose() {
    stopMonitoring();
    _metricsController.close();
    _qualityLevelController.close();
  }
}
