import Flutter
import UIKit
import DGCharts

final class BarChartViewFactory: NSObject, FlutterPlatformViewFactory {
    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        let params = args as? [String: Any] ?? [:]
        return BarChartPlatformView(frame: frame, params: params)
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

final class BarChartPlatformView: NSObject, FlutterPlatformView {
    private let chartView: BarChartView
    private let params: [String: Any]

    init(frame: CGRect, params: [String: Any]) {
        self.chartView = BarChartView(frame: frame)
        self.params = params
        super.init()
        applyConfig()
    }

    func view() -> UIView {
        return chartView
    }

    private func applyConfig() {
        let series = params["series"] as? [[String: Any]] ?? []
        let defaultStyle = params["defaultBarStyle"] as? [String: Any]
        let perSeriesStyle = params["perSeriesStyle"] as? [String: Any]
        let barGroup = params["barGroup"] as? [String: Any]
        let groupEnabled = barGroup?["enabled"] as? Bool ?? false

        var dataSets: [BarChartDataSet] = []
        var barWidth: Double?
        var labelMap: [Int: String] = [:]
        for (index, item) in series.enumerated() {
            let points = item["points"] as? [[String: Any]] ?? []
            let entries: [BarChartDataEntry] = points.compactMap { point in
                guard let x = point["x"] as? Double,
                      let y = point["y"] as? Double else { return nil }
                if !groupEnabled, index == 0, let label = point["label"] as? String {
                    labelMap[Int(x)] = label
                }
                return BarChartDataEntry(x: x, y: y)
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
            applyGroupedBars(barGroup: barGroup, data: data)
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

    private func applyGroupedBars(barGroup: [String: Any]?, data: BarChartData) {
        guard let barGroup, data.dataSetCount > 1 else { return }
        let groupSpace = barGroup["groupSpace"] as? Double ?? 0.2
        let barSpace = barGroup["barSpace"] as? Double ?? 0.05
        let fromX = barGroup["fromX"] as? Double ?? 0
        let centerAxisLabels = barGroup["centerAxisLabels"] as? Bool ?? true

        data.groupBars(fromX: fromX, groupSpace: groupSpace, barSpace: barSpace)
        chartView.xAxis.centerAxisLabelsEnabled = centerAxisLabels

        let groupCount = data.dataSets.first?.entryCount ?? 0
        let groupWidth = data.groupWidth(groupSpace: groupSpace, barSpace: barSpace)
        chartView.xAxis.axisMinimum = fromX
        chartView.xAxis.axisMaximum = fromX + groupWidth * Double(groupCount)
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

    private func applyMarker(markerMap: [String: Any]?) {
        guard let markerMap else { return }
        let enabled = markerMap["enabled"] as? Bool ?? false
        if !enabled { return }
        let format = markerMap["format"] as? String
        let marker = ChartMarkerView(format: format)
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
