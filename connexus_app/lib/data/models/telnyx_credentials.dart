import 'package:equatable/equatable.dart';

/// Model representing Telnyx SIP credentials for authentication.
class TelnyxCredentials extends Equatable {
  final String sipUsername;
  final String sipPassword;
  final String? callerIdName;
  final String? callerIdNumber;
  final String? fcmToken;
  final bool isValid;

  const TelnyxCredentials({
    required this.sipUsername,
    required this.sipPassword,
    this.callerIdName,
    this.callerIdNumber,
    this.fcmToken,
  }) : isValid = sipUsername != '' && sipPassword != '';

  /// Creates credentials from API response.
  factory TelnyxCredentials.fromJson(Map<String, dynamic> json) {
    final username = json['sip_username'] as String? ?? '';
    final password = json['sip_password'] as String? ?? '';

    return TelnyxCredentials(
      sipUsername: username,
      sipPassword: password,
      callerIdName: json['caller_id_name'] as String?,
      callerIdNumber: json['caller_id_number'] as String?,
      fcmToken: json['fcm_token'] as String?,
    );
  }

  /// Converts credentials to JSON for storage / API calls.
  Map<String, dynamic> toJson() {
    return {
      'sip_username': sipUsername,
      'sip_password': sipPassword,
      'caller_id_name': callerIdName,
      'caller_id_number': callerIdNumber,
      'fcm_token': fcmToken,
    };
  }

  /// Creates an empty/invalid credentials object.
  factory TelnyxCredentials.empty() {
    return const TelnyxCredentials(
      sipUsername: '',
      sipPassword: '',
    );
  }

  /// Creates a copy with updated fields.
  TelnyxCredentials copyWith({
    String? sipUsername,
    String? sipPassword,
    String? callerIdName,
    String? callerIdNumber,
    String? fcmToken,
  }) {
    return TelnyxCredentials(
      sipUsername: sipUsername ?? this.sipUsername,
      sipPassword: sipPassword ?? this.sipPassword,
      callerIdName: callerIdName ?? this.callerIdName,
      callerIdNumber: callerIdNumber ?? this.callerIdNumber,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  @override
  List<Object?> get props => [
        sipUsername,
        sipPassword,
        callerIdName,
        callerIdNumber,
        fcmToken,
        isValid,
      ];

  @override
  String toString() {
    return 'TelnyxCredentials(username: $sipUsername, '
        'hasPassword: ${sipPassword.isNotEmpty}, '
        'callerId: $callerIdName <$callerIdNumber>, '
        'isValid: $isValid)';
  }
}
