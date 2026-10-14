package com.anisrehman.archarts

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.view.MotionEvent
import android.view.View
import android.os.Handler
import android.os.Looper
import com.github.mikephil.charting.charts.LineChart
import com.github.mikephil.charting.components.Legend
import com.github.mikephil.charting.components.LimitLine
import com.github.mikephil.charting.components.XAxis
import com.github.mikephil.charting.components.YAxis
import com.github.mikephil.charting.data.Entry
import com.github.mikephil.charting.data.LineData
import com.github.mikephil.charting.data.LineDataSet
import com.github.mikephil.charting.listener.ChartTouchListener
import com.github.mikephil.charting.listener.OnChartGestureListener
import com.github.mikephil.charting.utils.MPPointD
import com.github.mikephil.charting.utils.Utils
import io.flutter.plugin.platform.PlatformView
import kotlin.math.min

private val defaultAxisTextColor: Int = Color.parseColor("#333333")

class LineChartPlatformView(
    context: Context,
    private val viewId: Int,
    private val params: Map<String, Any?>
) : PlatformView {

    private val chart: XAxisMarkLineChart = XAxisMarkLineChart(context)
    private val markerHelper = ChartMarkerHelper(context, Handler(Looper.getMainLooper()))
    private val xAxisMarks = mutableListOf<XAxisMarkModel>()
    private val markLabelPaint = Paint(Paint.ANTI_ALIAS_FLAG)

    init {
        chart.highlighter = XAxisSnapLineChartHighlighter(chart)
        chart.renderer = SelectedPointLineChartRenderer(chart, chart.animator, chart.viewPortHandler)
        markerHelper.onSeriesSelected = { chart.markTooltip = null }
        markerHelper.onAutoHide = { chart.markTooltip = null }
        chart.onChartGestureListener = object : OnChartGestureListener {
            override fun onChartGestureStart(me: MotionEvent, lastPerformedGesture: ChartTouchListener.ChartGesture) = Unit
            override fun onChartGestureEnd(me: MotionEvent, lastPerformedGesture: ChartTouchListener.ChartGesture) = Unit
            override fun onChartLongPressed(me: MotionEvent) = Unit
            override fun onChartDoubleTapped(me: MotionEvent) = Unit
            override fun onChartSingleTapped(me: MotionEvent) {
                val x = me.x
                val y = me.y
                // Highlight runs after this callback. Skip it when the tap is on a
                // mark so the series marker is not drawn for one frame first.
                if (markAt(x, y) != null && chart.marker is ChartMarkerView) {
                    val highlightWasEnabled = chart.isHighlightPerTapEnabled
                    chart.isHighlightPerTapEnabled = false
                    showMarkTooltip(x, y)
                    chart.post { chart.isHighlightPerTapEnabled = highlightWasEnabled }
                    return
                }
                chart.post { showMarkTooltip(x, y) }
            }
            override fun onChartFling(me1: MotionEvent?, me2: MotionEvent, velocityX: Float, velocityY: Float) = Unit
            override fun onChartScale(me: MotionEvent, scaleX: Float, scaleY: Float) = Unit
            override fun onChartTranslate(me: MotionEvent, dX: Float, dY: Float) = Unit
        }
        ChartViewRegistry.registerLineChart(viewId, this)
        applyConfig(params)
    }

    override fun getView(): View = chart

    override fun dispose() {
        markerHelper.cancelAutoHide()
        chart.onChartValueSelectedListener = null
        chart.onChartGestureListener = null
        ChartViewRegistry.unregisterLineChart(viewId)
    }

    fun updateConfig(params: Map<String, Any?>) {
        applyConfig(params)
    }

    private fun applyConfig(params: Map<String, Any?>) {
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
            }.sortedBy { it.x }
            val label = seriesMap["label"] as? String
            val dataSet = SelectedPointLineDataSet(entries, label ?: "")
            val seriesId = seriesMap["id"] as? String
            val styleMap = seriesId?.let { id -> perSeriesStyle?.get(id) as? Map<String, Any?> }
                ?: defaultStyle
            applyLineStyle(dataSet, styleMap)
            dataSet
        }

        chart.data = LineData(dataSets)

        applyAxis(chart.xAxis, params["xAxis"] as? Map<String, Any?>, AxisType.X)
        applyXAxisMarks(params["xAxisMarks"] as? List<*>)
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
    private fun applyLineStyle(dataSet: SelectedPointLineDataSet, styleMap: Map<String, Any?>?) {
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
            dataSet.isDrawCirclesEnabled = drawCircles
        }
        val circleColor = (styleMap["circleColor"] as? Number)?.toInt()
        if (circleColor != null) {
            dataSet.circleColor = circleColor
        } else if (lineColor != null) {
            dataSet.circleColor = lineColor
        }
        val circleRadius = (styleMap["circleRadius"] as? Number)?.toFloat()
        if (circleRadius != null) {
            // 4.0 stores radius in dp and ignores values below 1.
            if (circleRadius < 1f) {
                dataSet.isDrawCirclesEnabled = false
            } else {
                dataSet.circleRadius = circleRadius
            }
        }
        val selectedPointMap = styleMap["selectedPoint"] as? Map<String, Any?>
        if (selectedPointMap != null) {
            dataSet.selectedPointEnabled = selectedPointMap["enabled"] as? Boolean ?: true
            dataSet.selectedPointColor = (selectedPointMap["color"] as? Number)?.toInt()
            dataSet.selectedPointRadius =
                (selectedPointMap["radius"] as? Number)?.toFloat() ?: dataSet.selectedPointRadius
            dataSet.selectedPointStrokeColor =
                (selectedPointMap["strokeColor"] as? Number)?.toInt()
            dataSet.selectedPointStrokeWidth =
                (selectedPointMap["strokeWidth"] as? Number)?.toFloat() ?: dataSet.selectedPointStrokeWidth
        } else {
            dataSet.selectedPointEnabled = false
            dataSet.selectedPointColor = null
            dataSet.selectedPointStrokeColor = null
            dataSet.selectedPointStrokeWidth = 0f
        }
        val drawValues = styleMap["drawValues"] as? Boolean
        if (drawValues != null) {
            dataSet.isDrawValuesEnabled = drawValues
        }
        val cubic = styleMap["cubic"] as? Boolean
        if (cubic == true) {
            dataSet.mode = LineDataSet.Mode.CUBIC_BEZIER
        }
        val lineDashMap = styleMap["lineDash"] as? Map<String, Any?>
        if (lineDashMap != null) {
            val lengthsList = lineDashMap["lengths"] as? List<*>
            val lengths = lengthsList?.mapNotNull { (it as? Number)?.toFloat() } ?: emptyList()
            val phase = (lineDashMap["phase"] as? Number)?.toFloat() ?: 0f
            if (lengths.size >= 2) {
                dataSet.enableDashedLine(lengths[0], lengths[1], phase)
            }
        }
        val fill = styleMap["fill"] as? String
        if (fill == "solid") {
            dataSet.isDrawFilledEnabled = true
            val fillColorExplicit = (styleMap["fillColor"] as? Number)?.toInt()
            val fillColor = if (fillColorExplicit != null) {
                fillColorExplicit
            } else {
                val baseColor = lineColor ?: dataSet.color
                val fillAlpha = 51 // 0.2
                (fillAlpha shl 24) or (baseColor and 0x00FFFFFF)
            }
            dataSet.fillColor = fillColor
        } else if (fill == "gradient") {
            dataSet.isDrawFilledEnabled = true
            val lineColorArgb = (styleMap["lineColor"] as? Number)?.toInt() ?: 0xFF000000.toInt()
            val topArgb = (styleMap["fillColorTop"] as? Number)?.toInt() ?: lineColorArgb
            val bottomArgb = (styleMap["fillColorBottom"] as? Number)?.toInt() ?: 0
            val topWithFillAlpha = applyFillAlpha(topArgb, dataSet.fillAlpha)
            val bottomWithFillAlpha = applyFillAlpha(bottomArgb, dataSet.fillAlpha)
            val gradientDrawable = android.graphics.drawable.GradientDrawable(
                android.graphics.drawable.GradientDrawable.Orientation.TOP_BOTTOM,
                intArrayOf(topWithFillAlpha, bottomWithFillAlpha)
            )
            dataSet.fillDrawable = gradientDrawable
        }
    }

    // iOS applies fillAlpha to gradient fills via CGContext alpha; mirror that on Android.
    private fun applyFillAlpha(color: Int, fillAlpha: Int): Int {
        val sourceAlpha = Color.alpha(color)
        val mixedAlpha = (sourceAlpha * fillAlpha) / 255
        return (mixedAlpha shl 24) or (color and 0x00FFFFFF)
    }

    private fun applyAxis(axis: XAxis, axisMap: Map<String, Any?>?, type: AxisType) {
        if (axisMap == null) return
        axis.isEnabled = axisMap["enabled"] as? Boolean ?: true
        axis.textColor = defaultAxisTextColor
        axis.isDrawGridLinesEnabled = axisMap["drawGridLines"] as? Boolean ?: true
        val gridLineColor = (axisMap["gridLineColor"] as? Number)?.toInt()
        if (gridLineColor != null) {
            axis.gridColor = gridLineColor
        } else {
            val labelColor = axis.textColor
            axis.gridColor = Color.argb(
                56,
                Color.red(labelColor),
                Color.green(labelColor),
                Color.blue(labelColor)
            )
        }
        val gridLineWidth = (axisMap["gridLineWidth"] as? Number)?.toFloat()
        if (gridLineWidth != null) {
            axis.gridLineWidth = gridLineWidth
        }
        axis.isDrawAxisLineEnabled = axisMap["drawAxisLine"] as? Boolean ?: true

        val min = (axisMap["min"] as? Number)?.toFloat()
        val max = (axisMap["max"] as? Number)?.toFloat()
        if (min != null) axis.axisMinimum = min
        if (max != null) axis.axisMaximum = max

        val labelCount = axisMap["labelCount"] as? Int
        if (labelCount != null) {
            axis.labelCount = labelCount
            axis.isForceLabelsEnabled = true
        }

        if (type == AxisType.X) {
            axis.position = XAxis.XAxisPosition.BOTTOM
        }
        YAxisValueFormatter.fromAxisMap(axisMap)?.let { formatter ->
            axis.valueFormatter = formatter
        }
    }

    // Labels at x positions only. Limit lines are not data entries, so they do not
    // change the y-axis range. Keep in sync with iOS applyXAxisMarks.
    private fun applyXAxisMarks(marks: List<*>?) {
        val xAxis = chart.xAxis
        xAxis.removeAllLimitLines()
        xAxis.isDrawLimitLinesBehindDataEnabled = false
        xAxisMarks.clear()
        if (marks == null) return
        for (item in marks) {
            val markMap = item as? Map<*, *> ?: continue
            val x = (markMap["x"] as? Number)?.toFloat() ?: continue
            val label = markMap["label"] as? String ?: continue
            if (label.isEmpty()) continue
            val tooltip = (markMap["tooltip"] as? String)?.takeIf { it.isNotEmpty() } ?: label
            xAxisMarks.add(XAxisMarkModel(x, label, tooltip))
            val limitLine = LimitLine(x, label)
            limitLine.lineWidth = 0f
            limitLine.lineColor = Color.TRANSPARENT
            limitLine.textColor = (markMap["color"] as? Number)?.toInt() ?: defaultAxisTextColor
            limitLine.textSize = MARK_TEXT_SIZE_DP
            limitLine.labelPosition = LimitLine.LimitLabelPosition.RIGHT_BOTTOM
            xAxis.addLimitLine(limitLine)
        }
    }

    private fun showMarkTooltip(touchX: Float, touchY: Float) {
        val mark = markAt(touchX, touchY)
        val markerView = chart.marker as? ChartMarkerView
        if (mark == null || markerView == null) {
            if (chart.markTooltip != null) {
                chart.markTooltip = null
                chart.invalidate()
            }
            return
        }
        chart.markTooltip = XAxisMarkTooltip(mark.x, mark.tooltip)
        markerHelper.cancelAutoHide()
        markerHelper.armAutoHide(chart)
        chart.highlightValue(null, false)
    }

    // Matches XAxisRenderer.renderLimitLineLabel for RIGHT_BOTTOM: text sits just
    // to the right of the x position, along the bottom of the plot.
    private fun markAt(touchX: Float, touchY: Float): XAxisMarkModel? {
        if (xAxisMarks.isEmpty() || !chart.viewPortHandler.hasChartDimens()) return null
        markLabelPaint.textSize = Utils.convertDpToPixel(MARK_TEXT_SIZE_DP)
        val contentLeft = chart.viewPortHandler.contentLeft
        val contentRight = chart.viewPortHandler.contentRight
        val contentBottom = chart.viewPortHandler.contentBottom
        val xOffsetPx = Utils.convertDpToPixel(MARK_LINE_WIDTH_DP) + Utils.convertDpToPixel(MARK_X_OFFSET_DP)
        val baseline = contentBottom - (2f + Utils.convertDpToPixel(MARK_Y_OFFSET_DP))
        val slop = Utils.convertDpToPixel(MARK_TOUCH_SLOP_DP)
        val fontMetrics = markLabelPaint.fontMetrics
        var closest: XAxisMarkModel? = null
        var closestDistance = Float.MAX_VALUE
        for (mark in xAxisMarks) {
            val pixel = chart.getTransformer(YAxis.AxisDependency.LEFT)
                .getPixelForValues(mark.x, 0f)
            val pixelX = pixel.x.toFloat()
            MPPointD.recycleInstance(pixel)
            if (pixelX < contentLeft || pixelX > contentRight) continue
            val textWidth = markLabelPaint.measureText(mark.label)
            val left = min(pixelX + xOffsetPx, contentRight - textWidth)
            val rect = RectF(
                left,
                baseline + fontMetrics.ascent,
                left + textWidth,
                baseline + fontMetrics.descent,
            )
            rect.inset(-slop, -slop)
            if (!rect.contains(touchX, touchY)) continue
            val distance = kotlin.math.abs(touchX - rect.centerX())
            if (distance < closestDistance) {
                closest = mark
                closestDistance = distance
            }
        }
        return closest
    }

    private fun applyAxis(axis: YAxis, axisMap: Map<String, Any?>?, type: AxisType) {
        if (axisMap == null) return
        axis.isEnabled = axisMap["enabled"] as? Boolean ?: true
        axis.textColor = defaultAxisTextColor
        axis.isDrawGridLinesEnabled = axisMap["drawGridLines"] as? Boolean ?: true
        val gridLineColor = (axisMap["gridLineColor"] as? Number)?.toInt()
        if (gridLineColor != null) {
            axis.gridColor = gridLineColor
        } else {
            val labelColor = axis.textColor
            axis.gridColor = Color.argb(
                56,
                Color.red(labelColor),
                Color.green(labelColor),
                Color.blue(labelColor)
            )
        }
        val gridLineWidth = (axisMap["gridLineWidth"] as? Number)?.toFloat()
        if (gridLineWidth != null) {
            axis.gridLineWidth = gridLineWidth
        }
        axis.isDrawAxisLineEnabled = axisMap["drawAxisLine"] as? Boolean ?: true

        val min = (axisMap["min"] as? Number)?.toFloat()
        val max = (axisMap["max"] as? Number)?.toFloat()
        if (min != null) axis.axisMinimum = min
        if (max != null) axis.axisMaximum = max

        val labelCount = axisMap["labelCount"] as? Int
        if (labelCount != null) {
            axis.labelCount = labelCount
            axis.isForceLabelsEnabled = true
        }

        YAxisValueFormatter.fromAxisMap(axisMap)?.let { formatter ->
            axis.valueFormatter = formatter
        }
    }

    private fun applyLegend(legendMap: Map<String, Any?>?) {
        val legend = chart.legend
        if (legendMap == null) return
        legend.isEnabled = legendMap["enabled"] as? Boolean ?: true
        legend.textColor = defaultAxisTextColor

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
        legend.isDrawInsideEnabled = false
    }

    private fun applyInteraction(interactionMap: Map<String, Any?>?) {
        if (interactionMap == null) return
        val zoomEnabled = interactionMap["zoomEnabled"] as? Boolean ?: true
        val dragEnabled = interactionMap["dragEnabled"] as? Boolean ?: true
        val highlightEnabled = interactionMap["highlightEnabled"] as? Boolean ?: true

        chart.isScaleEnabled = zoomEnabled
        chart.isPinchZoomEnabled = zoomEnabled
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
        markerHelper.applyMarker(chart, markerMap)
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

    private companion object {
        const val MARK_TEXT_SIZE_DP = 10f
        const val MARK_LINE_WIDTH_DP = 0.2f
        const val MARK_X_OFFSET_DP = 5f
        const val MARK_Y_OFFSET_DP = 5f
        const val MARK_TOUCH_SLOP_DP = 12f
    }
}

private data class XAxisMarkModel(val x: Float, val label: String, val tooltip: String)

private data class XAxisMarkTooltip(val x: Float, val text: String)

/**
 * Draws an x-axis mark tooltip without adding a data entry. MPAndroidChart only
 * draws markers for highlighted entries, and a mark has no y value.
 */
private class XAxisMarkLineChart(context: Context) : LineChart(context) {
    var markTooltip: XAxisMarkTooltip? = null

    override fun drawMarkers(canvas: Canvas) {
        val tooltip = markTooltip
        val markerView = marker as? ChartMarkerView
        if (tooltip != null && markerView != null) {
            val pixel = getTransformer(YAxis.AxisDependency.LEFT)
                .getPixelForValues(tooltip.x, 0f)
            markerView.refreshMark(tooltip.text)
            markerView.draw(canvas, pixel.x.toFloat(), viewPortHandler.contentBottom)
            MPPointD.recycleInstance(pixel)
            return
        }
        super.drawMarkers(canvas)
    }
}
