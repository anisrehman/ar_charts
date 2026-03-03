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

    fun applyMarker(chart: BarLineChartBase<*>, markerMap: Map<String, Any?>?) {
        cancelAutoHide()
        chart.marker = null
        chart.setOnChartValueSelectedListener(null)

        if (markerMap == null) return
        val enabled = markerMap["enabled"] as? Boolean ?: false
        if (!enabled) return

        val marker = ChartMarkerView(context)
        marker.chartView = chart
        chart.marker = marker

        val autoHideSeconds = (markerMap["autoHideDurationSeconds"] as? Number)?.toDouble() ?: 3.5
        if (autoHideSeconds > 0.0) {
            val delayMs = (autoHideSeconds * 1000).toLong()
            chart.setOnChartValueSelectedListener(object : OnChartValueSelectedListener {
                override fun onValueSelected(e: Entry?, h: Highlight?) {
                    scheduleAutoHide(chart, delayMs)
                }

                override fun onNothingSelected() {
                    cancelAutoHide()
                }
            })
        }
    }

    fun cancelAutoHide() {
        autoHideRunnable?.let { handler.removeCallbacks(it) }
        autoHideRunnable = null
    }

    private fun scheduleAutoHide(chart: BarLineChartBase<*>, delayMs: Long) {
        cancelAutoHide()
        autoHideRunnable = Runnable {
            chart.highlightValue(null)
            chart.invalidate()
        }
        handler.postDelayed(autoHideRunnable!!, delayMs)
    }
}
