import UIKit
import DGCharts

/// Shared marker and auto-hide behavior for line and bar charts. Conform with a chart view
/// that is a `BarLineChartViewBase` and provide storage for `markerAutoHideSeconds` and
/// `autoHideWorkItem`; this extension provides `applyMarker(markerMap:)` and `ChartViewDelegate` implementation.
protocol ChartMarkerSupporting: AnyObject, ChartViewDelegate {
    var chartViewForMarker: BarLineChartViewBase { get }
    var markerAutoHideSeconds: TimeInterval? { get set }
    var autoHideWorkItem: DispatchWorkItem? { get set }
}

extension ChartMarkerSupporting {
    /// Apply marker config and optional auto-hide. Call from applyConfig when marker params are present.
    func applyMarker(markerMap: [String: Any]?) {
        cancelMarkerAutoHide()
        chartViewForMarker.delegate = nil
        chartViewForMarker.marker = nil

        guard let markerMap else { return }
        let enabled = markerMap["enabled"] as? Bool ?? false
        if !enabled { return }

        let marker = ChartMarkerView()
        marker.chartView = chartViewForMarker
        chartViewForMarker.marker = marker

        let autoHideSeconds: TimeInterval = (markerMap["autoHideDurationSeconds"] as? NSNumber)?.doubleValue ?? 3.5
        if autoHideSeconds > 0 {
            markerAutoHideSeconds = autoHideSeconds
            chartViewForMarker.delegate = self
        }
    }

    /// Cancel any scheduled auto-hide and clear delegate. Call from deinit.
    func cancelMarkerAutoHide() {
        autoHideWorkItem?.cancel()
        autoHideWorkItem = nil
        markerAutoHideSeconds = nil
        chartViewForMarker.delegate = nil
    }

    /// Called when a chart value is selected. Implementations should call this from their ChartViewDelegate method.
    func handleChartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        guard let seconds = markerAutoHideSeconds, seconds > 0 else { return }
        autoHideWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak chartView] in
            chartView?.highlightValues(nil)
        }
        autoHideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: workItem)
    }

    /// Called when selection is cleared. Implementations should call this from their ChartViewDelegate method.
    func handleChartValueNothingSelected(_ chartView: ChartViewBase) {
        autoHideWorkItem?.cancel()
        autoHideWorkItem = nil
    }

    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        handleChartValueSelected(chartView, entry: entry, highlight: highlight)
    }

    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        handleChartValueNothingSelected(chartView)
    }
}
