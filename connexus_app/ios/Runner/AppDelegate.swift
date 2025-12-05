import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var audioHandler: AudioHandler?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController

    let audioChannel = FlutterMethodChannel(
      name: "com.connexus/audio",
      binaryMessenger: controller.binaryMessenger
    )

    audioHandler = AudioHandler()
    audioChannel.setMethodCallHandler { [weak self] call, result in
      self?.audioHandler?.handle(call, result: result)
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
