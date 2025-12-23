import 'package:equatable/equatable.dart';

/// Model representing the current state of an active call.
/// Tracks all toggleable states and call metadata.
class ActiveCallStateModel extends Equatable {
  final String callId;
  final String callerName;
  final String callerNumber;
  final String? callerAvatarUrl;
  final Duration callDuration;
  final bool isMuted;
  final bool isSpeakerOn;
  final bool isOnHold;
  final bool isRecording;
  final bool isKeypadVisible;
  final bool isBluetoothConnected;
  final CallQuality callQuality;
  final DateTime callStartTime;

  const ActiveCallStateModel({
    required this.callId,
    required this.callerName,
    required this.callerNumber,
    this.callerAvatarUrl,
    this.callDuration = Duration.zero,
    this.isMuted = false,
    this.isSpeakerOn = false,
    this.isOnHold = false,
    this.isRecording = false,
    this.isKeypadVisible = false,
    this.isBluetoothConnected = false,
    this.callQuality = CallQuality.good,
    required this.callStartTime,
  });

  /// Creates a copy with updated fields.
  ActiveCallStateModel copyWith({
    String? callId,
    String? callerName,
    String? callerNumber,
    String? callerAvatarUrl,
    Duration? callDuration,
    bool? isMuted,
    bool? isSpeakerOn,
    bool? isOnHold,
    bool? isRecording,
    bool? isKeypadVisible,
    bool? isBluetoothConnected,
    CallQuality? callQuality,
    DateTime? callStartTime,
  }) {
    return ActiveCallStateModel(
      callId: callId ?? this.callId,
      callerName: callerName ?? this.callerName,
      callerNumber: callerNumber ?? this.callerNumber,
      callerAvatarUrl: callerAvatarUrl ?? this.callerAvatarUrl,
      callDuration: callDuration ?? this.callDuration,
      isMuted: isMuted ?? this.isMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      isOnHold: isOnHold ?? this.isOnHold,
      isRecording: isRecording ?? this.isRecording,
      isKeypadVisible: isKeypadVisible ?? this.isKeypadVisible,
      isBluetoothConnected:
          isBluetoothConnected ?? this.isBluetoothConnected,
      callQuality: callQuality ?? this.callQuality,
      callStartTime: callStartTime ?? this.callStartTime,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        callId,
        callerName,
        callerNumber,
        callerAvatarUrl,
        callDuration,
        isMuted,
        isSpeakerOn,
        isOnHold,
        isRecording,
        isKeypadVisible,
        isBluetoothConnected,
        callQuality,
        callStartTime,
      ];
}

/// Enum representing call quality levels.
enum CallQuality {
  excellent,
  good,
  fair,
  poor,
}

extension CallQualityExtension on CallQuality {
  String get displayName {
    switch (this) {
      case CallQuality.excellent:
        return 'Excellent';
      case CallQuality.good:
        return 'Good';
      case CallQuality.fair:
        return 'Fair';
      case CallQuality.poor:
        return 'Poor';
    }
  }

  int get signalBars {
    switch (this) {
      case CallQuality.excellent:
        return 4;
      case CallQuality.good:
        return 3;
      case CallQuality.fair:
        return 2;
      case CallQuality.poor:
        return 1;
    }
  }
}


