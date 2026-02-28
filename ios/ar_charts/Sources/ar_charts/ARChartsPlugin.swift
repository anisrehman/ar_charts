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
        case "updateLineChart":
            if let args = call.arguments as? [String: Any],
               let viewIdNum = args["viewId"] as? NSNumber,
               let params = args["params"] as? [String: Any] {
                let viewId = viewIdNum.int64Value
                ChartViewRegistry.getLineChart(viewId: viewId)?.updateConfig(params: params)
            }
            result(nil)
        case "updateBarChart":
            if let args = call.arguments as? [String: Any],
               let viewIdNum = args["viewId"] as? NSNumber,
               let params = args["params"] as? [String: Any] {
                let viewId = viewIdNum.int64Value
                ChartViewRegistry.getBarChart(viewId: viewId)?.updateConfig(params: params)
            }
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
