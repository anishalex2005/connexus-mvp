# Call Handling Approaches Research

## Android Call Handling

### Approach 1: Foreground Service

```kotlin
// Required for calls to continue when app is backgrounded
class CallService : Service() {
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification = createCallNotification()
        startForeground(NOTIFICATION_ID, notification)
        return START_STICKY
    }
}
```

**AndroidManifest.xml additions:**

```xml
<!-- Add service declaration and foreground service permission as needed -->
```

### Approach 2: ConnectionService Integration

```kotlin
class TelnyxConnectionService : ConnectionService() {
    override fun onCreateIncomingConnection(
        connectionManagerPhoneAccount: PhoneAccountHandle?,
        request: ConnectionRequest?
    ): Connection {
        val connection = TelnyxConnection()
        connection.setRinging()
        return connection
    }
}
```

**Pros:**

- Native Android dialer integration
- Bluetooth handling automatic
- Car system integration

**Cons:**

- Complex implementation
- Android-specific (no iOS equivalent)

## iOS Call Handling

### CallKit Integration (Required for iOS)

```swift
import CallKit

class CallManager: CXProviderDelegate {
    private let provider: CXProvider
    private let callController = CXCallController()
    
    init() {
        let config = CXProviderConfiguration()
        config.supportsVideo = false
        config.maximumCallsPerCallGroup = 1
        config.supportedHandleTypes = [.phoneNumber]
        
        provider = CXProvider(configuration: config)
        super.init()
        provider.setDelegate(self, queue: nil)
    }
    
    func reportIncomingCall(uuid: UUID, handle: String, completion: @escaping (Error?) -> Void) {
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .phoneNumber, value: handle)
        
        provider.reportNewIncomingCall(with: uuid, update: update, completion: completion)
    }
}
```

### PushKit for VoIP Notifications

```swift
import PushKit

class PushKitManager: PKPushRegistryDelegate {
    func setupPushKit() {
        let pushRegistry = PKPushRegistry(queue: .main)
        pushRegistry.delegate = self
        pushRegistry.desiredPushTypes = [.voIP]
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
        // Handle incoming call push
        let callInfo = extractCallInfo(from: payload)
        CallManager.shared.reportIncomingCall(uuid: UUID(), handle: callInfo.from)
    }
}
```

## Background Handling Comparison

| Platform | Solution | Battery Impact | Reliability | Implementation |
|----------|----------|---------------|-------------|----------------|
| Android | Foreground Service | Medium | High | Medium |
| Android | ConnectionService | Low | Very High | Complex |
| iOS | CallKit | Low | Very High | Medium |
| iOS | PushKit | Very Low | Very High | Medium |

## Recommended Approach

1. **Android:** Use Foreground Service initially, migrate to ConnectionService post-MVP
2. **iOS:** CallKit + PushKit (required by Apple)
3. **Flutter:** Abstract platform differences in service layer
