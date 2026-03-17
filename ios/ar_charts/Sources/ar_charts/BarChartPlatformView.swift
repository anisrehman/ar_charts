import Flutter
import UIKit
import DGCharts

private let defaultAxisLabelColor = UIColor(argb: 0xFF333333)

final class BarChartViewFactory: NSObject, FlutterPlatformViewFactory {
    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        let params = args as? [String: Any] ?? [:]
        return BarChartPlatformView(frame: frame, viewId: viewId, params: params)
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

final class BarChartPlatformView: NSObject, FlutterPlatformView, ChartMarkerSupporting {
    private let chartView: BarChartView
    private let viewId: Int64
    var markerAutoHideSeconds: TimeInterval?
    var autoHideWorkItem: DispatchWorkItem?

    var chartViewForMarker: BarLineChartViewBase { chartView }

    init(frame: CGRect, viewId: Int64, params: [String: Any]) {
        self.chartView = BarChartView(frame: frame)
        self.viewId = viewId
        super.init()
        ChartViewRegistry.registerBarChart(viewId: viewId, view: self)
        applyConfig(params: params)
    }

    deinit {
        cancelMarkerAutoHide()
        ChartViewRegistry.unregisterBarChart(viewId: viewId)
    }

    func view() -> UIView {
        return chartView
    }

    func updateConfig(params: [String: Any]) {
        applyConfig(params: params)
    }

    private func applyConfig(params: [String: Any]) {
        let dataSetsPayload = params["dataSets"] as? [[String: Any]] ?? []
        let defaultStyle = params["defaultBarStyle"] as? [String: Any]
        let perSeriesStyle = params["perSeriesStyle"] as? [String: Any]
        let group = params["group"] as? [String: Any]
        let groupEnabled = group?["enabled"] as? Bool ?? false
        let groupedXAxisContext = groupEnabled ? buildGroupedXAxisContext(dataSetsPayload: dataSetsPayload) : nil

        var dataSets: [BarChartDataSet] = []
        var barWidth: Double?
        var labelMap: [Int: String] = [:]
        for (index, item) in dataSetsPayload.enumerated() {
            let points = item["points"] as? [[String: Any]] ?? []
            let entries: [BarChartDataEntry]
            if groupEnabled, let ctx = groupedXAxisContext {
                // groupBars positions by entry index: index i → group i. Emit entries in group order.
                var pointByX: [Double: Double] = [:]
                for point in points {
                    guard let x = point["x"] as? Double, let y = point["y"] as? Double else { continue }
                    pointByX[x] = y
                }
                entries = ctx.sourceValuesInOrder.enumerated().map { groupIndex, sourceX in
                    let y = pointByX[sourceX] ?? 0
                    let xLabel = ctx.groupLabels[safe: groupIndex] ?? formatXAxisValue(sourceX)
                    return BarChartDataEntry(
                        x: Double(groupIndex),
                        y: y,
                        data: ["sourceX": sourceX, "xLabel": xLabel] as NSDictionary
                    )
                }
            } else {
                entries = points.compactMap { point in
                    guard let x = point["x"] as? Double, let y = point["y"] as? Double else { return nil }
                    if index == 0, let label = point["label"] as? String {
                        labelMap[Int(x)] = label
                    }
                    return BarChartDataEntry(x: x, y: y)
                }
            }
            let label = item["label"] as? String ?? ""
            let dataSet = BarChartDataSet(entries: entries, label: label)

            let seriesId = item["id"] as? String
            let styleMap = seriesId.flatMap { perSeriesStyle?[$0] as? [String: Any] } ?? defaultStyle
            let styleWidth = applyBarStyle(dataSet: dataSet, styleMap: styleMap)
            if barWidth == nil, let styleWidth {
                barWidth = styleWidth
            }
            dataSets.append(dataSet)
        }

        let data = BarChartData(dataSets: dataSets)
        if let barWidth {
            data.barWidth = barWidth
        }
        chartView.data = data

        let xAxisMap = params["xAxis"] as? [String: Any]
        applyAxis(axis: chartView.xAxis, axisMap: xAxisMap, isXAxis: true)
        applyAxis(axis: chartView.leftAxis, axisMap: params["leftAxis"] as? [String: Any], isXAxis: false)
        applyAxis(axis: chartView.rightAxis, axisMap: params["rightAxis"] as? [String: Any], isXAxis: false)

        if groupEnabled {
            applyGroupedBars(barGroup: group, data: data, groupedXAxisContext: groupedXAxisContext)
        } else {
            applyBarPointLabels(axis: chartView.xAxis, labelMap: labelMap)
        }

        applyLegend(legendMap: params["legend"] as? [String: Any])
        applyInteraction(interactionMap: params["interaction"] as? [String: Any])
        applyMarker(markerMap: params["marker"] as? [String: Any])
        applyAnimation(animationMap: params["animation"] as? [String: Any])

        chartView.chartDescription.enabled = false
        chartView.notifyDataSetChanged()
    }

    private func applyBarStyle(dataSet: BarChartDataSet, styleMap: [String: Any]?) -> Double? {
        guard let styleMap else { return nil }

        if let barColor = styleMap["barColor"] as? Int {
            dataSet.colors = [UIColor(argb: barColor)]
        }
        if let drawValues = styleMap["drawValues"] as? Bool {
            dataSet.drawValuesEnabled = drawValues
        }
        return styleMap["barWidth"] as? Double
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

    private func applyBarPointLabels(axis: XAxis, labelMap: [Int: String]) {
        guard let maxIndex = labelMap.keys.max(), !labelMap.isEmpty else { return }
        var labels = (0...maxIndex).map { String($0) }
        for (index, label) in labelMap {
            if index >= 0 && index < labels.count {
                labels[index] = label
            }
        }
        axis.valueFormatter = IndexAxisValueFormatter(values: labels)
        axis.granularity = 1
        axis.granularityEnabled = true
    }

    private func applyGroupedBars(
        barGroup: [String: Any]?,
        data: BarChartData,
        groupedXAxisContext: GroupedXAxisContext?
    ) {
        guard let barGroup, data.dataSetCount > 1 else { return }
        let groupSpace = barGroup["groupSpace"] as? Double ?? 0.2
        let barSpace = barGroup["barSpace"] as? Double ?? 0.05
        let fromX = barGroup["fromX"] as? Double ?? 0
        let centerAxisLabels = barGroup["centerAxisLabels"] as? Bool ?? true

        data.groupBars(fromX: fromX, groupSpace: groupSpace, barSpace: barSpace)
        chartView.xAxis.centerAxisLabelsEnabled = centerAxisLabels
        chartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: groupedXAxisContext?.groupLabels ?? [])
        chartView.xAxis.granularity = 1
        chartView.xAxis.granularityEnabled = true

        let groupCount = groupedXAxisContext?.groupLabels.count ?? data.dataSets.first?.entryCount ?? 0
        let groupWidth = data.groupWidth(groupSpace: groupSpace, barSpace: barSpace)
        chartView.xAxis.axisMinimum = fromX
        chartView.xAxis.axisMaximum = fromX + groupWidth * Double(groupCount)
    }

    private func buildGroupedXAxisContext(dataSetsPayload: [[String: Any]]) -> GroupedXAxisContext {
        var pointsByX: [Double: String] = [:]
        for item in dataSetsPayload {
            let points = item["points"] as? [[String: Any]] ?? []
            for point in points {
                guard let x = point["x"] as? Double else { continue }
                if pointsByX[x] != nil { continue }
                pointsByX[x] = (point["label"] as? String) ?? formatXAxisValue(x)
            }
        }
        let sourceValuesInOrder = pointsByX.keys.sorted()
        let xToGroupIndex = Dictionary(uniqueKeysWithValues: sourceValuesInOrder.enumerated().map { ($0.element, $0.offset) })
        let groupLabels = sourceValuesInOrder.map { pointsByX[$0] ?? formatXAxisValue($0) }
        return GroupedXAxisContext(xToGroupIndex: xToGroupIndex, groupLabels: groupLabels, sourceValuesInOrder: sourceValuesInOrder)
    }

    private func formatXAxisValue(_ value: Double) -> String {
        if value == value.rounded() { return String(Int(value)) }
        return String(value)
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

// MARK: - ChartMarkerSupporting (ChartViewDelegate)
extension BarChartPlatformView {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        handleChartValueSelected(chartView, entry: entry, highlight: highlight)
    }

    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        handleChartValueNothingSelected(chartView)
    }
}

private struct GroupedXAxisContext {
    let xToGroupIndex: [Double: Int]
    let groupLabels: [String]
    let sourceValuesInOrder: [Double]
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
