package com.anisrehman.archarts

import com.github.mikephil.charting.charts.LineChart
import com.github.mikephil.charting.highlight.ChartHighlighter
import kotlin.math.abs

/**
 * Highlights the nearest entry by x-position only.
 *
 * MPAndroidChart defaults to Euclidean distance (x + y) for touch selection,
 * which can pick the previous day when touching near the right edge.
 */
internal class XAxisSnapLineChartHighlighter(
    chart: LineChart
) : ChartHighlighter<LineChart>(chart) {
    override fun getDistance(x1: Float, y1: Float, x2: Float, y2: Float): Float {
        return abs(x1 - x2)
    }
}
