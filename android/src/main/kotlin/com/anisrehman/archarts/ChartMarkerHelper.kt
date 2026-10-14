package com.anisrehman.archarts

import android.content.Context
import android.os.Handler
import com.github.mikephil.charting.charts.BarLineChartBase
import com.github.mikephil.charting.data.Entry
import com.github.mikephil.charting.highlight.Highlight
import com.github.mikephil.charting.listener.OnChartValueSelectedListener

/**
 * Shared marker and auto-hide logic for line and bar charts. Apply marker config
 * and optional auto-hide timer; call [cancelAutoHide] from dispose.
 */
internal class ChartMarkerHelper(
    private val context: Context,
    private val handler: Handler
) {
    private var autoHideRunnable: Runnable? = null
    private var autoHideDelayMs: Long = 0

    /** Clears an x-axis mark tooltip when a series point is selected. */
    var onSeriesSelected: (() -> Unit)? = null

    /** Clears an x-axis mark tooltip when the marker auto-hides. */
    var onAutoHide: (() -> Unit)? = null

    fun applyMarker(chart: BarLineChartBase<*>, markerMap: Map<String, Any?>?) {
        cancelAutoHide()
        autoHideDelayMs = 0
        chart.marker = null
        chart.onChartValueSelectedListener = null

        if (markerMap == null) return
        val enabled = markerMap["enabled"] as? Boolean ?: false
        if (!enabled) return

        val marker = ChartMarkerView(context)
        marker.chartView = chart
        chart.marker = marker

        val autoHideSeconds = (markerMap["autoHideDurationSeconds"] as? Number)?.toDouble() ?: 3.5
        autoHideDelayMs = if (autoHideSeconds > 0.0) (autoHideSeconds * 1000).toLong() else 0L
        chart.onChartValueSelectedListener = object : OnChartValueSelectedListener {
            override fun onValueSelected(e: Entry<*>, h: Highlight) {
                onSeriesSelected?.invoke()
                if (autoHideDelayMs > 0L) {
                    scheduleAutoHide(chart, autoHideDelayMs)
                }
            }

            override fun onNothingSelected() {
                cancelAutoHide()
            }
        }
    }

    /** Starts the same auto-hide timer used after a series point is selected. */
    fun armAutoHide(chart: BarLineChartBase<*>) {
        if (autoHideDelayMs > 0L) {
            scheduleAutoHide(chart, autoHideDelayMs)
        }
    }

    fun cancelAutoHide() {
        autoHideRunnable?.let { handler.removeCallbacks(it) }
        autoHideRunnable = null
    }

    private fun scheduleAutoHide(chart: BarLineChartBase<*>, delayMs: Long) {
        cancelAutoHide()
        autoHideRunnable = Runnable {
            onAutoHide?.invoke()
            chart.highlightValue(null)
            chart.invalidate()
        }
        handler.postDelayed(autoHideRunnable!!, delayMs)
    }
}
