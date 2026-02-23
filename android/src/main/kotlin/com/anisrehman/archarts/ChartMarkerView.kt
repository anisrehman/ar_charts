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

    override fun getOffset(): MPPointF {
        return MPPointF(-(width / 2f), -height.toFloat())
    }
}
