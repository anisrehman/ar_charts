import Foundation
import DGCharts

/// Formats axis values: compact (1K, 1.5M, 1T), decimal, percent, or date.
/// Shared by BarChart and LineChart platform views (X and Y axes).
final class YAxisValueFormatter: NSObject, AxisValueFormatter {
    private let formatType: String
    private let decimals: Int
    private let dateFormatPattern: String

    init?(axisMap: [String: Any]) {
        guard let type = axisMap["formatType"] as? String, type != "none" else { return nil }
        self.formatType = type
        self.decimals = axisMap["formatTypeDecimals"] as? Int ?? 1
        self.dateFormatPattern = axisMap["formatPattern"] as? String ?? "MMM d"
    }

    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        switch formatType {
        case "compact":
            return Self.formatCompact(value)
        case "decimal":
            return String(format: "%.\(decimals)f", value)
        case "percent":
            return String(format: "%.\(decimals)f%%", value)
        case "date":
            return Self.formatDate(millisSinceEpoch: value, pattern: dateFormatPattern)
        default:
            return "\(value)"
        }
    }

    private static func formatDate(millisSinceEpoch: Double, pattern: String) -> String {
        let date = Date(timeIntervalSince1970: millisSinceEpoch / 1000)
        let formatter = DateFormatter()
        formatter.dateFormat = pattern
        formatter.locale = Locale.current
        return formatter.string(from: date)
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
