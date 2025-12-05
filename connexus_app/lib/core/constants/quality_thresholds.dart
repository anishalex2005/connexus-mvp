/// Quality threshold constants for call quality monitoring.
///
/// These thresholds are based on ITU-T recommendations and
/// industry best practices for VoIP quality assessment.
library;

/// Thresholds for determining call quality levels.
abstract class QualityThresholds {
  // ===== ROUND TRIP TIME (RTT) THRESHOLDS =====

  /// Excellent RTT threshold (ms) - below this is excellent.
  static const double rttExcellent = 100.0;

  /// Good RTT threshold (ms) - below this is good.
  static const double rttGood = 150.0;

  /// Fair RTT threshold (ms) - below this is fair.
  static const double rttFair = 300.0;

  /// Poor RTT threshold (ms) - above this is poor/bad.
  static const double rttPoor = 450.0;

  // ===== PACKET LOSS THRESHOLDS =====

  /// Excellent packet loss threshold (%) - below this is excellent.
  static const double packetLossExcellent = 0.5;

  /// Good packet loss threshold (%) - below this is good.
  static const double packetLossGood = 1.0;

  /// Fair packet loss threshold (%) - below this is fair.
  static const double packetLossFair = 3.0;

  /// Poor packet loss threshold (%) - above this is poor/bad.
  static const double packetLossPoor = 5.0;

  // ===== JITTER THRESHOLDS =====

  /// Excellent jitter threshold (ms) - below this is excellent.
  static const double jitterExcellent = 20.0;

  /// Good jitter threshold (ms) - below this is good.
  static const double jitterGood = 30.0;

  /// Fair jitter threshold (ms) - below this is fair.
  static const double jitterFair = 50.0;

  /// Poor jitter threshold (ms) - above this is poor/bad.
  static const double jitterPoor = 80.0;

  // ===== AUDIO BITRATE THRESHOLDS =====

  /// Minimum acceptable audio bitrate (kbps).
  static const double audioBitrateMinimum = 24.0;

  /// Good audio bitrate (kbps).
  static const double audioBitrateGood = 48.0;

  /// Excellent audio bitrate (kbps).
  static const double audioBitrateExcellent = 64.0;

  // ===== COLLECTION SETTINGS =====

  /// How often to collect metrics (milliseconds).
  static const int metricsCollectionIntervalMs = 2000;

  /// How many metrics samples to keep in memory.
  static const int maxMetricsSamples = 300; // 10 minutes at 2s intervals.

  /// Minimum samples needed for reliable quality assessment.
  static const int minSamplesForAssessment = 5;

  // ===== ALERT THRESHOLDS =====

  /// Consecutive poor quality samples before alerting user.
  static const int consecutivePoorSamplesForAlert = 3;

  /// Quality score threshold for warning.
  static const int qualityScoreWarning = 60;

  /// Quality score threshold for critical alert.
  static const int qualityScoreCritical = 40;
}
