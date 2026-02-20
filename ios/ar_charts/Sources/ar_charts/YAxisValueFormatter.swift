import Foundation
import DGCharts

/// Formats Y-axis values: compact (1K, 1.5M, 1T), decimal, or percent.
/// Shared by BarChart and LineChart platform views.
final class YAxisValueFormatter: NSObject, AxisValueFormatter {
    private let formatType: String
    private let decimals: Int

    init?(axisMap: [String: Any]) {
        guard let type = axisMap["formatType"] as? String, type != "none" else { return nil }
        self.formatType = type
        self.decimals = axisMap["formatTypeDecimals"] as? Int ?? 1
    }

    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        switch formatType {
        case "compact":
            return Self.formatCompact(value)
        case "decimal":
            return String(format: "%.\(decimals)f", value)
        case "percent":
            return String(format: "%.\(decimals)f%%", value)
        default:
            return "\(value)"
        }
    }

    private static func formatCompact(_ value: Double) -> String {
        let absValue = abs(value)
        let sign = value < 0 ? "-" : ""
        if absValue >= 1_000_000_000_000 {
            return sign + String(format: "%.1fT", absValue / 1_000_000_000_000)
        }
        if absValue >= 1_000_000_000 {
            return sign + String(format: "%.1fB", absValue / 1_000_000_000)
        }
        if absValue >= 1_000_000 {
            return sign + String(format: "%.1fM", absValue / 1_000_000)
        }
        if absValue >= 1_000 {
            return sign + String(format: "%.1fK", absValue / 1_000)
        }
        if absValue >= 1 || absValue == 0 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.2f", value)
    }
}
