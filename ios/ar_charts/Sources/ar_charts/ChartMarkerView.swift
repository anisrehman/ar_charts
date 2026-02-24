import UIKit
import DGCharts

/// Shared marker view for line and bar charts. Displays entry values using optional `{x}` and `{y}` format.
/// Sizes to content with 6pt padding (matches Android 6dp).
final class ChartMarkerView: MarkerView {
    private static let padding: CGFloat = 6

    private let format: String?
    private let textLabel = UILabel()

    init(format: String?) {
        self.format = format
        super.init(frame: CGRect(x: 0, y: 0, width: 40, height: 20))
        backgroundColor = UIColor.black.withAlphaComponent(0.8)
        layer.cornerRadius = 4
        layer.masksToBounds = true
        textLabel.textColor = .white
        textLabel.font = .systemFont(ofSize: 12)
        textLabel.textAlignment = .center
        textLabel.backgroundColor = .clear
        textLabel.numberOfLines = 0
        addSubview(textLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func refreshContent(entry: ChartDataEntry, highlight: Highlight) {
        let template = format ?? "x: {x}, y: {y}"
        var text = template
            .replacingOccurrences(of: "{x}", with: Self.formatLikeAndroid(entry.x))
            .replacingOccurrences(of: "{y}", with: Self.formatLikeAndroid(entry.y))
        text = text.replacingOccurrences(of: "\\n", with: "\n")
        textLabel.text = text
        let maxLabelWidth: CGFloat = 220
        let labelSize = textLabel.sizeThatFits(CGSize(width: maxLabelWidth, height: .greatestFiniteMagnitude))
        let p = Self.padding
        bounds = CGRect(x: 0, y: 0, width: labelSize.width + 2 * p, height: labelSize.height + 2 * p)
        textLabel.frame = CGRect(x: p, y: p, width: labelSize.width, height: labelSize.height)
    }

    /// Formats a number for marker display: whole numbers as "1.0", decimals limited to 2 places (e.g. 25886.45).
    private static func formatLikeAndroid(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.usesGroupingSeparator = false
        formatter.decimalSeparator = "."
        formatter.locale = Locale(identifier: "en_US_POSIX")
        guard let s = formatter.string(from: NSNumber(value: value)) else { return String(value) }
        if value.isFinite && !value.isNaN && value == value.rounded() {
            return s + ".0"
        }
        return s
    }

    override func offsetForDrawing(atPoint point: CGPoint) -> CGPoint {
        return CGPoint(x: -bounds.width / 2, y: -bounds.height)
    }
}
