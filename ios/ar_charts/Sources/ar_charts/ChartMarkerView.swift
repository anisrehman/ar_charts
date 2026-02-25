import UIKit
import DGCharts

/// Shared marker view for line and bar charts. Shows x-axis value on the first line,
/// then each series that has a point at that x with a colored bullet and formatted y.
/// Sizes to content with 6pt padding (matches Android 6dp).
final class ChartMarkerView: MarkerView {
    private static let padding: CGFloat = 6

    private let containerView = UIView()
    private let textLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 40, height: 20))
        commonInit()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func commonInit() {
        backgroundColor = .clear
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.25

        containerView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        containerView.layer.cornerRadius = 4
        containerView.layer.masksToBounds = true
        addSubview(containerView)

        textLabel.textColor = .white
        textLabel.font = .systemFont(ofSize: 12)
        textLabel.textAlignment = .natural
        textLabel.backgroundColor = .clear
        textLabel.numberOfLines = 0
        containerView.addSubview(textLabel)
    }

    override func refreshContent(entry: ChartDataEntry, highlight: Highlight) {
        guard let chart = chartView as? BarLineChartViewBase,
              let data = chart.data else {
            textLabel.attributedText = nil
            super.refreshContent(entry: entry, highlight: highlight)
            return
        }
        let refX = highlight.x
        let xFormatted = chart.xAxis.valueFormatter?.stringForValue(refX, axis: chart.xAxis)
            ?? Self.formatLikeAndroid(refX)
        let yAxis = chart.leftAxis
        let yFormatter = yAxis.valueFormatter
        let bullet: Character = "\u{2022}"
        let attr = NSMutableAttributedString()
        let textColor = textLabel.textColor ?? .white
        attr.append(NSAttributedString(
            string: xFormatted,
            attributes: [.foregroundColor: textColor]
        ))
        for dataSet in data.dataSets {
            guard let entryAtX = dataSet.entryForXValue(refX, closestToY: .nan, rounding: .closest) else {
                continue
            }
            if abs(entryAtX.x - refX) > 0.001 {
                continue
            }
            let yFormatted = yFormatter?.stringForValue(entryAtX.y, axis: yAxis)
                ?? Self.formatLikeAndroid(entryAtX.y)
            let label = dataSet.label ?? ""
            let color = dataSet.colors.first ?? .gray
            attr.append(NSAttributedString(string: "\n"))
            let bulletStart = attr.length
            attr.append(NSAttributedString(string: String(bullet), attributes: [.foregroundColor: color]))
            attr.append(NSAttributedString(
                string: " \(label): \(yFormatted)",
                attributes: [.foregroundColor: textColor]
            ))
        }
        textLabel.attributedText = attr
        let maxLabelWidth: CGFloat = 220
        let labelSize = textLabel.sizeThatFits(CGSize(width: maxLabelWidth, height: .greatestFiniteMagnitude))
        let p = Self.padding
        bounds = CGRect(x: 0, y: 0, width: labelSize.width + 2 * p, height: labelSize.height + 2 * p)
        containerView.frame = CGRect(origin: .zero, size: bounds.size)
        textLabel.frame = CGRect(x: p, y: p, width: labelSize.width, height: labelSize.height)
        super.refreshContent(entry: entry, highlight: highlight)
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

    /// Vertical gap between the data point and the marker so the point stays visible.
    private static let verticalGap: CGFloat = 8

    override func offsetForDrawing(atPoint point: CGPoint) -> CGPoint {
        let width = bounds.width
        let height = bounds.height
        let gap = Self.verticalGap
        var offsetX = -width / 2
        var offsetY = -height - gap

        guard let chart = chartView else {
            return CGPoint(x: offsetX, y: offsetY)
        }
        let chartWidth = chart.bounds.width
        let chartHeight = chart.bounds.height

        if point.x + offsetX < 0 {
            offsetX = -point.x
        } else if point.x + width + offsetX > chartWidth {
            offsetX = chartWidth - point.x - width
        }

        if point.y + offsetY < 0 {
            offsetY = -point.y
        } else if point.y + height + offsetY > chartHeight {
            offsetY = chartHeight - point.y - height
        }

        return CGPoint(x: offsetX, y: offsetY)
    }
}
