import Flutter
import UIKit

final class NativeMapCommandBus {
  static let shared = NativeMapCommandBus()
  private weak var activeView: NativeMapPlatformView?

  func attach(_ view: NativeMapPlatformView) {
    activeView = view
  }

  func handle(_ call: FlutterMethodCall, result: FlutterResult) {
    switch call.method {
    case "setMarkers":
      let pois = call.arguments as? [[String: Any]] ?? []
      activeView?.setPois(pois)
      result(nil)
    case "moveCamera":
      activeView?.setStatus("移动地图中心: \(String(describing: call.arguments))")
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

final class NativeMapViewFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    let params = args as? [String: Any]
    let pois = params?["pois"] as? [[String: Any]] ?? []
    return NativeMapPlatformView(frame: frame, viewId: viewId, messenger: messenger, pois: pois)
  }
}

final class NativeMapPlatformView: NSObject, FlutterPlatformView {
  private let root = UIView()
  private let title = UILabel()
  private let subtitle = UILabel()

  init(frame: CGRect, viewId: Int64, messenger: FlutterBinaryMessenger, pois: [[String: Any]]) {
    super.init()

    root.frame = frame
    root.backgroundColor = UIColor(red: 232 / 255, green: 240 / 255, blue: 232 / 255, alpha: 1)

    title.text = "高德原生地图 SDK 接入点"
    title.textColor = UIColor(red: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 1)
    title.font = .systemFont(ofSize: 18, weight: .bold)
    title.textAlignment = .center

    subtitle.textColor = UIColor(red: 92 / 255, green: 103 / 255, blue: 92 / 255, alpha: 1)
    subtitle.font = .systemFont(ofSize: 13, weight: .medium)
    subtitle.textAlignment = .center
    subtitle.numberOfLines = 0

    let stack = UIStackView(arrangedSubviews: [title, subtitle])
    stack.axis = .vertical
    stack.spacing = 8
    stack.alignment = .center
    stack.translatesAutoresizingMaskIntoConstraints = false

    root.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.centerXAnchor.constraint(equalTo: root.centerXAnchor),
      stack.centerYAnchor.constraint(equalTo: root.centerYAnchor),
      stack.leadingAnchor.constraint(greaterThanOrEqualTo: root.leadingAnchor, constant: 24),
      stack.trailingAnchor.constraint(lessThanOrEqualTo: root.trailingAnchor, constant: -24),
    ])

    setPois(pois)
    NativeMapCommandBus.shared.attach(self)
  }

  func view() -> UIView {
    root
  }

  func setPois(_ pois: [[String: Any]]) {
    if pois.isEmpty {
      subtitle.text = "等待 Flutter 传入 POI"
      return
    }

    let names = pois.prefix(4).compactMap { $0["name"] as? String }.joined(separator: " / ")
    subtitle.text = "Flutter 已传入 \(pois.count) 个 POI：\(names)"
  }

  func setStatus(_ message: String) {
    subtitle.text = message
  }
}
