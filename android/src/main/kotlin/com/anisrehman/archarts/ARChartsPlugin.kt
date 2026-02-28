package com.anisrehman.archarts

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class ARChartsPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "ar_charts")
        channel.setMethodCallHandler(this)
        flutterPluginBinding
            .platformViewRegistry
            .registerViewFactory(
                "ar_charts/line_chart",
                LineChartViewFactory()
            )
        flutterPluginBinding
            .platformViewRegistry
            .registerViewFactory(
                "ar_charts/bar_chart",
                BarChartViewFactory()
            )
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
            "updateLineChart" -> {
                val viewId = (call.arguments as? Map<*, *>)?.get("viewId") as? Number
                val params = (call.arguments as? Map<*, *>)?.get("params") as? Map<String, Any?>
                if (viewId != null && params != null) {
                    ChartViewRegistry.getLineChart(viewId.toInt())?.updateConfig(params)
                }
                result.success(null)
            }
            "updateBarChart" -> {
                val viewId = (call.arguments as? Map<*, *>)?.get("viewId") as? Number
                val params = (call.arguments as? Map<*, *>)?.get("params") as? Map<String, Any?>
                if (viewId != null && params != null) {
                    ChartViewRegistry.getBarChart(viewId.toInt())?.updateConfig(params)
                }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

}
