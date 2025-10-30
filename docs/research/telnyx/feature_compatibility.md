# Telnyx Feature Compatibility Matrix

## Core Features Required for MVP

| Feature | Voice API | WebRTC | Native SDK | Selected | Notes |
|---------|-----------|--------|------------|----------|-------|
| **Outbound Calls** | ✅ | ✅ | ✅ | Voice API + WebRTC | |
| **Inbound Calls** | ✅ | ✅ | ✅ | Voice API + WebRTC | Requires webhook |
| **Answer Call** | ✅ | ✅ | ✅ | Voice API + WebRTC | |
| **Decline Call** | ✅ | ✅ | ✅ | Voice API | |
| **End Call** | ✅ | ✅ | ✅ | Voice API | |
| **Hold/Resume** | ✅ | ⚠️ | ✅ | Voice API | Manual WebRTC handling |
| **Mute/Unmute** | ❌ | ✅ | ✅ | WebRTC | Local only |
| **DTMF** | ✅ | ✅ | ✅ | Voice API | |
| **Speaker Toggle** | ❌ | ✅ | ✅ | Platform-specific | |
| **Call Transfer** | ✅ | ❌ | ✅ | Voice API | |
| **SMS During Call** | ✅ | ❌ | ❌ | Voice API | Separate API |
| **Call Recording** | ✅ | ❌ | ✅ | Voice API | |
| **Call Quality Metrics** | ⚠️ | ✅ | ✅ | WebRTC | getStats() |
| **Network Handover** | ❌ | ⚠️ | ✅ | WebRTC | Manual implementation |

## Implementation Code Samples

### Voice API Call Creation

```dart
Future createCall(String to, String from) async {
  final response = await dio.post(
    'https://api.telnyx.com/v2/calls',
    data: {
      'connection_id': connectionId,
      'to': to,
      'from': from,
      'webhook_url': 'https://your-server.com/webhooks/telnyx',
      'webhook_url_method': 'POST',
      'answering_machine_detection': 'disabled',
    },
  );
  
  return CallResponse.fromJson(response.data);
}
```

### WebRTC Media Handling

```dart
class WebRTCMediaHandler {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  
  Future setupLocalMedia() async {
    final mediaConstraints = {
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': false,
    };
    
    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });
  }
  
  Future handleRemoteSDP(String sdp) async {
    final description = RTCSessionDescription(sdp, 'answer');
    await _peerConnection!.setRemoteDescription(description);
  }
  
  void toggleMute(bool mute) {
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = !mute;
    });
  }
}
```

## Platform-Specific Implementations

### iOS CallKit Integration Points

```swift
// When receiving call via Push Notification
func handleIncomingCall(callId: String, from: String) {
    // 1. Report to CallKit
    callManager.reportIncomingCall(uuid: UUID(callId), handle: from)
    
    // 2. On answer from CallKit
    callManager.onAnswer = {
        // 3. Accept via Telnyx Voice API
        TelnyxAPI.answerCall(callId)
        
        // 4. Setup WebRTC
        WebRTCManager.connectToCall(callId)
    }
}
```

### Android Foreground Service

```kotlin
class CallForegroundService : Service() {
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START_CALL -> startCall(intent)
            ACTION_END_CALL -> endCall()
            ACTION_ANSWER -> answerCall()
        }
        return START_STICKY
    }
    
    private fun startCall(intent: Intent) {
        val notification = buildCallNotification()
        startForeground(CALL_NOTIFICATION_ID, notification)
        
        // Initialize WebRTC
        webRTCManager.initialize()
        
        // Create call via API
        telnyxAPI.createCall(intent.getStringExtra("TO"))
    }
}
```

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| WebSocket disconnection during call | Medium | High | Implement exponential backoff reconnection |
| WebRTC negotiation failure | Low | High | Fallback to TURN servers |
| Voice API rate limiting | Low | Medium | Implement request queuing |
| Platform audio conflicts | Medium | Medium | Proper audio focus handling |
| Background call drops (Android) | Medium | High | Foreground service implementation |
| CallKit rejection (iOS) | Low | Critical | Follow Apple guidelines strictly |
