/// Represents the current network connectivity state.
enum NetworkStatus {
  /// Device is connected via WiFi.
  wifi,

  /// Device is connected via cellular/mobile data.
  cellular,

  /// Device is connected via Ethernet (tablets/desktop/web).
  ethernet,

  /// Device has no network connection.
  disconnected,

  /// Network status is unknown or being determined.
  unknown,
}

/// Represents the quality of the current network connection.
///
/// Note: For now this is a coarse, mostly-static value. Task 18 will
/// update it using real WebRTC statistics and Telnyx metrics.
enum NetworkQuality {
  /// Excellent connection (low latency, high bandwidth).
  excellent,

  /// Good connection (acceptable for VoIP).
  good,

  /// Poor connection (may experience call quality issues).
  poor,

  /// Connection is unstable or unreliable.
  unstable,

  /// Cannot determine quality.
  unknown,
}

/// Comprehensive network state model.
class NetworkState {
  final NetworkStatus status;
  final NetworkQuality quality;
  final bool isConnected;
  final DateTime lastChanged;
  final String? connectionType;
  final int? signalStrength;

  const NetworkState({
    required this.status,
    this.quality = NetworkQuality.unknown,
    required this.isConnected,
    required this.lastChanged,
    this.connectionType,
    this.signalStrength,
  });

  /// Factory for initial/unknown state.
  factory NetworkState.unknown() {
    return NetworkState(
      status: NetworkStatus.unknown,
      quality: NetworkQuality.unknown,
      isConnected: false,
      lastChanged: DateTime.now(),
    );
  }

  /// Factory for connected state.
  factory NetworkState.connected({
    required NetworkStatus status,
    NetworkQuality quality = NetworkQuality.good,
    String? connectionType,
    int? signalStrength,
  }) {
    return NetworkState(
      status: status,
      quality: quality,
      isConnected: true,
      lastChanged: DateTime.now(),
      connectionType: connectionType,
      signalStrength: signalStrength,
    );
  }

  /// Factory for disconnected state.
  factory NetworkState.disconnected() {
    return NetworkState(
      status: NetworkStatus.disconnected,
      quality: NetworkQuality.unknown,
      isConnected: false,
      lastChanged: DateTime.now(),
    );
  }

  /// Check if network is suitable for VoIP calls.
  bool get isSuitableForCalls {
    return isConnected &&
        (status == NetworkStatus.wifi ||
            status == NetworkStatus.cellular ||
            status == NetworkStatus.ethernet) &&
        quality != NetworkQuality.poor &&
        quality != NetworkQuality.unstable;
  }

  /// Check if this represents a network type change.
  bool hasNetworkTypeChanged(NetworkState previous) {
    return status != previous.status && isConnected && previous.isConnected;
  }

  @override
  String toString() {
    return 'NetworkState(status: $status, quality: $quality, '
        'isConnected: $isConnected, connectionType: $connectionType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NetworkState &&
        other.status == status &&
        other.quality == quality &&
        other.isConnected == isConnected;
  }

  @override
  int get hashCode => Object.hash(status, quality, isConnected);
}

/// Types of network changes.
enum NetworkChangeType {
  /// Network type changed (e.g., WiFi to cellular).
  typeChanged,

  /// Network was lost.
  disconnected,

  /// Network was recovered after disconnection.
  reconnected,

  /// Network quality changed.
  qualityChanged,

  /// Initial connection established or baseline snapshot.
  initial,
}

/// Event emitted when network changes.
class NetworkChangeEvent {
  final NetworkState previousState;
  final NetworkState currentState;
  final DateTime timestamp;
  final NetworkChangeType changeType;

  const NetworkChangeEvent({
    required this.previousState,
    required this.currentState,
    required this.timestamp,
    required this.changeType,
  });

  /// Whether this change requires call reconnection.
  ///
  /// Reconnect on network type change or recovery from disconnection.
  bool get requiresReconnection {
    return changeType == NetworkChangeType.typeChanged ||
        changeType == NetworkChangeType.reconnected;
  }
}
