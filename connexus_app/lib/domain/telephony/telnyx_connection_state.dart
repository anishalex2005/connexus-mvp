/// Represents the current state of the Telnyx SIP connection.
enum TelnyxConnectionState {
  /// Initial state, not yet attempted connection.
  disconnected,

  /// Currently attempting to connect.
  connecting,

  /// Successfully registered with SIP server.
  registered,

  /// Registration failed, may retry.
  failed,

  /// Connection lost, attempting reconnection.
  reconnecting,

  /// Intentionally disconnected by user/app.
  loggedOut,
}

/// Extension helpers for [TelnyxConnectionState].
extension TelnyxConnectionStateX on TelnyxConnectionState {
  bool get isConnected => this == TelnyxConnectionState.registered;

  bool get isConnecting =>
      this == TelnyxConnectionState.connecting ||
      this == TelnyxConnectionState.reconnecting;

  bool get canMakeCalls => this == TelnyxConnectionState.registered;

  String get displayName {
    switch (this) {
      case TelnyxConnectionState.disconnected:
        return 'Disconnected';
      case TelnyxConnectionState.connecting:
        return 'Connecting...';
      case TelnyxConnectionState.registered:
        return 'Connected';
      case TelnyxConnectionState.failed:
        return 'Connection Failed';
      case TelnyxConnectionState.reconnecting:
        return 'Reconnecting...';
      case TelnyxConnectionState.loggedOut:
        return 'Logged Out';
    }
  }
}

/// Event emitted when connection state changes.
class TelnyxConnectionEvent {
  final TelnyxConnectionState state;
  final String? message;
  final dynamic error;
  final DateTime timestamp;

  TelnyxConnectionEvent({
    required this.state,
    this.message,
    this.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'TelnyxConnectionEvent(state: ${state.displayName}, '
        'message: $message, error: $error, time: $timestamp)';
  }
}
