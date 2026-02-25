package com.anisrehman.archarts

import android.content.Context
import com.github.mikephil.charting.components.MarkerView
import com.github.mikephil.charting.data.Entry
import com.github.mikephil.charting.highlight.Highlight
import com.github.mikephil.charting.utils.MPPointF

/**
 * Shared marker view for line and bar charts. Displays entry values using optional `{x}` and `{y}` format.
 */
internal class ChartMarkerView(
    context: Context,
    private val format: String?
) : MarkerView(context, R.layout.ar_charts_marker_view) {

    private val textView = findViewById<android.widget.TextView>(R.id.markerText)

    override fun refreshContent(e: Entry?, highlight: Highlight?) {
        if (e != null) {
            val template = format ?: "x: {x}, y: {y}"
            val text = template
                .replace("{x}", e.x.toString())
                .replace("{y}", e.y.toString())
            textView.text = text
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
