import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:rxdart/rxdart.dart';

import '../../core/utils/logger.dart' as app_logger;
import '../../domain/models/connection_state.dart';
import '../../domain/models/webrtc_config.dart';

/// Manages WebRTC peer connections for voice calls.
class WebRTCConnectionManager {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  final WebRTCConfig _config;

  // Stream controllers for state management.
  final BehaviorSubject<WebRTCConnectionState> _connectionStateController =
      BehaviorSubject<WebRTCConnectionState>.seeded(
    WebRTCConnectionState.idle,
  );
  final BehaviorSubject<ConnectionQuality> _connectionQualityController =
      BehaviorSubject<ConnectionQuality>.seeded(
    const ConnectionQuality(),
  );
  final StreamController<RTCIceCandidate> _iceCandidateController =
      StreamController<RTCIceCandidate>.broadcast();

  // Quality monitoring timer.
  Timer? _qualityMonitorTimer;

  // Reconnection state.
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 2);

  WebRTCConnectionManager({WebRTCConfig? config})
      : _config = config ?? WebRTCConfig.telnyxDefault();

  // Public streams.
  Stream<WebRTCConnectionState> get connectionState =>
      _connectionStateController.stream;

  Stream<ConnectionQuality> get connectionQuality =>
      _connectionQualityController.stream;

  /// Latest connection quality snapshot.
  ConnectionQuality get currentQuality => _connectionQualityController.value;

  Stream<RTCIceCandidate> get iceCandidates => _iceCandidateController.stream;

  // Current state getters.
  WebRTCConnectionState get currentState => _connectionStateController.value;

  RTCPeerConnection? get peerConnection => _peerConnection;

  MediaStream? get localStream => _localStream;

  MediaStream? get remoteStream => _remoteStream;

  /// Initialize the WebRTC connection.
  Future<void> initialize() async {
    app_logger.Logger.info('Initializing WebRTC connection manager');
    _updateState(WebRTCConnectionState.connecting);

    try {
      _peerConnection = await createPeerConnection(
        _config.toRTCConfiguration(),
      );
      _setupPeerConnectionListeners();
      app_logger.Logger.info('WebRTC peer connection created successfully');
    } catch (e, stackTrace) {
      app_logger.Logger.error(
        'Failed to initialize WebRTC',
        e,
        stackTrace,
      );
      _updateState(WebRTCConnectionState.failed, reason: e.toString());
      rethrow;
    }
  }

  /// Set up all peer connection event listeners.
  void _setupPeerConnectionListeners() {
    final RTCPeerConnection? pc = _peerConnection;
    if (pc == null) return;

    // ICE Connection State.
    pc.onIceConnectionState = (RTCIceConnectionState state) {
      app_logger.Logger.debug('ICE connection state changed: $state');
      _handleIceConnectionState(state);
    };

    // ICE Gathering State.
    pc.onIceGatheringState = (RTCIceGatheringState state) {
      app_logger.Logger.debug('ICE gathering state: $state');
      if (state == RTCIceGatheringState.RTCIceGatheringStateGathering) {
        _updateState(WebRTCConnectionState.gatheringIceCandidates);
      }
    };

    // ICE Candidates.
    pc.onIceCandidate = (RTCIceCandidate candidate) {
      app_logger.Logger.debug('New ICE candidate: ${candidate.candidate}');
      _iceCandidateController.add(candidate);
    };

    // Connection State (newer API).
    pc.onConnectionState = (RTCPeerConnectionState state) {
      app_logger.Logger.debug('Peer connection state: $state');
      _handlePeerConnectionState(state);
    };

    // Track events for remote streams.
    pc.onTrack = (RTCTrackEvent event) {
      app_logger.Logger.info('Remote track received: ${event.track.kind}');
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
      }
    };

    // Signaling state.
    pc.onSignalingState = (RTCSignalingState state) {
      app_logger.Logger.debug('Signaling state: $state');
    };
  }

  /// Handle ICE connection state changes.
  void _handleIceConnectionState(RTCIceConnectionState state) {
    switch (state) {
      case RTCIceConnectionState.RTCIceConnectionStateNew:
      case RTCIceConnectionState.RTCIceConnectionStateChecking:
        _updateState(WebRTCConnectionState.connecting);
        break;
      case RTCIceConnectionState.RTCIceConnectionStateConnected:
      case RTCIceConnectionState.RTCIceConnectionStateCompleted:
        _onConnectionEstablished();
        break;
      case RTCIceConnectionState.RTCIceConnectionStateFailed:
        // ignore: discarded_futures
        _handleConnectionFailure();
        break;
      case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
        // ignore: discarded_futures
        _handleDisconnection();
        break;
      case RTCIceConnectionState.RTCIceConnectionStateClosed:
        _updateState(WebRTCConnectionState.closed);
        break;
      default:
        break;
    }
  }

  /// Handle peer connection state changes.
  void _handlePeerConnectionState(RTCPeerConnectionState state) {
    switch (state) {
      case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
        _updateState(WebRTCConnectionState.connecting);
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
        _onConnectionEstablished();
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
        // ignore: discarded_futures
        _handleConnectionFailure();
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        // ignore: discarded_futures
        _handleDisconnection();
        break;
      case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
        _updateState(WebRTCConnectionState.closed);
        break;
      default:
        break;
    }
  }

  /// Called when connection is successfully established.
  void _onConnectionEstablished() {
    app_logger.Logger.info('WebRTC connection established successfully');
    _reconnectAttempts = 0;
    _updateState(WebRTCConnectionState.connected);
    _startQualityMonitoring();
  }

  /// Handle connection failure.
  Future<void> _handleConnectionFailure() async {
    app_logger.Logger.warning('WebRTC connection failed');

    if (_reconnectAttempts < _maxReconnectAttempts) {
      _updateState(WebRTCConnectionState.reconnecting);
      await _attemptReconnection();
    } else {
      _updateState(
        WebRTCConnectionState.failed,
        reason: 'Max reconnection attempts exceeded',
      );
    }
  }

  /// Handle disconnection (may be temporary).
  Future<void> _handleDisconnection() async {
    app_logger.Logger.warning('WebRTC connection disconnected');
    _stopQualityMonitoring();

    // Give it a moment to see if it recovers automatically.
    await Future<void>.delayed(const Duration(seconds: 2));

    if (currentState != WebRTCConnectionState.connected) {
      _updateState(WebRTCConnectionState.reconnecting);
      await _attemptReconnection();
    }
  }

  /// Attempt to reconnect.
  Future<void> _attemptReconnection() async {
    _reconnectAttempts++;
    app_logger.Logger.info(
      'Attempting reconnection (attempt $_reconnectAttempts/$_maxReconnectAttempts)',
    );

    try {
      await _peerConnection?.close();

      // Wait before reconnecting (exponential backoff).
      final Duration delay = _reconnectDelay * _reconnectAttempts;
      await Future<void>.delayed(delay);

      // Reinitialize.
      await initialize();

      // If we had local media, re-add it.
      final MediaStream? local = _localStream;
      if (local != null) {
        await addLocalStream(local);
      }
    } catch (e, stackTrace) {
      app_logger.Logger.error(
        'Reconnection attempt failed',
        e,
        stackTrace,
      );
      if (_reconnectAttempts >= _maxReconnectAttempts) {
        _updateState(
          WebRTCConnectionState.failed,
          reason: 'Reconnection failed after $_maxReconnectAttempts attempts',
        );
      }
    }
  }

  /// Force a reconnection attempt.
  Future<void> forceReconnect() async {
    _reconnectAttempts = 0;
    _updateState(WebRTCConnectionState.reconnecting);
    await _attemptReconnection();
  }

  /// Start monitoring connection quality.
  void _startQualityMonitoring() {
    _stopQualityMonitoring();

    _qualityMonitorTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) {
        // ignore: discarded_futures
        _collectQualityMetrics();
      },
    );
  }

  /// Stop quality monitoring.
  void _stopQualityMonitoring() {
    _qualityMonitorTimer?.cancel();
    _qualityMonitorTimer = null;
  }

  /// Collect and emit quality metrics.
  Future<void> _collectQualityMetrics() async {
    final RTCPeerConnection? pc = _peerConnection;
    if (pc == null) return;

    try {
      // flutter_webrtc >= 1.x returns a Map<String, dynamic> for getStats.
      final dynamic stats = await pc.getStats();

      double? packetsLost;
      double? jitter;
      double? roundTripTime;
      int? bitrate;

      if (stats is Map) {
        for (final dynamic entry in stats.values) {
          if (entry is! Map) continue;
          final Map<String, dynamic> report = entry.cast<String, dynamic>();
          final String? type = report['type'] as String?;
          final Map<String, dynamic> values =
              (report['values'] as Map?)?.cast<String, dynamic>() ??
                  <String, dynamic>{};

          if (type == 'inbound-rtp' && values['kind'] == 'audio') {
            packetsLost = (values['packetsLost'] as num?)?.toDouble();
            jitter = (values['jitter'] as num?)?.toDouble();
          }

          if (type == 'candidate-pair' && values['state'] == 'succeeded') {
            roundTripTime =
                (values['currentRoundTripTime'] as num?)?.toDouble();
            if (roundTripTime != null) {
              roundTripTime *= 1000; // Convert to milliseconds.
            }
          }

          if (type == 'outbound-rtp' && values['kind'] == 'audio') {
            final int? bytesSent = values['bytesSent'] as int?;
            if (bytesSent != null) {
              // Rough bitrate estimate over 2 seconds.
              bitrate = bytesSent * 8 ~/ 2;
            }
          }
        }
      }

      final ConnectionQuality quality = ConnectionQuality(
        packetsLost: packetsLost,
        jitter: jitter,
        roundTripTime: roundTripTime,
        bitrate: bitrate,
        qualityLevel:
            _calculateQualityLevel(roundTripTime, packetsLost, jitter),
      );

      _connectionQualityController.add(quality);
      app_logger.Logger.debug('Connection quality: $quality');
    } catch (e, stackTrace) {
      app_logger.Logger.warning(
        'Failed to collect quality metrics',
        <String, dynamic>{
          'error': e,
          'stackTrace': stackTrace.toString(),
        },
      );
    }
  }

  /// Calculate quality level based on metrics.
  String _calculateQualityLevel(
    double? rtt,
    double? packetsLost,
    double? jitter,
  ) {
    if (rtt == null) return 'unknown';

    int score = 100;

    // RTT scoring.
    if (rtt > 400) {
      score -= 40;
    } else if (rtt > 200) {
      score -= 20;
    } else if (rtt > 100) {
      score -= 10;
    }

    // Packet loss scoring.
    if (packetsLost != null) {
      if (packetsLost > 5) {
        score -= 30;
      } else if (packetsLost > 2) {
        score -= 15;
      } else if (packetsLost > 0.5) {
        score -= 5;
      }
    }

    // Jitter scoring.
    if (jitter != null) {
      if (jitter > 50) {
        score -= 20;
      } else if (jitter > 30) {
        score -= 10;
      } else if (jitter > 15) {
        score -= 5;
      }
    }

    if (score >= 80) return 'excellent';
    if (score >= 60) return 'good';
    if (score >= 40) return 'fair';
    return 'poor';
  }

  /// Add local media stream to the connection.
  Future<void> addLocalStream(MediaStream stream) async {
    final RTCPeerConnection? pc = _peerConnection;
    if (pc == null) {
      throw StateError('Peer connection not initialized');
    }

    _localStream = stream;
    for (final MediaStreamTrack track in stream.getTracks()) {
      await pc.addTrack(track, stream);
    }

    app_logger.Logger.info(
      'Local stream added with ${stream.getTracks().length} tracks',
    );
  }

  /// Create and set local description (offer).
  Future<RTCSessionDescription> createOffer() async {
    final RTCPeerConnection? pc = _peerConnection;
    if (pc == null) {
      throw StateError('Peer connection not initialized');
    }

    final RTCSessionDescription offer = await pc.createOffer(<String, dynamic>{
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': false,
    });

    await pc.setLocalDescription(offer);
    app_logger.Logger.info('Local offer created and set');
    return offer;
  }

  /// Create and set local description (answer).
  Future<RTCSessionDescription> createAnswer() async {
    final RTCPeerConnection? pc = _peerConnection;
    if (pc == null) {
      throw StateError('Peer connection not initialized');
    }

    final RTCSessionDescription answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);
    app_logger.Logger.info('Local answer created and set');
    return answer;
  }

  /// Set remote description.
  Future<void> setRemoteDescription(RTCSessionDescription description) async {
    final RTCPeerConnection? pc = _peerConnection;
    if (pc == null) {
      throw StateError('Peer connection not initialized');
    }

    await pc.setRemoteDescription(description);
    app_logger.Logger.info('Remote description set');
  }

  /// Add ICE candidate from remote peer.
  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    final RTCPeerConnection? pc = _peerConnection;
    if (pc == null) {
      throw StateError('Peer connection not initialized');
    }

    await pc.addCandidate(candidate);
    app_logger.Logger.debug('Remote ICE candidate added');
  }

  /// Update state and notify listeners.
  void _updateState(WebRTCConnectionState state, {String? reason}) {
    _connectionStateController.add(state);
    final String message =
        'Connection state changed to: $state${reason != null ? ' ($reason)' : ''}';
    app_logger.Logger.info(message);
  }

  /// Close the connection and clean up resources.
  Future<void> dispose() async {
    app_logger.Logger.info('Disposing WebRTC connection manager');

    _stopQualityMonitoring();

    // Close streams.
    await _localStream?.dispose();
    await _remoteStream?.dispose();

    // Close peer connection.
    await _peerConnection?.close();

    // Close stream controllers.
    await _connectionStateController.close();
    await _connectionQualityController.close();
    await _iceCandidateController.close();

    _peerConnection = null;
    _localStream = null;
    _remoteStream = null;
  }
}
