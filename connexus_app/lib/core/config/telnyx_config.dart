/// Telnyx SDK configuration model.
///
/// Holds all configuration needed for Telnyx SDK initialization.
/// Values are ultimately loaded from environment variables via [AppConfig].
library;

/// Strongly-typed configuration for Telnyx WebRTC client.
class TelnyxConfig {
  /// SIP username for authentication (from Telnyx Portal).
  final String sipUsername;

  /// SIP password for authentication.
  final String sipPassword;

  /// Caller ID (phone number) for outbound calls.
  final String callerIdNumber;

  /// Optional caller ID name.
  final String? callerIdName;

  /// Enable/disable debug logging.
  final bool enableDebugLogging;

  /// Connection timeout in seconds.
  final int connectionTimeoutSeconds;

  /// Auto-reconnect on connection loss.
  final bool autoReconnect;

  const TelnyxConfig({
    required this.sipUsername,
    required this.sipPassword,
    required this.callerIdNumber,
    this.callerIdName,
    this.enableDebugLogging = false,
    this.connectionTimeoutSeconds = 30,
    this.autoReconnect = true,
  });

  /// Create config from raw environment-style values.
  ///
  /// Throws [ArgumentError] if any required field is empty.
  factory TelnyxConfig.fromEnvironment({
    required String sipUsername,
    required String sipPassword,
    required String callerIdNumber,
    String? callerIdName,
    bool enableDebugLogging = false,
  }) {
    if (sipUsername.isEmpty) {
      throw ArgumentError('SIP username cannot be empty');
    }
    if (sipPassword.isEmpty) {
      throw ArgumentError('SIP password cannot be empty');
    }
    if (callerIdNumber.isEmpty) {
      throw ArgumentError('Caller ID number cannot be empty');
    }

    return TelnyxConfig(
      sipUsername: sipUsername,
      sipPassword: sipPassword,
      callerIdNumber: callerIdNumber,
      callerIdName: callerIdName,
      enableDebugLogging: enableDebugLogging,
    );
  }

  /// Check if configuration appears valid.
  bool get isValid =>
      sipUsername.isNotEmpty &&
      sipPassword.isNotEmpty &&
      callerIdNumber.isNotEmpty;

  @override
  String toString() {
    return 'TelnyxConfig(sipUsername: $sipUsername, callerIdNumber: '
        '$callerIdNumber, debugLogging: $enableDebugLogging)';
  }
}
