import Flutter
import UIKit
import DGCharts

private let defaultAxisLabelColor = UIColor(argb: 0xFF333333)

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

final class LineChartPlatformView: NSObject, FlutterPlatformView, ChartMarkerSupporting {
    private let chartView: XAxisMarkLineChartView
    private let viewId: Int64
    private var xAxisMarks: [XAxisMarkModel] = []
    private let markTapRecognizer = UITapGestureRecognizer()
    var markerAutoHideSeconds: TimeInterval?
    var autoHideWorkItem: DispatchWorkItem?

    var chartViewForMarker: BarLineChartViewBase { chartView }

    init(frame: CGRect, viewId: Int64, params: [String: Any]) {
        self.chartView = XAxisMarkLineChartView(frame: frame)
        self.viewId = viewId
        super.init()
        chartView.renderer = SelectedPointLineChartRenderer(
            dataProvider: chartView,
            animator: chartView.chartAnimator,
            viewPortHandler: chartView.viewPortHandler
        )
        markTapRecognizer.addTarget(self, action: #selector(handleMarkTap(_:)))
        markTapRecognizer.cancelsTouchesInView = false
        markTapRecognizer.delegate = self
        chartView.addGestureRecognizer(markTapRecognizer)
        ChartViewRegistry.registerLineChart(viewId: viewId, view: self)
        applyConfig(params: params)
    }

    deinit {
        cancelMarkerAutoHide()
        ChartViewRegistry.unregisterLineChart(viewId: viewId)
    }

    func view() -> UIView {
        return chartView
    }

    func updateConfig(params: [String: Any]) {
        applyConfig(params: params)
    }

    private func applyConfig(params: [String: Any]) {
        clearMarkTooltip()
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
            }.sorted { $0.x < $1.x }
            let label = item["label"] as? String ?? ""
            let dataSet = SelectedPointLineChartDataSet(entries: entries, label: label)

            let seriesId = item["id"] as? String
            let styleMap = seriesId.flatMap { perSeriesStyle?[$0] as? [String: Any] } ?? defaultStyle
            applyLineStyle(dataSet: dataSet, styleMap: styleMap)
            dataSets.append(dataSet)
        }

        chartView.data = LineChartData(dataSets: dataSets)

        applyAxis(axis: chartView.xAxis, axisMap: params["xAxis"] as? [String: Any], isXAxis: true)
        applyXAxisMarks(marks: params["xAxisMarks"] as? [[String: Any]])
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

    private func applyLineStyle(dataSet: SelectedPointLineChartDataSet, styleMap: [String: Any]?) {
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
        if let selectedPointMap = styleMap["selectedPoint"] as? [String: Any] {
            dataSet.selectedPointEnabled = selectedPointMap["enabled"] as? Bool ?? true
            dataSet.selectedPointColor = (selectedPointMap["color"] as? Int).map(UIColor.init(argb:))
            if let radius = selectedPointMap["radius"] as? Double {
                dataSet.selectedPointRadius = CGFloat(radius)
            } else if let radius = selectedPointMap["radius"] as? Int {
                dataSet.selectedPointRadius = CGFloat(radius)
            }
            dataSet.selectedPointStrokeColor = (selectedPointMap["strokeColor"] as? Int).map(UIColor.init(argb:))
            if let width = selectedPointMap["strokeWidth"] as? Double {
                dataSet.selectedPointStrokeWidth = CGFloat(width)
            } else if let width = selectedPointMap["strokeWidth"] as? Int {
                dataSet.selectedPointStrokeWidth = CGFloat(width)
            }
        } else {
            dataSet.selectedPointEnabled = false
            dataSet.selectedPointColor = nil
            dataSet.selectedPointStrokeColor = nil
            dataSet.selectedPointStrokeWidth = 0
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
        axis.labelTextColor = defaultAxisLabelColor
        axis.drawGridLinesEnabled = axisMap["drawGridLines"] as? Bool ?? true
        if let gridLineColor = axisMap["gridLineColor"] as? Int {
            axis.gridColor = UIColor(argb: gridLineColor)
        } else {
            axis.gridColor = axis.labelTextColor.withAlphaComponent(0.22)
        }
        if let gridLineWidth = axisMap["gridLineWidth"] as? Double {
            axis.gridLineWidth = gridLineWidth
        } else if let gridLineWidth = axisMap["gridLineWidth"] as? Int {
            axis.gridLineWidth = Double(gridLineWidth)
        }
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

    /// Labels at x positions only. Limit lines are not data entries, so they do not
    /// change the y-axis range. Keep in sync with Android applyXAxisMarks.
    private func applyXAxisMarks(marks: [[String: Any]]?) {
        let xAxis = chartView.xAxis
        xAxis.removeAllLimitLines()
        xAxis.drawLimitLinesBehindDataEnabled = false
        xAxisMarks = []
        guard let marks else { return }
        for markMap in marks {
            let x: Double
            if let value = markMap["x"] as? Double {
                x = value
            } else if let value = markMap["x"] as? Int {
                x = Double(value)
            } else {
                continue
            }
            guard let label = markMap["label"] as? String, !label.isEmpty else { continue }
            let tooltip = (markMap["tooltip"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? label
            xAxisMarks.append(XAxisMarkModel(x: x, label: label, tooltip: tooltip))
            let limitLine = ChartLimitLine(limit: x, label: label)
            limitLine.lineWidth = 0
            limitLine.lineColor = .clear
            if let color = markMap["color"] as? Int {
                limitLine.valueTextColor = UIColor(argb: color)
            } else {
                limitLine.valueTextColor = defaultAxisLabelColor
            }
            limitLine.valueFont = .systemFont(ofSize: XAxisMarkMetrics.textSize)
            limitLine.labelPosition = .rightBottom
            xAxis.addLimitLine(limitLine)
        }
    }

    /// The chart's own tap highlights a series point in the same turn. This runs
    /// afterward so a label tap can replace that highlight with the mark tooltip.
    @objc private func handleMarkTap(_ recognizer: UITapGestureRecognizer) {
        let point = recognizer.location(in: chartView)
        DispatchQueue.main.async { [weak self] in
            self?.showMarkTooltip(at: point)
        }
    }

    private func showMarkTooltip(at point: CGPoint) {
        guard chartView.marker != nil, let mark = markAt(point) else {
            if chartView.markTooltipText != nil {
                clearMarkTooltip()
                chartView.setNeedsDisplay()
            }
            return
        }
        chartView.markTooltipText = mark.tooltip
        chartView.markTooltipX = mark.x
        scheduleMarkTooltipHide()
        chartView.highlightValue(nil, callDelegate: false)
    }

    private func clearMarkTooltip() {
        chartView.markTooltipText = nil
        chartView.markTooltipX = nil
    }

    private func scheduleMarkTooltipHide() {
        autoHideWorkItem?.cancel()
        guard let seconds = markerAutoHideSeconds, seconds > 0 else { return }
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.clearMarkTooltip()
            self.chartView.highlightValue(nil, callDelegate: false)
        }
        autoHideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: workItem)
    }

    /// Matches XAxisRenderer.renderLimitLineLabel for `.rightBottom`.
    private func markAt(_ point: CGPoint) -> XAxisMarkModel? {
        guard !xAxisMarks.isEmpty else { return nil }
        let contentLeft = chartView.viewPortHandler.contentLeft
        let contentRight = chartView.viewPortHandler.contentRight
        let contentBottom = chartView.viewPortHandler.contentBottom
        let font = UIFont.systemFont(ofSize: XAxisMarkMetrics.textSize)
        let xOffset = XAxisMarkMetrics.lineWidth + XAxisMarkMetrics.xOffset
        let yOffset = 2.0 + XAxisMarkMetrics.yOffset
        let transformer = chartView.getTransformer(forAxis: .left)
        var closest: XAxisMarkModel?
        var closestDistance = CGFloat.greatestFiniteMagnitude
        for mark in xAxisMarks {
            let pixel = transformer.pixelForValues(x: mark.x, y: 0)
            if pixel.x < contentLeft || pixel.x > contentRight { continue }
            let textSize = mark.label.size(withAttributes: [.font: font])
            let rect = CGRect(
                x: pixel.x + xOffset,
                y: contentBottom - textSize.height - yOffset,
                width: textSize.width,
                height: textSize.height
            ).insetBy(dx: -XAxisMarkMetrics.touchSlop, dy: -XAxisMarkMetrics.touchSlop)
            if !rect.contains(point) { continue }
            let distance = abs(point.x - rect.midX)
            if distance < closestDistance {
                closest = mark
                closestDistance = distance
            }
        }
        return closest
    }

    private func applyLegend(legendMap: [String: Any]?) {
        guard let legendMap else { return }
        let legend = chartView.legend
        legend.enabled = legendMap["enabled"] as? Bool ?? true
        legend.textColor = defaultAxisLabelColor

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

private struct XAxisMarkModel {
    let x: Double
    let label: String
    let tooltip: String
}

private enum XAxisMarkMetrics {
    static let textSize: CGFloat = 10
    /// ChartLimitLine clamps a requested width of 0 to 0.2.
    static let lineWidth: CGFloat = 0.2
    static let xOffset: CGFloat = 5
    static let yOffset: CGFloat = 5
    static let touchSlop: CGFloat = 12
}

/// Draws an x-axis mark tooltip without adding a data entry. DGCharts only draws
/// markers for highlighted entries, and a mark has no y value.
private final class XAxisMarkLineChartView: LineChartView {
    var markTooltipText: String?
    var markTooltipX: Double?

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let text = markTooltipText,
              let x = markTooltipX,
              let marker = marker as? ChartMarkerView,
              let context = UIGraphicsGetCurrentContext() else { return }
        marker.refreshMark(text)
        let pixel = getTransformer(forAxis: .left).pixelForValues(x: x, y: 0)
        marker.draw(context: context, point: CGPoint(x: pixel.x, y: viewPortHandler.contentBottom))
    }
}

// MARK: - ChartMarkerSupporting (ChartViewDelegate) - It will be called by the framework when the user taps on a value.
extension LineChartPlatformView: UIGestureRecognizerDelegate {
    /// Only claim taps that land on an x-axis mark label. Every other tap stays
    /// with the chart so a line point can still show its marker.
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        gestureRecognizer === markTapRecognizer
            && markAt(touch.location(in: chartView)) != nil
    }
}

extension LineChartPlatformView {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        clearMarkTooltip()
        handleChartValueSelected(chartView, entry: entry, highlight: highlight)
    }

    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        handleChartValueNothingSelected(chartView)
    }
}
