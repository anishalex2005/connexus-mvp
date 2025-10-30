# ADR-001: VOIP Architecture Decision

**Status:** Proposed  
**Date:** 2025-10-29  
**Deciders:** [Team Members]

## Context

ConnexUS requires a robust VOIP implementation to handle voice calls through the Telnyx network. We need to choose between several implementation approaches that balance development speed, maintainability, and feature completeness.

## Decision Drivers

1. **Time to Market:** MVP must be delivered in 8 weeks
2. **Developer Resources:** 1-3 Flutter developers with variable availability
3. **Platform Parity:** Must work on both iOS and Android
4. **Call Quality:** Latency must be <150ms
5. **Features Required:**
   - Inbound/Outbound calls
   - Call transfer
   - SMS during calls
   - AI agent integration
6. **Maintenance:** Solution must be maintainable by small team

## Considered Options

### Option 1: Native SDKs with Platform Channels

**Description:** Use Telnyx native SDKs for each platform, bridged to Flutter via platform channels.

**Pros:**

- Full feature access
- Best performance
- Native UI integration possible
- Official SDK support

**Cons:**

- High implementation complexity
- Requires platform-specific expertise
- Longer development time (5-7 days)
- Maintenance overhead for two codebases

### Option 2: WebRTC Direct Implementation

**Description:** Use flutter_webrtc package with manual SIP signaling.

**Pros:**

- Single codebase
- Good performance
- Full control over implementation
- Platform-agnostic

**Cons:**

- Complex SIP implementation
- Limited documentation
- Higher bug risk
- No official support

### Option 3: Telnyx Voice API + WebSocket + WebRTC

**Description:** Hybrid approach using Voice API for control and WebRTC for media.

**Pros:**

- Balanced complexity
- Good documentation
- Incremental implementation possible
- Easier debugging
- RESTful API familiar to team

**Cons:**

- Potential latency in call setup
- Additional API calls required
- WebSocket connection management

## Decision

**We will use Option 3: Telnyx Voice API + WebSocket + WebRTC**

## Rationale

1. **Fastest Time to MVP:** Can implement core features in 2-3 days
2. **Lower Complexity:** RESTful APIs are familiar to the team
3. **Incremental Development:** Can add features progressively
4. **Better Debugging:** Clear separation of control and media planes
5. **Documentation:** Telnyx Voice API has excellent documentation
6. **Flexibility:** Can migrate to native SDKs post-MVP if needed

## Implementation Plan

### Phase 1: Core Implementation (Tasks 13-18)

```dart
// lib/services/telephony/telnyx_service.dart
class TelnyxService {
  // Voice API for call control
  final VoiceAPIClient voiceAPI;
  
  // WebSocket for real-time events
  final WebSocketManager websocket;
  
  // WebRTC for media handling
  final WebRTCManager webrtc;
  
  Future makeCall(String to) async {
    // 1. Create call via Voice API
    final callData = await voiceAPI.createCall(to);
    
    // 2. Establish WebRTC connection
    await webrtc.connect(callData.sdp);
    
    // 3. Return call handle
    return Call(callData.id, webrtc.stream);
  }
}
```

### Phase 2: Platform Integration (Tasks 82-83)

- Add CallKit for iOS
- Add ConnectionService for Android (post-MVP)

### Phase 3: Advanced Features (Post-MVP)

- Migrate to native SDKs if performance requires

## Consequences

### Positive

- Rapid development possible
- Clear upgrade path
- Lower initial complexity
- Easier onboarding for new developers

### Negative

- May need refactoring for native SDKs later
- Slightly higher latency than native SDKs
- Additional service dependencies (WebSocket server)

### Risks & Mitigation

| Risk | Mitigation |
|------|------------|
| WebSocket disconnections | Implement robust reconnection logic |
| API rate limits | Implement caching and request queuing |
| WebRTC complexity | Use established flutter_webrtc package |
| Call quality issues | Monitor metrics, fallback to native if needed |

## Validation Metrics

Success will be measured by:

- Call connection time < 5 seconds
- Call quality latency < 150ms  
- Successful implementation within 3 days
- 99% call completion rate in testing

## Review Date

This decision will be reviewed after Task 18 (Test Call Quality Metrics) and can be revised if metrics are not met.

## Sign-off

- [ ] Technical Lead
- [ ] Project Manager
- [ ] Lead Developer
