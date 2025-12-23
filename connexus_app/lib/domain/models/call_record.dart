import 'package:flutter/foundation.dart';

import 'call_model.dart';

/// Represents a call record for history and logging.
@immutable
class CallRecord {
  final String id;
  final String callerNumber;
  final String? callerName;
  final CallDirection direction;
  final CallStatus status;
  final String? declineReason;

  /// Optional end reason identifier (e.g. `userHangUp`, `remoteHangUp`).
  /// Used to distinguish different end scenarios for analytics/history.
  final String? endReason;

  final DateTime timestamp;
  final Duration duration;
  final String? notes;

  const CallRecord({
    required this.id,
    required this.callerNumber,
    this.callerName,
    required this.direction,
    required this.status,
    this.declineReason,
    this.endReason,
    required this.timestamp,
    required this.duration,
    this.notes,
  });

  /// Creates a copy with modified fields.
  CallRecord copyWith({
    String? id,
    String? callerNumber,
    String? callerName,
    CallDirection? direction,
    CallStatus? status,
    String? declineReason,
    String? endReason,
    DateTime? timestamp,
    Duration? duration,
    String? notes,
  }) {
    return CallRecord(
      id: id ?? this.id,
      callerNumber: callerNumber ?? this.callerNumber,
      callerName: callerName ?? this.callerName,
      direction: direction ?? this.direction,
      status: status ?? this.status,
      declineReason: declineReason ?? this.declineReason,
      endReason: endReason ?? this.endReason,
      timestamp: timestamp ?? this.timestamp,
      duration: duration ?? this.duration,
      notes: notes ?? this.notes,
    );
  }

  /// Converts to JSON for API/storage.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'caller_number': callerNumber,
      'caller_name': callerName,
      'direction': direction.name,
      'status': status.name,
      'decline_reason': declineReason,
      'end_reason': endReason,
      'timestamp': timestamp.toIso8601String(),
      'duration_seconds': duration.inSeconds,
      'notes': notes,
    };
  }

  /// Creates from JSON.
  factory CallRecord.fromJson(Map<String, dynamic> json) {
    return CallRecord(
      id: json['id'] as String,
      callerNumber: json['caller_number'] as String,
      callerName: json['caller_name'] as String?,
      direction:
          CallDirection.values.byName(json['direction'] as String? ?? 'incoming'),
      status:
          CallStatus.values.byName(json['status'] as String? ?? 'missed'),
      declineReason: json['decline_reason'] as String?,
      endReason: json['end_reason'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      duration: Duration(
        seconds: (json['duration_seconds'] as int?) ?? 0,
      ),
      notes: json['notes'] as String?,
    );
  }

  @override
  String toString() {
    return 'CallRecord(id: $id, caller: $callerNumber, status: $status, endReason: $endReason)';
  }
}

/// Status of the call for history.
enum CallStatus {
  missed,
  answered,
  declined,
  failed,
  completed,
}


