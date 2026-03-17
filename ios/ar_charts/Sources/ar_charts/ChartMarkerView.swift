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

        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 4
        containerView.layer.masksToBounds = true
        addSubview(containerView)

        textLabel.textColor = .black
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
        let xFormatted = Self.resolveMarkerTitle(entry: entry, chart: chart, fallbackX: refX)
        let yAxis = chart.leftAxis
        let yFormatter = yAxis.valueFormatter
        let bullet: Character = "\u{25CF}"
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

    private static func resolveMarkerTitle(entry: ChartDataEntry, chart: BarLineChartViewBase, fallbackX: Double) -> String {
        if let metadata = entry.data as? [String: Any] {
            if let label = metadata["xLabel"] as? String, !label.isEmpty { return label }
            if let sourceX = metadata["sourceX"] as? NSNumber { return formatXAxisValue(sourceX.doubleValue) }
        } else if let metadata = entry.data as? NSDictionary {
            if let label = metadata["xLabel"] as? String, !label.isEmpty { return label }
            if let sourceX = metadata["sourceX"] as? NSNumber { return formatXAxisValue(sourceX.doubleValue) }
        }
        return chart.xAxis.valueFormatter?.stringForValue(fallbackX, axis: chart.xAxis)
            ?? formatXAxisValue(fallbackX)
    }

    private static func formatXAxisValue(_ value: Double) -> String {
        if value == value.rounded() { return String(Int(value)) }
        return String(value)
    }

    /// Gap between the data point and the marker so the point stays visible.
    private static let gap: CGFloat = 8

    override func offsetForDrawing(atPoint point: CGPoint) -> CGPoint {
        let width = bounds.width
        let height = bounds.height
        let gap = Self.gap
        var offsetX: CGFloat
        var offsetY: CGFloat

        guard let chart = chartView else {
            return CGPoint(x: -width / 2, y: gap)
        }
        let contentLeft: CGFloat = 0
        let contentTop: CGFloat = 0
        let contentRight = chart.bounds.width
        let contentBottom = chart.bounds.height

        if point.y + gap + height <= contentBottom {
            offsetX = -width / 2
            offsetY = gap
        } else if point.y - height - gap >= contentTop {
            offsetX = -width / 2
            offsetY = -height - gap
        } else if point.x + gap + width <= contentRight {
            offsetX = gap
            offsetY = -height / 2
        } else if point.x - width - gap >= contentLeft {
            offsetX = -width - gap
            offsetY = -height / 2
        } else {
            offsetX = -width / 2
            offsetY = -height / 2
        }

        let left = point.x + offsetX
        let top = point.y + offsetY
        let right = left + width
        let bottom = top + height
        if left < contentLeft {
            offsetX = contentLeft - point.x
        } else if right > contentRight {
            offsetX = contentRight - point.x - width
        }
        if top < contentTop {
            offsetY = contentTop - point.y
        } else if bottom > contentBottom {
            offsetY = contentBottom - point.y - height
        }

        return CGPoint(x: offsetX, y: offsetY)
    }
}
