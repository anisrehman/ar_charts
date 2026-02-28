package com.anisrehman.archarts

import java.util.concurrent.ConcurrentHashMap

internal object ChartViewRegistry {
    private val lineCharts = ConcurrentHashMap<Int, LineChartPlatformView>()
    private val barCharts = ConcurrentHashMap<Int, BarChartPlatformView>()

    fun registerLineChart(viewId: Int, view: LineChartPlatformView) {
        lineCharts[viewId] = view
    }

    fun unregisterLineChart(viewId: Int) {
        lineCharts.remove(viewId)
    }

    fun getLineChart(viewId: Int): LineChartPlatformView? = lineCharts[viewId]

    fun registerBarChart(viewId: Int, view: BarChartPlatformView) {
        barCharts[viewId] = view
    }

    fun unregisterBarChart(viewId: Int) {
        barCharts.remove(viewId)
    }

    fun getBarChart(viewId: Int): BarChartPlatformView? = barCharts[viewId]
}
