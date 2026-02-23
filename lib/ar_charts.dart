/// Flutter charts library for Android and iOS.
///
/// Provides [LineChart] and [BarChart] widgets that wrap native chart libraries
/// (MPAndroidChart on Android, Charts on iOS). Supports configurable axes,
/// legends, interactions (zoom, drag, highlight), markers, and animations.
///
/// Example:
/// ```dart
/// LineChart(
///   series: [
///     LineSeries(
///       id: 'series1',
///       label: 'Series 1',
///       points: [LinePoint(x: 0, y: 10), LinePoint(x: 1, y: 20)],
///     ),
///   ],
///   height: 280,
///   xAxis: const AxisConfig(min: 0, max: 2),
/// )
/// ```
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ar_charts_platform_interface.dart';

/// Entry point for platform-specific functionality (e.g. [getPlatformVersion]).
class ArCharts {
  /// Returns the current platform version string (Android/iOS).
  Future<String?> getPlatformVersion() {
    return ArChartsPlatform.instance.getPlatformVersion();
  }
}

const String _lineChartViewType = 'ar_charts/line_chart';
const String _barChartViewType = 'ar_charts/bar_chart';

/// A line chart widget that renders one or more [LineSeries] using the native
/// chart engine (MPAndroidChart on Android, Charts on iOS).
///
/// Use [series] for data. Optionally configure [xAxis], [leftAxis], [rightAxis],
/// [legend], [interaction], [viewport], [marker], and [animation]. [height] and
/// [padding] control layout. On unsupported platforms (e.g. web) renders nothing.
class LineChart extends StatelessWidget {
  const LineChart({
    super.key,
    required this.series,
    this.xAxis,
    this.leftAxis,
    this.rightAxis = const AxisConfig(enabled: false),
    this.defaultLineStyle,
    this.perSeriesStyle,
    this.legend,
    this.interaction,
    this.viewport,
    this.marker,
    this.animation,
    this.height,
    this.padding,
  });

  final List<LineSeries> series;
  final AxisConfig? xAxis;
  final AxisConfig? leftAxis;
  final AxisConfig? rightAxis;
  final LineStyle? defaultLineStyle;
  final Map<String, LineStyle>? perSeriesStyle;
  final LegendConfig? legend;
  final InteractionConfig? interaction;
  final ViewportConfig? viewport;
  final MarkerConfig? marker;
  final AnimationConfig? animation;

  /// Fixed height of the chart; if null, only [padding] affects size.
  final double? height;

  /// Padding around the native chart view.
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final view = _buildPlatformView();
    final padded = padding != null
        ? Padding(padding: padding!, child: view)
        : view;

    if (height == null) {
      return padded;
    }
    return SizedBox(height: height, child: padded);
  }

  Widget _buildPlatformView() {
    final params = _toCreationParams();
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: _lineChartViewType,
        creationParams: params,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: _lineChartViewType,
        creationParams: params,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }
    return const SizedBox.shrink();
  }

  Map<String, Object?> _toCreationParams() {
    return {
      'series': series.map((item) => item.toMap()).toList(),
      'xAxis': xAxis?.toMap(),
      'leftAxis': leftAxis?.toMap(),
      'rightAxis': rightAxis?.toMap(),
      'defaultLineStyle': defaultLineStyle?.toMap(),
      'perSeriesStyle': perSeriesStyle?.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
      'legend': legend?.toMap(),
      'interaction': interaction?.toMap(),
      'viewport': viewport?.toMap(),
      'marker': marker?.toMap(),
      'animation': animation?.toMap(),
    };
  }
}

/// A bar chart widget that renders one or more [BarSeries] using the native
/// chart engine. Use [barGroup] with [BarGroupConfig] for grouped bars.
///
/// Optionally configure [xAxis], [leftAxis], [rightAxis], [legend], [interaction],
/// [marker], and [animation]. On unsupported platforms (e.g. web) renders nothing.
class BarChart extends StatelessWidget {
  const BarChart({
    super.key,
    required this.series,
    this.xAxis,
    this.leftAxis,
    this.rightAxis,
    this.defaultBarStyle,
    this.perSeriesStyle,
    this.legend,
    this.interaction = const InteractionConfig(
      zoomEnabled: false,
      dragEnabled: false,
      highlightEnabled: true,
    ),
    this.marker,
    this.animation,
    this.barGroup,
    this.height,
    this.padding,
  });

  final List<BarSeries> series;
  final AxisConfig? xAxis;
  final AxisConfig? leftAxis;
  final AxisConfig? rightAxis;
  final BarStyle? defaultBarStyle;
  final Map<String, BarStyle>? perSeriesStyle;
  final LegendConfig? legend;
  final InteractionConfig? interaction;
  final MarkerConfig? marker;
  final AnimationConfig? animation;
  final BarGroupConfig? barGroup;

  /// Fixed height of the chart; if null, only [padding] affects size.
  final double? height;

  /// Padding around the native chart view.
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final view = _buildPlatformView();
    final padded = padding != null
        ? Padding(padding: padding!, child: view)
        : view;

    if (height == null) {
      return padded;
    }
    return SizedBox(height: height, child: padded);
  }

  Widget _buildPlatformView() {
    final params = _toCreationParams();
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: _barChartViewType,
        creationParams: params,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: _barChartViewType,
        creationParams: params,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }
    return const SizedBox.shrink();
  }

  Map<String, Object?> _toCreationParams() {
    return {
      'series': series.map((item) => item.toMap()).toList(),
      'xAxis': xAxis?.toMap(),
      'leftAxis': leftAxis?.toMap(),
      'rightAxis': rightAxis?.toMap(),
      'defaultBarStyle': defaultBarStyle?.toMap(),
      'perSeriesStyle': perSeriesStyle?.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
      'legend': legend?.toMap(),
      'interaction': interaction?.toMap(),
      'marker': marker?.toMap(),
      'animation': animation?.toMap(),
      'barGroup': barGroup?.toMap(),
    };
  }
}

/// A single line series: unique [id], optional [label] for legend, and [points].
class LineSeries {
  const LineSeries({required this.id, required this.points, this.label});

  /// Unique identifier; used for [LineChart.perSeriesStyle] lookup.
  final String id;

  /// Optional label shown in the legend.
  final String? label;

  /// Data points (x, y) for this series.
  final List<LinePoint> points;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'label': label,
      'points': points.map((point) => point.toMap()).toList(),
    };
  }
}

/// A single bar series: unique [id], optional [label] for legend, and [points].
class BarSeries {
  const BarSeries({required this.id, required this.points, this.label});

  /// Unique identifier; used for [BarChart.perSeriesStyle] and [BarGroupConfig].
  final String id;

  /// Optional label shown in the legend.
  final String? label;

  /// Data points (x, y, optional label) for this series.
  final List<BarPoint> points;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'label': label,
      'points': points.map((point) => point.toMap()).toList(),
    };
  }
}

/// One (x, y) point for a [LineSeries].
class LinePoint {
  const LinePoint({required this.x, required this.y});

  final double x;
  final double y;

  Map<String, Object> toMap() {
    return {'x': x, 'y': y};
  }
}

/// One (x, y) bar with optional [label] for axis or tooltip.
class BarPoint {
  const BarPoint({required this.x, required this.y, this.label});

  final double x;
  final double y;

  /// Optional label (e.g. day name) for the X axis or marker.
  final String? label;

  Map<String, Object?> toMap() {
    return {'x': x, 'y': y, 'label': label};
  }
}

/// Format for axis value labels (e.g. Y-axis). Use [AxisValueFormatCompact]
/// for large numbers (1K, 1.5M) or [AxisValueFormatDecimal] for fixed decimals.
sealed class AxisValueFormat {
  const AxisValueFormat();
}

/// No custom formatting; use chart default numeric labels.
class AxisValueFormatNone extends AxisValueFormat {
  const AxisValueFormatNone();
}

/// Compact notation: 1000 → "1K", 1_500_000 → "1.5M", 1e9 → "1B".
class AxisValueFormatCompact extends AxisValueFormat {
  const AxisValueFormatCompact();
}

/// Fixed decimal places, e.g. [decimals] = 2 → "1.23".
class AxisValueFormatDecimal extends AxisValueFormat {
  const AxisValueFormatDecimal(this.decimals);
  final int decimals;
}

/// Percentage: append "%", e.g. 50 → "50%", 50.5 → "50.5%". [decimals] defaults to 1.
class AxisValueFormatPercent extends AxisValueFormat {
  const AxisValueFormatPercent([this.decimals = 1]);
  final int decimals;
}

/// Configuration for an axis (X, left Y, or right Y): visibility, label, range,
/// label count, grid/axis lines, and optional [formatType] for value labels.
class AxisConfig {
  const AxisConfig({
    this.enabled = true,
    this.label,
    this.min,
    this.max,
    this.labelCount,
    this.drawGridLines = true,
    this.drawAxisLine = true,
    this.formatType,
  });

  final bool enabled;
  final String? label;
  final double? min;
  final double? max;
  final int? labelCount;
  final bool drawGridLines;
  final bool drawAxisLine;
  /// Optional formatter for axis value labels (Y-axis only). E.g. [AxisValueFormatCompact].
  final AxisValueFormat? formatType;

  Map<String, Object?> toMap() {
    final String? formatTypeValue = formatType == null ||
            formatType is AxisValueFormatNone
        ? null
        : formatType is AxisValueFormatCompact
            ? 'compact'
            : formatType is AxisValueFormatDecimal
                ? 'decimal'
                : formatType is AxisValueFormatPercent
                    ? 'percent'
                    : null;
    final int? formatTypeDecimals =
        formatType is AxisValueFormatDecimal
            ? (formatType as AxisValueFormatDecimal).decimals
            : formatType is AxisValueFormatPercent
                ? (formatType as AxisValueFormatPercent).decimals
                : null;
    return {
      'enabled': enabled,
      'label': label,
      'min': min,
      'max': max,
      'labelCount': labelCount,
      'drawGridLines': drawGridLines,
      'drawAxisLine': drawAxisLine,
      'formatType': formatTypeValue,
      'formatTypeDecimals': formatTypeDecimals,
    };
  }
}

/// Style for a line series: color, width, circles, optional value labels, cubic curve.
class LineStyle {
  const LineStyle({
    required this.lineColor,
    this.lineWidth = 2,
    this.drawCircles = true,
    this.circleColor,
    this.circleRadius = 4,
    this.drawValues = false,
    this.cubic = false,
  });

  final Color lineColor;
  final double lineWidth;
  final bool drawCircles;
  final Color? circleColor;
  final double circleRadius;
  final bool drawValues;
  final bool cubic;

  Map<String, Object?> toMap() {
    return {
      'lineColor': lineColor.value,
      'lineWidth': lineWidth,
      'drawCircles': drawCircles,
      'circleColor': circleColor?.value,
      'circleRadius': circleRadius,
      'drawValues': drawValues,
      'cubic': cubic,
    };
  }
}

/// Style for a bar series: color, width, optional value-on-bar labels.
class BarStyle {
  const BarStyle({
    required this.barColor,
    this.barWidth = 0.8,
    this.drawValues = false,
  });

  final Color barColor;
  final double barWidth;
  final bool drawValues;

  Map<String, Object?> toMap() {
    return {
      'barColor': barColor.value,
      'barWidth': barWidth,
      'drawValues': drawValues,
    };
  }
}

/// Configuration for grouped bars when using multiple [BarSeries]: spacing and labels.
class BarGroupConfig {
  const BarGroupConfig({
    this.enabled = false,
    this.groupSpace = 0.2,
    this.barSpace = 0.05,
    this.fromX = 0,
    this.centerAxisLabels = true,
    this.label,
  });

  final bool enabled;
  final double groupSpace;
  final double barSpace;
  final double fromX;
  final bool centerAxisLabels;
  final String? label;

  Map<String, Object?> toMap() {
    return {
      'enabled': enabled,
      'groupSpace': groupSpace,
      'barSpace': barSpace,
      'fromX': fromX,
      'centerAxisLabels': centerAxisLabels,
      'label': label,
    };
  }
}

/// Legend visibility, [position] (top/bottom/left/right), and [alignment].
class LegendConfig {
  const LegendConfig({
    this.enabled = true,
    this.position = LegendPosition.top,
    this.alignment = LegendAlignment.center,
  });

  final bool enabled;
  final LegendPosition position;
  final LegendAlignment alignment;

  Map<String, Object> toMap() {
    return {
      'enabled': enabled,
      'position': position.name,
      'alignment': alignment.name,
    };
  }
}

/// Where the legend is placed relative to the chart.
enum LegendPosition { top, bottom, left, right }

/// How the legend is aligned within its position.
enum LegendAlignment { start, center, end }

/// Zoom, drag, and tap-highlight behavior for the chart.
class InteractionConfig {
  const InteractionConfig({
    this.zoomEnabled = false,
    this.dragEnabled = false,
    this.highlightEnabled = true,
  });

  final bool zoomEnabled;
  final bool dragEnabled;
  final bool highlightEnabled;

  Map<String, Object> toMap() {
    return {
      'zoomEnabled': zoomEnabled,
      'dragEnabled': dragEnabled,
      'highlightEnabled': highlightEnabled,
    };
  }
}

/// Visible X range and offsets for [LineChart]; useful with zoom/drag.
class ViewportConfig {
  const ViewportConfig({
    this.visibleXRangeMin,
    this.visibleXRangeMax,
    this.initialX,
    this.viewPortOffsets,
  });

  final double? visibleXRangeMin;
  final double? visibleXRangeMax;
  final double? initialX;
  final EdgeInsets? viewPortOffsets;

  Map<String, Object?> toMap() {
    return {
      'visibleXRangeMin': visibleXRangeMin,
      'visibleXRangeMax': visibleXRangeMax,
      'initialX': initialX,
      'viewPortOffsets': viewPortOffsets == null
          ? null
          : {
              'left': viewPortOffsets!.left,
              'top': viewPortOffsets!.top,
              'right': viewPortOffsets!.right,
              'bottom': viewPortOffsets!.bottom,
            },
    };
  }
}

/// Popover on tap showing value; [format] can use `{x}` and `{y}` placeholders.
class MarkerConfig {
  const MarkerConfig({this.enabled = false, this.format});

  final bool enabled;

  /// Format string, e.g. `'x: {x}, y: {y}'`.
  final String? format;

  Map<String, Object?> toMap() {
    return {'enabled': enabled, 'format': format};
  }
}

/// Entrance animation: [durationMs] and [easing].
class AnimationConfig {
  const AnimationConfig({
    this.enabled = false,
    this.durationMs = 500,
    this.easing = AnimationEasing.easeInOut,
  });

  final bool enabled;
  final int durationMs;
  final AnimationEasing easing;

  Map<String, Object> toMap() {
    return {
      'enabled': enabled,
      'durationMs': durationMs,
      'easing': easing.name,
    };
  }
}

/// Easing for [AnimationConfig].
enum AnimationEasing { easeInOut, linear }
