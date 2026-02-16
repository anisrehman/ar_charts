import Flutter
import UIKit

@objc(ARChartsPlugin)
public class ARChartsPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "ar_charts", binaryMessenger: registrar.messenger())
        let instance = ARChartsPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        let factory = LineChartViewFactory()
        registrar.register(factory, withId: "ar_charts/line_chart")
        let barFactory = BarChartViewFactory()
        registrar.register(barFactory, withId: "ar_charts/bar_chart")
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
