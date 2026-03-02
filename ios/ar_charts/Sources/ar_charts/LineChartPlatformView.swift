import Flutter
import UIKit
import DGCharts

final class LineChartViewFactory: NSObject, FlutterPlatformViewFactory {
    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        let params = args as? [String: Any] ?? [:]
        return LineChartPlatformView(frame: frame, viewId: viewId, params: params)
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

final class LineChartPlatformView: NSObject, FlutterPlatformView {
    private let chartView: LineChartView
    private let viewId: Int64

    init(frame: CGRect, viewId: Int64, params: [String: Any]) {
        self.chartView = LineChartView(frame: frame)
        self.viewId = viewId
        super.init()
        ChartViewRegistry.registerLineChart(viewId: viewId, view: self)
        applyConfig(params: params)
    }

    deinit {
        ChartViewRegistry.unregisterLineChart(viewId: viewId)
    }

    func view() -> UIView {
        return chartView
    }

    func updateConfig(params: [String: Any]) {
        applyConfig(params: params)
    }

    private func applyConfig(params: [String: Any]) {
        let series = params["series"] as? [[String: Any]] ?? []
        let defaultStyle = params["defaultLineStyle"] as? [String: Any]
        let perSeriesStyle = params["perSeriesStyle"] as? [String: Any]

        var dataSets: [LineChartDataSet] = []
        for item in series {
            let points = item["points"] as? [[String: Any]] ?? []
            let entries: [ChartDataEntry] = points.compactMap { point in
                guard let x = point["x"] as? Double,
                      let y = point["y"] as? Double else { return nil }
                return ChartDataEntry(x: x, y: y)
            }
            let label = item["label"] as? String ?? ""
            let dataSet = LineChartDataSet(entries: entries, label: label)

            let seriesId = item["id"] as? String
            let styleMap = seriesId.flatMap { perSeriesStyle?[$0] as? [String: Any] } ?? defaultStyle
            applyLineStyle(dataSet: dataSet, styleMap: styleMap)
            dataSets.append(dataSet)
        }

        chartView.data = LineChartData(dataSets: dataSets)

        applyAxis(axis: chartView.xAxis, axisMap: params["xAxis"] as? [String: Any], isXAxis: true)
        applyAxis(axis: chartView.leftAxis, axisMap: params["leftAxis"] as? [String: Any], isXAxis: false)
        applyAxis(axis: chartView.rightAxis, axisMap: params["rightAxis"] as? [String: Any], isXAxis: false)

        applyLegend(legendMap: params["legend"] as? [String: Any])
        applyInteraction(interactionMap: params["interaction"] as? [String: Any])
        applyViewport(viewportMap: params["viewport"] as? [String: Any])
        applyMarker(markerMap: params["marker"] as? [String: Any])
        applyAnimation(animationMap: params["animation"] as? [String: Any])

        chartView.chartDescription.enabled = false
        chartView.notifyDataSetChanged()
    }

    private func applyLineStyle(dataSet: LineChartDataSet, styleMap: [String: Any]?) {
        guard let styleMap else { return }

        if let lineColor = styleMap["lineColor"] as? Int {
            dataSet.colors = [UIColor(argb: lineColor)]
        }
        if let lineWidth = styleMap["lineWidth"] as? Double {
            dataSet.lineWidth = lineWidth
        }
        if let drawCircles = styleMap["drawCircles"] as? Bool {
            dataSet.drawCirclesEnabled = drawCircles
        }
        if let circleColor = styleMap["circleColor"] as? Int {
            dataSet.circleColors = [UIColor(argb: circleColor)]
        } else if let lineColor = styleMap["lineColor"] as? Int {
            dataSet.circleColors = [UIColor(argb: lineColor)]
        }
        if let circleRadius = styleMap["circleRadius"] as? Double {
            dataSet.circleRadius = circleRadius
        }
        if let drawValues = styleMap["drawValues"] as? Bool {
            dataSet.drawValuesEnabled = drawValues
        }
        if let cubic = styleMap["cubic"] as? Bool, cubic == true {
            dataSet.mode = .cubicBezier
        }
        if let lineDashMap = styleMap["lineDash"] as? [String: Any],
           let lengthsRaw = lineDashMap["lengths"] as? [Any],
           lengthsRaw.count >= 2 {
            let lengths = lengthsRaw.compactMap { item -> CGFloat? in
                if let d = item as? Double { return CGFloat(d) }
                if let i = item as? Int { return CGFloat(i) }
                return nil
            }
            if lengths.count >= 2 {
                var phase: CGFloat = 0
                if let p = lineDashMap["phase"] as? Double { phase = CGFloat(p) }
                else if let p = lineDashMap["phase"] as? Int { phase = CGFloat(p) }
                dataSet.lineDashLengths = lengths
                dataSet.lineDashPhase = phase
            }
        }
        let fill = styleMap["fill"] as? String
        if fill == "solid" {
            dataSet.drawFilledEnabled = true
            let fillColor: UIColor
            if let fillColorArgb = styleMap["fillColor"] as? Int {
                fillColor = UIColor(argb: fillColorArgb)
            } else if let lineColorArgb = styleMap["lineColor"] as? Int {
                fillColor = UIColor(argb: lineColorArgb).withAlphaComponent(0.2)
            } else {
                fillColor = (dataSet.colors.first ?? .black).withAlphaComponent(0.2)
            }
            dataSet.fill = ColorFill(color: fillColor)
        } else if fill == "gradient" {
            dataSet.drawFilledEnabled = true
            let lineColorArgb = styleMap["lineColor"] as? Int ?? 0xFF000000
            let topArgb = styleMap["fillColorTop"] as? Int ?? lineColorArgb
            let bottomArgb = styleMap["fillColorBottom"] as? Int ?? 0
            let topColor = UIColor(argb: topArgb)
            let bottomColor = UIColor(argb: bottomArgb)
            let colors = [bottomColor.cgColor, topColor.cgColor]
            let locations: [CGFloat] = [0.0, 1.0]
            guard let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray,
                locations: locations
            ) else { return }
            dataSet.fill = LinearGradientFill(gradient: gradient, angle: 90)
        }
    }

    private func applyAxis(axis: AxisBase, axisMap: [String: Any]?, isXAxis: Bool) {
        guard let axisMap else { return }
        axis.enabled = axisMap["enabled"] as? Bool ?? true
        axis.drawGridLinesEnabled = axisMap["drawGridLines"] as? Bool ?? true
        axis.drawAxisLineEnabled = axisMap["drawAxisLine"] as? Bool ?? true

        if let min = axisMap["min"] as? Double { axis.axisMinimum = min }
        if let max = axisMap["max"] as? Double { axis.axisMaximum = max }
        if let labelCount = axisMap["labelCount"] as? Int { axis.setLabelCount(labelCount, force: true) }

        if let xAxis = axis as? XAxis, isXAxis {
            xAxis.labelPosition = .bottom
        }
        if let formatter = YAxisValueFormatter(axisMap: axisMap) {
            axis.valueFormatter = formatter
        }
    }

    private func applyLegend(legendMap: [String: Any]?) {
        guard let legendMap else { return }
        let legend = chartView.legend
        legend.enabled = legendMap["enabled"] as? Bool ?? true

        switch legendMap["position"] as? String {
        case "bottom":
            legend.verticalAlignment = .bottom
        case "left":
            legend.verticalAlignment = .top
            legend.horizontalAlignment = .left
        case "right":
            legend.verticalAlignment = .top
            legend.horizontalAlignment = .right
        default:
            legend.verticalAlignment = .top
            legend.horizontalAlignment = .center
        }

        switch legendMap["alignment"] as? String {
        case "start":
            legend.horizontalAlignment = .left
        case "end":
            legend.horizontalAlignment = .right
        default:
            legend.horizontalAlignment = .center
        }

        legend.orientation = .horizontal
        legend.drawInside = false
    }

    private func applyInteraction(interactionMap: [String: Any]?) {
        guard let interactionMap else { return }
        let zoomEnabled = interactionMap["zoomEnabled"] as? Bool ?? true
        let dragEnabled = interactionMap["dragEnabled"] as? Bool ?? true
        let highlightEnabled = interactionMap["highlightEnabled"] as? Bool ?? true

        chartView.scaleXEnabled = zoomEnabled
        chartView.scaleYEnabled = zoomEnabled
        chartView.doubleTapToZoomEnabled = zoomEnabled
        chartView.dragEnabled = dragEnabled
        chartView.highlightPerTapEnabled = highlightEnabled
    }

    private func applyViewport(viewportMap: [String: Any]?) {
        guard let viewportMap else { return }
        if let minRange = viewportMap["visibleXRangeMin"] as? Double {
            chartView.setVisibleXRangeMinimum(minRange)
        }
        if let maxRange = viewportMap["visibleXRangeMax"] as? Double {
            chartView.setVisibleXRangeMaximum(maxRange)
        }
        if let initialX = viewportMap["initialX"] as? Double {
            chartView.moveViewToX(initialX)
        }
        if let offsets = viewportMap["viewPortOffsets"] as? [String: Any] {
            let left = offsets["left"] as? Double ?? 0
            let top = offsets["top"] as? Double ?? 0
            let right = offsets["right"] as? Double ?? 0
            let bottom = offsets["bottom"] as? Double ?? 0
            chartView.setViewPortOffsets(left: left, top: top, right: right, bottom: bottom)
        }
    }

    private func applyMarker(markerMap: [String: Any]?) {
        guard let markerMap else { return }
        let enabled = markerMap["enabled"] as? Bool ?? false
        if !enabled { return }
        let marker = ChartMarkerView()
        marker.chartView = chartView
        chartView.marker = marker
    }

    private func applyAnimation(animationMap: [String: Any]?) {
        guard let animationMap else { return }
        let enabled = animationMap["enabled"] as? Bool ?? false
        if !enabled { return }
        let durationMs = animationMap["durationMs"] as? Double ?? 500
        let duration = durationMs / 1000.0
        switch animationMap["easing"] as? String {
        case "linear":
            chartView.animate(xAxisDuration: duration, easingOption: .linear)
        default:
            chartView.animate(xAxisDuration: duration, easingOption: .easeInOutQuad)
        }
    }
}
