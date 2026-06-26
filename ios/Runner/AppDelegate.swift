import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "GoPlanNativeMap") {
      registrar.register(
        NativeMapViewFactory(messenger: registrar.messenger()),
        withId: "goplan/native_map_view"
      )

      let channel = FlutterMethodChannel(
        name: "goplan/native_map",
        binaryMessenger: registrar.messenger()
      )
      channel.setMethodCallHandler { call, result in
        NativeMapCommandBus.shared.handle(call, result: result)
      }
    }
  }
}
