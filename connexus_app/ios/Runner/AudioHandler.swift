import Foundation
import AVFoundation
import Flutter

class AudioHandler: NSObject {
  private let audioSession = AVAudioSession.sharedInstance()

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "setAudioMode":
      if
        let args = call.arguments as? [String: Any],
        let mode = args["mode"] as? String
      {
        setAudioMode(mode: mode, result: result)
      } else {
        result(
          FlutterError(
            code: "INVALID_ARGS",
            message: "Missing mode argument",
            details: nil
          )
        )
      }

    case "setSpeaker":
      if
        let args = call.arguments as? [String: Any],
        let enabled = args["enabled"] as? Bool
      {
        setSpeaker(enabled: enabled, result: result)
      } else {
        result(
          FlutterError(
            code: "INVALID_ARGS",
            message: "Missing enabled argument",
            details: nil
          )
        )
      }

    case "setMute":
      if
        let args = call.arguments as? [String: Any],
        let muted = args["muted"] as? Bool
      {
        setMute(muted: muted, result: result)
      } else {
        result(
          FlutterError(
            code: "INVALID_ARGS",
            message: "Missing muted argument",
            details: nil
          )
        )
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func setAudioMode(mode: String, result: @escaping FlutterResult) {
    do {
      switch mode {
      case "voice_call":
        try audioSession.setCategory(
          .playAndRecord,
          mode: .voiceChat,
          options: [.allowBluetooth, .defaultToSpeaker]
        )
        try audioSession.setActive(true)
      case "normal":
        try audioSession.setActive(false)
        try audioSession.setCategory(.ambient)
      default:
        break
      }
      result(true)
    } catch {
      result(
        FlutterError(
          code: "AUDIO_ERROR",
          message: error.localizedDescription,
          details: nil
        )
      )
    }
  }

  private func setSpeaker(enabled: Bool, result: @escaping FlutterResult) {
    do {
      if enabled {
        try audioSession.overrideOutputAudioPort(.speaker)
      } else {
        try audioSession.overrideOutputAudioPort(.none)
      }
      result(true)
    } catch {
      result(
        FlutterError(
          code: "SPEAKER_ERROR",
          message: error.localizedDescription,
          details: nil
        )
      )
    }
  }

  private func setMute(muted: Bool, result: @escaping FlutterResult) {
    // iOS does not expose direct microphone mute; this is expected to be
    // handled at the WebRTC / Telnyx SDK level. We simply report success.
    result(true)
  }
}


