package com.anisrehman.archarts

import android.content.Context
import android.view.View
import com.github.mikephil.charting.charts.LineChart
import com.github.mikephil.charting.components.Legend
import com.github.mikephil.charting.components.XAxis
import com.github.mikephil.charting.components.YAxis
import com.github.mikephil.charting.data.Entry
import com.github.mikephil.charting.data.LineData
import com.github.mikephil.charting.data.LineDataSet
import com.github.mikephil.charting.highlight.Highlight
import io.flutter.plugin.platform.PlatformView

class LineChartPlatformView(
    context: Context,
    private val params: Map<String, Any?>
) : PlatformView {

    private val chart: LineChart = LineChart(context)

    init {
        applyConfig()
    }

    override fun getView(): View = chart

    override fun dispose() = Unit

    private fun applyConfig() {
        val series = params["series"] as? List<*> ?: emptyList<Any>()
        val defaultStyle = params["defaultLineStyle"] as? Map<String, Any?>
        val perSeriesStyle = params["perSeriesStyle"] as? Map<String, Any?>

        val dataSets = series.mapNotNull { item ->
            val seriesMap = item as? Map<String, Any?> ?: return@mapNotNull null
            val points = seriesMap["points"] as? List<*> ?: emptyList<Any>()
            val entries = points.mapNotNull { point ->
                val pointMap = point as? Map<String, Any?> ?: return@mapNotNull null
                val x = (pointMap["x"] as? Number)?.toFloat() ?: return@mapNotNull null
                val y = (pointMap["y"] as? Number)?.toFloat() ?: return@mapNotNull null
                Entry(x, y)
            }
            val label = seriesMap["label"] as? String
            val dataSet = LineDataSet(entries, label ?: "")
            val seriesId = seriesMap["id"] as? String
            val styleMap = seriesId?.let { id -> perSeriesStyle?.get(id) as? Map<String, Any?> }
                ?: defaultStyle
            applyLineStyle(dataSet, styleMap)
            dataSet
        }

        chart.data = LineData(dataSets)

        applyAxis(chart.xAxis, params["xAxis"] as? Map<String, Any?>, AxisType.X)
        applyAxis(chart.axisLeft, params["leftAxis"] as? Map<String, Any?>, AxisType.Y)
        applyAxis(chart.axisRight, params["rightAxis"] as? Map<String, Any?>, AxisType.Y)

        applyLegend(params["legend"] as? Map<String, Any?>)
        applyInteraction(params["interaction"] as? Map<String, Any?>)
        applyViewport(params["viewport"] as? Map<String, Any?>)
        applyMarker(params["marker"] as? Map<String, Any?>)
        applyAnimation(params["animation"] as? Map<String, Any?>)

        chart.description.isEnabled = false
        chart.invalidate()
    }

    // Keep in sync with iOS LineChartPlatformView.applyLineStyle (same order and rules).
    private fun applyLineStyle(dataSet: LineDataSet, styleMap: Map<String, Any?>?) {
        if (styleMap == null) return

        val lineColor = (styleMap["lineColor"] as? Number)?.toInt()
        if (lineColor != null) {
            dataSet.color = lineColor
        }
        val lineWidth = (styleMap["lineWidth"] as? Number)?.toFloat()
        if (lineWidth != null) {
            dataSet.lineWidth = lineWidth
        }
        val drawCircles = styleMap["drawCircles"] as? Boolean
        if (drawCircles != null) {
            dataSet.setDrawCircles(drawCircles)
        }
        val circleColor = (styleMap["circleColor"] as? Number)?.toInt()
        if (circleColor != null) {
            dataSet.setCircleColor(circleColor)
        } else if (lineColor != null) {
            dataSet.setCircleColor(lineColor)
        }
        val circleRadius = (styleMap["circleRadius"] as? Number)?.toFloat()
        if (circleRadius != null) {
            dataSet.circleRadius = circleRadius
            // radius <= 0 means no visible circles, so disable drawing.
            if (circleRadius <= 0f) dataSet.setDrawCircles(false)
        }
        val drawValues = styleMap["drawValues"] as? Boolean
        if (drawValues != null) {
            dataSet.setDrawValues(drawValues)
        }
        val cubic = styleMap["cubic"] as? Boolean
        if (cubic == true) {
            dataSet.mode = LineDataSet.Mode.CUBIC_BEZIER
        }
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

    private fun applyViewport(viewportMap: Map<String, Any?>?) {
        if (viewportMap == null) return
        val minRange = (viewportMap["visibleXRangeMin"] as? Number)?.toFloat()
        if (minRange != null) {
            chart.setVisibleXRangeMinimum(minRange)
        }
        val maxRange = (viewportMap["visibleXRangeMax"] as? Number)?.toFloat()
        if (maxRange != null) {
            chart.setVisibleXRangeMaximum(maxRange)
        }
        val initialX = (viewportMap["initialX"] as? Number)?.toFloat()
        if (initialX != null) {
            chart.moveViewToX(initialX)
        }
        val offsets = viewportMap["viewPortOffsets"] as? Map<*, *>
        if (offsets != null) {
            val left = (offsets["left"] as? Number)?.toFloat() ?: 0f
            val top = (offsets["top"] as? Number)?.toFloat() ?: 0f
            val right = (offsets["right"] as? Number)?.toFloat() ?: 0f
            val bottom = (offsets["bottom"] as? Number)?.toFloat() ?: 0f
            chart.setViewPortOffsets(left, top, right, bottom)
        }
    }

    private fun applyMarker(markerMap: Map<String, Any?>?) {
        if (markerMap == null) return
        val enabled = markerMap["enabled"] as? Boolean ?: false
        if (!enabled) return
        val format = markerMap["format"] as? String
        chart.marker = ChartMarkerView(chart.context, format)
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
