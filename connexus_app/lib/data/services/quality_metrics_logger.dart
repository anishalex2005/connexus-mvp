/// Logger for persisting call quality metrics for later analysis.
///
/// Supports local file storage and optional remote API submission
/// for centralized analytics collection.
library;

import 'dart:convert';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/call_quality_metrics.dart';

/// Configuration for metrics logging.
class MetricsLoggerConfig {
  /// Whether to log metrics locally to file.
  final bool enableLocalLogging;

  /// Whether to submit metrics to remote API.
  final bool enableRemoteLogging;

  /// Remote API endpoint for metrics submission.
  final String? remoteEndpoint;

  /// How many days to retain local logs.
  final int localRetentionDays;

  /// Minimum quality score that triggers detailed logging.
  final int detailedLoggingThreshold;

  const MetricsLoggerConfig({
    this.enableLocalLogging = true,
    this.enableRemoteLogging = false,
    this.remoteEndpoint,
    this.localRetentionDays = 7,
    this.detailedLoggingThreshold = 60,
  });
}

/// Service for logging and persisting quality metrics.
class QualityMetricsLogger {
  final Logger _logger;
  final MetricsLoggerConfig config;

  /// Preference key for tracking last cleanup date.
  static const String _lastCleanupKey = 'quality_metrics_last_cleanup';

  /// Directory name for metrics logs.
  static const String _logsDirName = 'quality_metrics';

  QualityMetricsLogger({
    required this.config,
    Logger? logger,
  }) : _logger = logger ?? Logger();

  /// Log a call's quality metrics summary.
  Future<void> logCallSummary({
    required String callId,
    required List<CallQualityMetrics> metrics,
    required Duration callDuration,
    String? callerNumber,
    String? callDirection,
  }) async {
    if (metrics.isEmpty) {
      _logger.w('No metrics to log for call $callId');
      return;
    }

    final Map<String, dynamic> summary = _calculateSummary(metrics);

    final Map<String, dynamic> logEntry = <String, dynamic>{
      'callId': callId,
      'timestamp': DateTime.now().toIso8601String(),
      'duration': callDuration.inSeconds,
      'callerNumber': callerNumber,
      'direction': callDirection,
      'samplesCount': metrics.length,
      'summary': summary,
      'metrics': metrics.map((CallQualityMetrics m) => m.toJson()).toList(),
    };

    // Log locally.
    if (config.enableLocalLogging) {
      await _writeToLocalFile(callId, logEntry);
    }

    // Submit to remote if enabled and quality was poor.
    final dynamic avgScore = summary['avgQualityScore'];
    if (config.enableRemoteLogging &&
        config.remoteEndpoint != null &&
        avgScore is num &&
        avgScore < config.detailedLoggingThreshold) {
      await _submitToRemote(logEntry);
    }

    _logger.i(
      'Logged quality metrics for call $callId: '
      'avg score ${summary['avgQualityScore']}, '
      '${metrics.length} samples',
    );
  }

  /// Calculate summary statistics from metrics.
  Map<String, dynamic> _calculateSummary(List<CallQualityMetrics> metrics) {
    if (metrics.isEmpty) return <String, dynamic>{};

    double totalRtt = 0;
    double totalJitter = 0;
    double totalLoss = 0;
    double totalScore = 0;
    int rttCount = 0;
    int jitterCount = 0;
    int lossCount = 0;
    double? minRtt;
    double? maxRtt;
    double? minJitter;
    double? maxJitter;

    for (final CallQualityMetrics m in metrics) {
      totalScore += m.qualityScore;

      if (m.roundTripTime != null) {
        final double rtt = m.roundTripTime!;
        totalRtt += rtt;
        rttCount++;

        if (minRtt == null) {
          minRtt = rtt;
        } else if (rtt < minRtt) {
          minRtt = rtt;
        }

        if (maxRtt == null) {
          maxRtt = rtt;
        } else if (rtt > maxRtt) {
          maxRtt = rtt;
        }
      }

      if (m.jitter != null) {
        final double jitter = m.jitter!;
        totalJitter += jitter;
        jitterCount++;

        if (minJitter == null) {
          minJitter = jitter;
        } else if (jitter < minJitter) {
          minJitter = jitter;
        }

        if (maxJitter == null) {
          maxJitter = jitter;
        } else if (jitter > maxJitter) {
          maxJitter = jitter;
        }
      }

      if (m.packetLossPercent != null) {
        totalLoss += m.packetLossPercent!;
        lossCount++;
      }
    }

    // Count quality levels.
    final Map<String, int> levelCounts = <String, int>{};
    for (final CallQualityMetrics m in metrics) {
      final String level = m.qualityLevel.name;
      levelCounts[level] = (levelCounts[level] ?? 0) + 1;
    }

    return <String, dynamic>{
      'avgQualityScore': (totalScore / metrics.length).round(),
      'avgRtt': rttCount > 0 ? (totalRtt / rttCount).round() : null,
      'minRtt': minRtt?.round(),
      'maxRtt': maxRtt?.round(),
      'avgJitter': jitterCount > 0 ? (totalJitter / jitterCount).round() : null,
      'minJitter': minJitter?.round(),
      'maxJitter': maxJitter?.round(),
      'avgPacketLoss': lossCount > 0
          ? double.parse((totalLoss / lossCount).toStringAsFixed(2))
          : null,
      'qualityLevelDistribution': levelCounts,
      'audioCodec': metrics.last.audioCodec,
      'connectionType': metrics.last.localCandidateType,
    };
  }

  /// Write metrics to local file.
  Future<void> _writeToLocalFile(
    String callId,
    Map<String, dynamic> logEntry,
  ) async {
    try {
      final Directory dir = await _getLogsDirectory();
      final DateTime date = DateTime.now();
      final String fileName =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}.jsonl';
      final File file = File('${dir.path}/$fileName');

      // Append to file (JSONL format - one JSON object per line).
      await file.writeAsString(
        '${jsonEncode(logEntry)}\n',
        mode: FileMode.append,
      );

      // Run cleanup periodically.
      await _cleanupOldLogs();
    } catch (e, stackTrace) {
      _logger.e(
        'Failed to write metrics to file',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Submit metrics to remote API.
  Future<void> _submitToRemote(Map<String, dynamic> logEntry) async {
    if (config.remoteEndpoint == null) return;

    try {
      final HttpClient httpClient = HttpClient();
      final HttpClientRequest request =
          await httpClient.postUrl(Uri.parse(config.remoteEndpoint!));
      request.headers.set('Content-Type', 'application/json');
      request.write(jsonEncode(logEntry));

      final HttpClientResponse response = await request.close();

      if (response.statusCode != 200 && response.statusCode != 201) {
        _logger.w(
          'Failed to submit metrics to remote: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.w('Failed to submit metrics to remote', error: e);
      // Don't throw - remote logging is best-effort.
    }
  }

  /// Get or create logs directory.
  Future<Directory> _getLogsDirectory() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final Directory logsDir = Directory('${appDir.path}/$_logsDirName');

    if (!await logsDir.exists()) {
      await logsDir.create(recursive: true);
    }

    return logsDir;
  }

  /// Clean up old log files.
  Future<void> _cleanupOldLogs() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? lastCleanup = prefs.getString(_lastCleanupKey);
      final String today = DateTime.now().toIso8601String().substring(0, 10);

      // Only run cleanup once per day.
      if (lastCleanup == today) return;

      final Directory dir = await _getLogsDirectory();
      final DateTime cutoffDate = DateTime.now().subtract(
        Duration(days: config.localRetentionDays),
      );

      await for (final FileSystemEntity entity in dir.list()) {
        if (entity is File) {
          final FileStat stat = await entity.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await entity.delete();
            _logger.d('Deleted old metrics log: ${entity.path}');
          }
        }
      }

      await prefs.setString(_lastCleanupKey, today);
    } catch (e) {
      _logger.w('Failed to cleanup old logs', error: e);
    }
  }

  /// Read metrics logs for a specific date.
  Future<List<Map<String, dynamic>>> readLogsForDate(DateTime date) async {
    try {
      final Directory dir = await _getLogsDirectory();
      final String fileName =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}.jsonl';
      final File file = File('${dir.path}/$fileName');

      if (!await file.exists()) return <Map<String, dynamic>>[];

      final List<String> lines = await file.readAsLines();
      return lines
          .where((String line) => line.trim().isNotEmpty)
          .map((String line) => jsonDecode(line) as Map<String, dynamic>)
          .toList();
    } catch (e) {
      _logger.e('Failed to read logs', error: e);
      return <Map<String, dynamic>>[];
    }
  }

  /// Get all available log dates.
  Future<List<DateTime>> getAvailableLogDates() async {
    try {
      final Directory dir = await _getLogsDirectory();
      final List<DateTime> dates = <DateTime>[];

      await for (final FileSystemEntity entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.jsonl')) {
          final String fileName =
              entity.path.split(Platform.pathSeparator).last;
          final String datePart = fileName.replaceAll('.jsonl', '');
          final List<String> parts = datePart.split('-');
          if (parts.length == 3) {
            try {
              dates.add(
                DateTime(
                  int.parse(parts[0]),
                  int.parse(parts[1]),
                  int.parse(parts[2]),
                ),
              );
            } catch (_) {
              // Ignore malformed filenames.
            }
          }
        }
      }

      dates.sort(
          (DateTime a, DateTime b) => b.compareTo(a)); // Most recent first.
      return dates;
    } catch (e) {
      _logger.e('Failed to get log dates', error: e);
      return <DateTime>[];
    }
  }
}
