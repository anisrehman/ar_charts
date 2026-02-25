package com.anisrehman.archarts

import android.content.Context
import android.view.View
import com.github.mikephil.charting.charts.BarChart
import com.github.mikephil.charting.components.Legend
import com.github.mikephil.charting.components.XAxis
import com.github.mikephil.charting.components.YAxis
import com.github.mikephil.charting.data.BarData
import com.github.mikephil.charting.data.BarDataSet
import com.github.mikephil.charting.data.BarEntry
import com.github.mikephil.charting.formatter.IndexAxisValueFormatter
import com.github.mikephil.charting.highlight.Highlight
import io.flutter.plugin.platform.PlatformView

class BarChartPlatformView(
    context: Context,
    private val params: Map<String, Any?>
) : PlatformView {

    private val chart: BarChart = BarChart(context)

    init {
        applyConfig()
    }

    override fun getView(): View = chart

    override fun dispose() = Unit

    private fun applyConfig() {
        val series = params["series"] as? List<*> ?: emptyList<Any>()
        val defaultStyle = params["defaultBarStyle"] as? Map<String, Any?>
        val perSeriesStyle = params["perSeriesStyle"] as? Map<String, Any?>
        val barGroup = params["barGroup"] as? Map<String, Any?>
        val groupEnabled = barGroup?.get("enabled") as? Boolean ?: false

        var barWidth: Float? = null
        val labelMap = linkedMapOf<Int, String>()
        val dataSets = series.mapIndexedNotNull { index, item ->
            val seriesMap = item as? Map<String, Any?> ?: return@mapIndexedNotNull null
            val points = seriesMap["points"] as? List<*> ?: emptyList<Any>()
            val entries = points.mapNotNull { point ->
                val pointMap = point as? Map<String, Any?> ?: return@mapNotNull null
                val x = (pointMap["x"] as? Number)?.toFloat() ?: return@mapNotNull null
                val y = (pointMap["y"] as? Number)?.toFloat() ?: return@mapNotNull null
                if (!groupEnabled && index == 0) {
                    val label = pointMap["label"] as? String
                    if (label != null) {
                        labelMap[x.toInt()] = label
                    }
                }
                BarEntry(x, y)
            }
            val label = seriesMap["label"] as? String
            val dataSet = BarDataSet(entries, label ?: "")
            val seriesId = seriesMap["id"] as? String
            val styleMap = seriesId?.let { id -> perSeriesStyle?.get(id) as? Map<String, Any?> }
                ?: defaultStyle
            val styleWidth = applyBarStyle(dataSet, styleMap)
            if (barWidth == null && styleWidth != null) {
                barWidth = styleWidth
            }
            dataSet
        }

        val data = BarData(dataSets)
        if (barWidth != null) {
            data.barWidth = barWidth ?: data.barWidth
        }
        chart.data = data

        val xAxisMap = params["xAxis"] as? Map<String, Any?>
        applyAxis(chart.xAxis, xAxisMap, AxisType.X)
        applyAxis(chart.axisLeft, params["leftAxis"] as? Map<String, Any?>, AxisType.Y)
        applyAxis(chart.axisRight, params["rightAxis"] as? Map<String, Any?>, AxisType.Y)

        if (groupEnabled) {
            applyGroupedBars(chart.xAxis, barGroup, data, dataSets)
        } else {
            applyBarPointLabels(chart.xAxis, labelMap)
        }

        applyLegend(params["legend"] as? Map<String, Any?>)
        applyInteraction(params["interaction"] as? Map<String, Any?>)
        applyMarker(params["marker"] as? Map<String, Any?>)
        applyAnimation(params["animation"] as? Map<String, Any?>)

        chart.description.isEnabled = false
        chart.invalidate()
    }

    private fun applyBarStyle(dataSet: BarDataSet, styleMap: Map<String, Any?>?): Float? {
        if (styleMap == null) return null

        val barColor = (styleMap["barColor"] as? Number)?.toInt()
        if (barColor != null) {
            dataSet.color = barColor
        }
        val drawValues = styleMap["drawValues"] as? Boolean
        if (drawValues != null) {
            dataSet.setDrawValues(drawValues)
        }
        return (styleMap["barWidth"] as? Number)?.toFloat()
    }

    private fun applyAxis(axis: XAxis, axisMap: Map<String, Any?>?, type: AxisType) {
        if (axisMap == null) return
        axis.isEnabled = axisMap["enabled"] as? Boolean ?: true
        axis.setDrawGridLines(axisMap["drawGridLines"] as? Boolean ?: true)
        axis.setDrawAxisLine(axisMap["drawAxisLine"] as? Boolean ?: true)

        val min = (axisMap["min"] as? Number)?.toFloat()
        val max = (axisMap["max"] as? Number)?.toFloat()
        if (min != null) axis.axisMinimum = min
        if (max != null) axis.axisMaximum = max

        val labelCount = axisMap["labelCount"] as? Int
        if (labelCount != null) {
            axis.setLabelCount(labelCount, true)
        }
        if (type == AxisType.X) {
            axis.position = XAxis.XAxisPosition.BOTTOM
        }
        YAxisValueFormatter.fromAxisMap(axisMap)?.let { formatter ->
            axis.valueFormatter = formatter
        }
    }

    private fun applyAxis(axis: YAxis, axisMap: Map<String, Any?>?, type: AxisType) {
        if (axisMap == null) return
        axis.isEnabled = axisMap["enabled"] as? Boolean ?: true
        axis.setDrawGridLines(axisMap["drawGridLines"] as? Boolean ?: true)
        axis.setDrawAxisLine(axisMap["drawAxisLine"] as? Boolean ?: true)

        val min = (axisMap["min"] as? Number)?.toFloat()
        val max = (axisMap["max"] as? Number)?.toFloat()
        if (min != null) axis.axisMinimum = min
        if (max != null) axis.axisMaximum = max

        val labelCount = axisMap["labelCount"] as? Int
        if (labelCount != null) {
            axis.setLabelCount(labelCount, true)
        }

        YAxisValueFormatter.fromAxisMap(axisMap)?.let { formatter ->
            axis.valueFormatter = formatter
        }
    }

    private fun applyBarPointLabels(axis: XAxis, labelMap: Map<Int, String>) {
        if (labelMap.isEmpty()) return
        val maxIndex = labelMap.keys.maxOrNull() ?: return
        val labels = MutableList(maxIndex + 1) { index -> index.toString() }
        labelMap.forEach { (index, label) ->
            if (index in labels.indices) {
                labels[index] = label
            }
        }
        axis.valueFormatter = IndexAxisValueFormatter(labels)
        axis.granularity = 1f
    }

    private fun applyGroupedBars(
        axis: XAxis,
        barGroup: Map<String, Any?>?,
        data: BarData,
        dataSets: List<BarDataSet>
    ) {
        if (barGroup == null || dataSets.size < 2) return
        val groupSpace = (barGroup["groupSpace"] as? Number)?.toFloat() ?: 0.2f
        val barSpace = (barGroup["barSpace"] as? Number)?.toFloat() ?: 0.05f
        val fromX = (barGroup["fromX"] as? Number)?.toFloat() ?: 0f
        val centerAxisLabels = barGroup["centerAxisLabels"] as? Boolean ?: true

        data.groupBars(fromX, groupSpace, barSpace)
        axis.setCenterAxisLabels(centerAxisLabels)
        axis.granularity = 1f

        val groupCount = dataSets.firstOrNull()?.entryCount ?: 0
        val groupWidth = data.getGroupWidth(groupSpace, barSpace)
        axis.axisMinimum = fromX
        axis.axisMaximum = fromX + groupWidth * groupCount
    }

    private fun applyLegend(legendMap: Map<String, Any?>?) {
        val legend = chart.legend
        if (legendMap == null) return
        legend.isEnabled = legendMap["enabled"] as? Boolean ?: true

        when (legendMap["position"] as? String) {
            "bottom" -> legend.verticalAlignment = Legend.LegendVerticalAlignment.BOTTOM
            "left" -> legend.verticalAlignment = Legend.LegendVerticalAlignment.TOP
            "right" -> legend.verticalAlignment = Legend.LegendVerticalAlignment.TOP
            else -> legend.verticalAlignment = Legend.LegendVerticalAlignment.TOP
        }

        when (legendMap["position"] as? String) {
            "left" -> legend.horizontalAlignment = Legend.LegendHorizontalAlignment.LEFT
            "right" -> legend.horizontalAlignment = Legend.LegendHorizontalAlignment.RIGHT
            else -> legend.horizontalAlignment = Legend.LegendHorizontalAlignment.CENTER
        }

        legend.orientation = Legend.LegendOrientation.HORIZONTAL
        legend.setDrawInside(false)
    }

    private fun applyInteraction(interactionMap: Map<String, Any?>?) {
        if (interactionMap == null) return
        val zoomEnabled = interactionMap["zoomEnabled"] as? Boolean ?: true
        val dragEnabled = interactionMap["dragEnabled"] as? Boolean ?: true
        val highlightEnabled = interactionMap["highlightEnabled"] as? Boolean ?: true

        chart.setScaleEnabled(zoomEnabled)
        chart.setPinchZoom(zoomEnabled)
        chart.isDragEnabled = dragEnabled
        chart.isHighlightPerTapEnabled = highlightEnabled
        chart.isHighlightPerDragEnabled = highlightEnabled
    }

    private fun applyMarker(markerMap: Map<String, Any?>?) {
        if (markerMap == null) return
        val enabled = markerMap["enabled"] as? Boolean ?: false
        if (!enabled) return
        val format = markerMap["format"] as? String
        val marker = ChartMarkerView(chart.context, format)
        marker.chartView = chart
        chart.marker = marker
    }

    private fun applyAnimation(animationMap: Map<String, Any?>?) {
        if (animationMap == null) return
        val enabled = animationMap["enabled"] as? Boolean ?: false
        if (!enabled) return
        val duration = (animationMap["durationMs"] as? Number)?.toInt() ?: 500
        when (animationMap["easing"] as? String) {
            "linear" -> chart.animateX(duration, com.github.mikephil.charting.animation.Easing.Linear)
            else -> chart.animateX(duration, com.github.mikephil.charting.animation.Easing.EaseInOutQuad)
        }
    }

    private enum class AxisType { X, Y }
}
