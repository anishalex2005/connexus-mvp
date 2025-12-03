/// Represents the current state of the WebRTC connection.
enum WebRTCConnectionState {
  /// Initial state, no connection attempt made.
  idle,

  /// Connecting to the peer.
  connecting,

  /// Connection established successfully.
  connected,

  /// Connection temporarily disrupted, attempting recovery.
  reconnecting,

  /// Connection failed.
  failed,

  /// Connection closed intentionally.
  closed,

  /// Gathering ICE candidates.
  gatheringIceCandidates,
}

/// Detailed connection quality information.
class ConnectionQuality {
  final double? packetsLost;
  final double? jitter;
  final double? roundTripTime;
  final int? bitrate;
  final String qualityLevel; // 'excellent', 'good', 'fair', 'poor', 'unknown'

  const ConnectionQuality({
    this.packetsLost,
    this.jitter,
    this.roundTripTime,
    this.bitrate,
    this.qualityLevel = 'unknown',
  });

  factory ConnectionQuality.fromStats(Map<String, dynamic> stats) {
    final double? packetsLost = stats['packetsLost'] as double?;
    final double? jitter = stats['jitter'] as double?;
    final double? rtt = stats['roundTripTime'] as double?;
    final int? bitrate = stats['bitrate'] as int?;

    String quality = 'unknown';
    if (rtt != null) {
      if (rtt < 100) {
        quality = 'excellent';
      } else if (rtt < 200) {
        quality = 'good';
      } else if (rtt < 400) {
        quality = 'fair';
      } else {
        quality = 'poor';
      }
    }

    return ConnectionQuality(
      packetsLost: packetsLost,
      jitter: jitter,
      roundTripTime: rtt,
      bitrate: bitrate,
      qualityLevel: quality,
    );
  }

  @override
  String toString() {
    return 'ConnectionQuality(quality: $qualityLevel, rtt: ${roundTripTime}ms, '
        'jitter: ${jitter}ms, packetsLost: $packetsLost, bitrate: $bitrate)';
  }
}

/// Event emitted when connection state changes.
class ConnectionStateEvent {
  final WebRTCConnectionState state;
  final String? reason;
  final DateTime timestamp;

  ConnectionStateEvent({
    required this.state,
    this.reason,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
