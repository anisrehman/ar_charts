package com.anisrehman.archarts

import com.github.mikephil.charting.components.AxisBase
import com.github.mikephil.charting.formatter.ValueFormatter
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Formats axis values: compact (1K, 1.5M, 1T), decimal, percent, or date.
 * Matches iOS YAxisValueFormatter semantics. Used for X and Y axes.
 */
class YAxisValueFormatter(
    private val formatType: String,
    private val decimals: Int = 1,
    private val dateFormatPattern: String = "MMM d"
) : ValueFormatter() {

    override fun getAxisLabel(value: Float, axis: AxisBase?): String {
        return when (formatType) {
            "compact" -> formatCompact(value.toDouble())
            "decimal" -> String.format(Locale.US, "%.${decimals}f", value)
            "percent" -> String.format(Locale.US, "%.${decimals}f%%", value)
            "date" -> formatDate(value.toLong(), dateFormatPattern)
            else -> value.toString()
        }
    }

    private fun formatDate(millisSinceEpoch: Long, pattern: String): String {
        val date = Date(millisSinceEpoch)
        val formatter = SimpleDateFormat(pattern, Locale.getDefault())
        return formatter.format(date)
    }

    private fun formatCompact(value: Double): String {
        val absValue = kotlin.math.abs(value)
        val sign = if (value < 0) "-" else ""
        return when {
            absValue >= 1_000_000_000_000 -> sign + String.format(Locale.US, "%.1fT", absValue / 1_000_000_000_000)
            absValue >= 1_000_000_000 -> sign + String.format(Locale.US, "%.1fB", absValue / 1_000_000_000)
            absValue >= 1_000_000 -> sign + String.format(Locale.US, "%.1fM", absValue / 1_000_000)
            absValue >= 1_000 -> sign + String.format(Locale.US, "%.1fK", absValue / 1_000)
            absValue >= 1 || absValue == 0.0 -> String.format(Locale.US, "%.0f", value)
            else -> String.format(Locale.US, "%.2f", value)
        }
    }

    companion object {
        /**
         * Returns a formatter if axisMap specifies formatType (compact, decimal, percent, date), else null.
         */
        fun fromAxisMap(axisMap: Map<String, Any?>?): YAxisValueFormatter? {
            if (axisMap == null) return null
            val type = axisMap["formatType"] as? String ?: return null
            if (type == "none") return null
            val decimals = (axisMap["formatTypeDecimals"] as? Number)?.toInt() ?: 1
            val formatPattern = axisMap["formatPattern"] as? String ?: "MMM d"
            return YAxisValueFormatter(type, decimals, formatPattern)
        }
    }
}
