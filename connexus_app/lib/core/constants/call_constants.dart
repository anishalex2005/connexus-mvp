/// Constants and enums related to call lifecycle.
///
/// This file focuses on reasons why a call ended. It is used by the
/// active call flow, post-call UI, and call history logging.

/// Reasons why a call ended.
enum CallEndReason {
  /// User initiated hang up.
  userHangUp,

  /// Remote party hung up.
  remoteHangUp,

  /// Call was declined before being answered.
  declined,

  /// No answer (timeout).
  noAnswer,

  /// Network connection lost mid‑call.
  networkError,

  /// Call failed to connect/setup.
  connectionFailed,

  /// Call was transferred to another destination.
  transferred,

  /// Unknown or unspecified reason.
  unknown,
}

/// Extension to provide display/short text for end reasons.
extension CallEndReasonExtension on CallEndReason {
  /// Human‑readable message suitable for UI.
  String get displayText {
    switch (this) {
      case CallEndReason.userHangUp:
        return 'Call ended';
      case CallEndReason.remoteHangUp:
        return 'Call ended by other party';
      case CallEndReason.declined:
        return 'Call declined';
      case CallEndReason.noAnswer:
        return 'No answer';
      case CallEndReason.networkError:
        return 'Connection lost';
      case CallEndReason.connectionFailed:
        return 'Failed to connect';
      case CallEndReason.transferred:
        return 'Call transferred';
      case CallEndReason.unknown:
        return 'Call ended';
    }
  }

  /// Short label suitable for compact chips / history rows.
  String get shortText {
    switch (this) {
      case CallEndReason.userHangUp:
      case CallEndReason.remoteHangUp:
        return 'Ended';
      case CallEndReason.declined:
        return 'Declined';
      case CallEndReason.noAnswer:
        return 'No answer';
      case CallEndReason.networkError:
        return 'Lost';
      case CallEndReason.connectionFailed:
        return 'Failed';
      case CallEndReason.transferred:
        return 'Transferred';
      case CallEndReason.unknown:
        return 'Ended';
    }
  }
}


