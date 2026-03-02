package com.anisrehman.archarts

import android.graphics.Color
import android.text.SpannableStringBuilder
import android.text.Spanned
import android.text.style.ForegroundColorSpan
import com.github.mikephil.charting.charts.BarLineChartBase
import com.github.mikephil.charting.components.MarkerView
import com.github.mikephil.charting.data.DataSet
import com.github.mikephil.charting.data.Entry
import com.github.mikephil.charting.highlight.Highlight
import com.github.mikephil.charting.interfaces.datasets.IBarLineScatterCandleBubbleDataSet
import com.github.mikephil.charting.utils.MPPointF
import kotlin.math.abs

/**
 * Shared marker view for line and bar charts. Shows x-axis value on the first line,
 * then each series that has a point at that x with a colored bullet and formatted y.
 */
internal class ChartMarkerView(
    context: android.content.Context
) : MarkerView(context, R.layout.ar_charts_marker_view) {

    private val textView = findViewById<android.widget.TextView>(R.id.markerText)

    override fun refreshContent(e: Entry?, highlight: Highlight?) {
        if (e != null && highlight != null) {
            val chart = chartView as? BarLineChartBase<*>
            val data = chart?.data
            if (chart != null && data != null) {
                val refX = highlight.x
                val xFormatted = chart.xAxis.valueFormatter?.getAxisLabel(refX, chart.xAxis)
                    ?: refX.toString()
                val yAxis = chart.axisLeft
                val yFormatter = yAxis.valueFormatter
                val bullet = '\u25CF'
                val sb = SpannableStringBuilder()
                sb.append(xFormatted)
                for (ds in data.dataSets) {
                    val entry = ds.getEntryForXValue(refX, Float.NaN, DataSet.Rounding.CLOSEST)
                        ?: continue
                    if (abs(entry.x - refX) > 0.001f) continue
                    val yFormatted = yFormatter?.getAxisLabel(entry.y, yAxis) ?: entry.y.toString()
                    val label = ds.label ?: ""
                    val color = (ds as? IBarLineScatterCandleBubbleDataSet<*>)?.getColor(0) ?: Color.GRAY
                    val lineStart = sb.length
                    sb.append('\n')
                    sb.append(bullet)
                    sb.setSpan(
                        ForegroundColorSpan(color),
                        lineStart + 1,
                        lineStart + 2,
                        Spanned.SPAN_EXCLUSIVE_EXCLUSIVE
                    )
                    sb.append(" ")
                    sb.append(label)
                    sb.append(": ")
                    sb.append(yFormatted)
                }
                textView.text = sb
            }
        }
        super.refreshContent(e, highlight)
    }

    /** Vertical gap (dp) between the data point and the marker so the point stays visible. */
    private val verticalGapPx: Float
        get() = 8f * resources.displayMetrics.density

    override fun getOffset(): MPPointF {
        return MPPointF(-(width / 2f), -(height + verticalGapPx))
    }

    override fun getOffsetForDrawingAtPoint(posX: Float, posY: Float): MPPointF {
        // Center marker on point: center X, place above point
        var offsetX = -(width / 2f)
        var offsetY = -(height + verticalGapPx)
        val chart = chartView ?: return MPPointF(offsetX, offsetY)
        val vph = chart.viewPortHandler
        val contentLeft = vph.contentLeft()
        val contentRight = vph.contentRight()
        val contentTop = vph.contentTop()
        val contentBottom = vph.contentBottom()
        // Clamp horizontal: if marker would extend past content bounds, shift center X so it stays inside
        if (posX + offsetX < contentLeft) {
            offsetX = contentLeft - posX
        } else if (posX + offsetX + width > contentRight) {
            offsetX = contentRight - posX - width
        }
        if (posY + offsetY < contentTop) {
            offsetY = contentTop - posY
        } else if (posY + offsetY + height > contentBottom) {
            offsetY = contentBottom - posY - height
        }
        return MPPointF(offsetX, offsetY)
    }
}
