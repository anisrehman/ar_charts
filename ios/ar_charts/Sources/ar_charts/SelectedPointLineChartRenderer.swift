import CoreGraphics
import UIKit
import DGCharts

final class SelectedPointLineChartDataSet: LineChartDataSet {
    var selectedPointEnabled = false
    var selectedPointColor: UIColor?
    var selectedPointRadius: CGFloat = 5
    var selectedPointStrokeColor: UIColor?
    var selectedPointStrokeWidth: CGFloat = 0
}

final class SelectedPointLineChartRenderer: LineChartRenderer {
    override func drawHighlighted(context: CGContext, indices: [Highlight]) {
        super.drawHighlighted(context: context, indices: indices)

        guard let dataProvider, let lineData = dataProvider.lineData else { return }

        context.saveGState()

        for highlight in indices {
            guard let set = lineData[highlight.dataSetIndex] as? SelectedPointLineChartDataSet,
                  set.isHighlightEnabled,
                  set.selectedPointEnabled,
                  let entry = set.entryForXValue(highlight.x, closestToY: highlight.y)
            else { continue }

            let x = entry.x
            let y = entry.y * Double(animator.phaseY)
            let point = dataProvider.getTransformer(forAxis: set.axisDependency)
                .pixelForValues(x: x, y: y)
            let radius = set.selectedPointRadius
            let rect = CGRect(
                x: point.x - radius,
                y: point.y - radius,
                width: radius * 2,
                height: radius * 2
            )

            context.setFillColor((set.selectedPointColor ?? set.circleColors.first ?? set.colors.first ?? .black).cgColor)
            context.fillEllipse(in: rect)

            if set.selectedPointStrokeWidth > 0 {
                context.setStrokeColor((set.selectedPointStrokeColor ?? .white).cgColor)
                context.setLineWidth(set.selectedPointStrokeWidth)
                context.strokeEllipse(in: rect)
            }
        }

        context.restoreGState()
    }
}
