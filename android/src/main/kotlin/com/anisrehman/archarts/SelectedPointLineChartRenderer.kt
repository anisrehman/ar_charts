package com.anisrehman.archarts

import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import com.github.mikephil.charting.animation.ChartAnimator
import com.github.mikephil.charting.data.Entry
import com.github.mikephil.charting.data.LineDataSet
import com.github.mikephil.charting.highlight.Highlight
import com.github.mikephil.charting.interfaces.dataprovider.LineDataProvider
import com.github.mikephil.charting.renderer.LineChartRenderer
import com.github.mikephil.charting.utils.MPPointD
import com.github.mikephil.charting.utils.Utils
import com.github.mikephil.charting.utils.ViewPortHandler

internal class SelectedPointLineDataSet(
    entries: List<Entry>,
    label: String
) : LineDataSet(entries, label) {
    var selectedPointEnabled: Boolean = false
    var selectedPointColor: Int? = null
    var selectedPointRadius: Float = 5f
    var selectedPointStrokeColor: Int? = null
    var selectedPointStrokeWidth: Float = 0f
}

internal class SelectedPointLineChartRenderer(
    chart: LineDataProvider,
    animator: ChartAnimator,
    viewPortHandler: ViewPortHandler
) : LineChartRenderer(chart, animator, viewPortHandler) {

    private val selectedPointFillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.FILL
    }

    private val selectedPointStrokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
    }

    override fun drawHighlighted(c: Canvas, indices: Array<Highlight>) {
        super.drawHighlighted(c, indices)

        val lineData = mChart.lineData ?: return

        for (highlight in indices) {
            val dataSet = lineData.getDataSetByIndex(highlight.dataSetIndex) as? SelectedPointLineDataSet
                ?: continue
            if (!dataSet.selectedPointEnabled || !dataSet.isHighlightEnabled) continue

            val entry = dataSet.getEntryForXValue(highlight.x, highlight.y) ?: continue
            if (!isInBoundsX(entry, dataSet)) continue

            val pixel = mChart.getTransformer(dataSet.axisDependency)
                .getPixelForValues(entry.x, entry.y * mAnimator.phaseY)
            val x = pixel.x.toFloat()
            val y = pixel.y.toFloat()

            if (!mViewPortHandler.isInBoundsLeft(x)
                || !mViewPortHandler.isInBoundsRight(x)
                || !mViewPortHandler.isInBoundsY(y)
            ) {
                MPPointD.recycleInstance(pixel)
                continue
            }

            val fillColor = dataSet.selectedPointColor
                ?: dataSet.getCircleColor(0)
                ?: dataSet.color
            val radiusPx = Utils.convertDpToPixel(dataSet.selectedPointRadius)
            selectedPointFillPaint.color = fillColor
            c.drawCircle(x, y, radiusPx, selectedPointFillPaint)

            if (dataSet.selectedPointStrokeWidth > 0f) {
                selectedPointStrokePaint.color = dataSet.selectedPointStrokeColor ?: Color.WHITE
                selectedPointStrokePaint.strokeWidth =
                    Utils.convertDpToPixel(dataSet.selectedPointStrokeWidth)
                c.drawCircle(x, y, radiusPx, selectedPointStrokePaint)
            }

            MPPointD.recycleInstance(pixel)
        }
    }
}
