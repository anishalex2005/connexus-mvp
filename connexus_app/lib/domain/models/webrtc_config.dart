/// Configuration for ICE servers used in WebRTC connections.
class IceServerConfig {
  final String url;
  final String? username;
  final String? credential;

  const IceServerConfig({
    required this.url,
    this.username,
    this.credential,
  });

  /// Convert to flutter_webrtc format.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{'urls': url};
    if (username != null) {
      map['username'] = username;
    }
    if (credential != null) {
      map['credential'] = credential;
    }
    return map;
  }

  factory IceServerConfig.fromJson(Map<String, dynamic> json) {
    return IceServerConfig(
      url: json['url'] as String,
      username: json['username'] as String?,
      credential: json['credential'] as String?,
    );
  }
}

/// Complete WebRTC configuration including all ICE servers.
class WebRTCConfig {
  final List<IceServerConfig> iceServers;
  final bool iceCandidatePooling;
  final int iceCandidatePoolSize;
  final String bundlePolicy;
  final String rtcpMuxPolicy;
  final String iceTransportPolicy;

  const WebRTCConfig({
    required this.iceServers,
    this.iceCandidatePooling = true,
    this.iceCandidatePoolSize = 2,
    this.bundlePolicy = 'max-bundle',
    this.rtcpMuxPolicy = 'require',
    this.iceTransportPolicy = 'all',
  });

  /// Convert to RTCConfiguration for flutter_webrtc.
  Map<String, dynamic> toRTCConfiguration() {
    return <String, dynamic>{
      'iceServers': iceServers.map((s) => s.toMap()).toList(),
      'iceCandidatePoolSize': iceCandidatePoolSize,
      'bundlePolicy': bundlePolicy,
      'rtcpMuxPolicy': rtcpMuxPolicy,
      'iceTransportPolicy': iceTransportPolicy,
    };
  }

  /// Default configuration for Telnyx using public STUN plus Telnyx STUN/TURN.
  factory WebRTCConfig.telnyxDefault({
    String? turnUsername,
    String? turnPassword,
  }) {
    return WebRTCConfig(
      iceServers: <IceServerConfig>[
        // Google's public STUN servers as backup.
        const IceServerConfig(url: 'stun:stun.l.google.com:19302'),
        const IceServerConfig(url: 'stun:stun1.l.google.com:19302'),
        // Telnyx STUN server.
        const IceServerConfig(url: 'stun:stun.telnyx.com:3478'),
        // Telnyx TURN server (requires credentials).
        if (turnUsername != null && turnPassword != null)
          IceServerConfig(
            url: 'turn:turn.telnyx.com:3478',
            username: turnUsername,
            credential: turnPassword,
          ),
        if (turnUsername != null && turnPassword != null)
          IceServerConfig(
            url: 'turn:turn.telnyx.com:3478?transport=tcp',
            username: turnUsername,
            credential: turnPassword,
          ),
      ],
    );
  }
}
