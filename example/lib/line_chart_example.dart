import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ar_charts/ar_charts.dart';

class LineChartExamplePage extends StatelessWidget {
  const LineChartExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    const totalPoints = 60;
    final random = Random();
    final startDate = DateTime.now().subtract(const Duration(days: totalPoints - 1));
    final endDate = DateTime.now();

    // Line 1: Y values above 1000 so compact formatter shows 1K, 10K, 50K, etc.
    double y1 = 5000.0;
    final series1 = List.generate(totalPoints, (index) {
      final date = startDate.add(Duration(days: index));
      final delta = (random.nextDouble() - 0.5) * 3000.0;
      y1 = (y1 + delta).clamp(1000.0, 100000.0);
      return LinePoint(
        x: date.millisecondsSinceEpoch.toDouble(),
        y: y1,
      );
    });
    // Line 2: Different random walk, offset range
    double y2 = 30000.0;
    final series2 = List.generate(totalPoints, (index) {
      final date = startDate.add(Duration(days: index));
      final delta = (random.nextDouble() - 0.5) * 2000.0;
      y2 = (y2 + delta).clamp(5000.0, 80000.0);
      return LinePoint(
        x: date.millisecondsSinceEpoch.toDouble(),
        y: y2,
      );
    });
    final lineSeries = [
      LineSeries(id: 'price', label: 'Price', points: series1),
      LineSeries(id: 'volume', label: 'Volume', points: series2),
    ];

    final lineStyles = {
      'price': const LineStyle(
        lineColor: Colors.blue,
        lineWidth: 2,
        drawCircles: true,
        circleRadius: 0,
        drawValues: false,
        cubic: true,
        fill: LineFillSolid(color: Colors.blue),
        lineDrawStyle: LineDrawDashed(length: 10, gap: 5),
      ),
      'volume': const LineStyle(
        lineColor: Colors.orange,
        lineWidth: 2,
        drawCircles: true,
        circleRadius: 0,
        drawValues: false,
        cubic: true,
        fill: LineFillSolid(color: Color(0xFFFF9800)), // orange with alpha
        lineDrawStyle: LineDrawDashed(length: 2, gap: 4),
      ),
    };

    // Gradient chart: single series with gradient fill (same data as first series).
    final gradientSeries = [
      LineSeries(id: 'gradient', label: 'Price', points: series1),
    ];
    final gradientStyles = {
      'gradient': const LineStyle(
        lineColor: Colors.blue,
        lineWidth: 2,
        drawCircles: true,
        circleRadius: 0,
        drawValues: false,
        cubic: true,
        fill: LineFillGradient(
          colorTop: Colors.blue,
          colorBottom: Colors.white,
        ),
      ),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Line Chart')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LineChart(
              series: lineSeries,
              height: 280,
              xAxis: AxisConfig(
                min: startDate.millisecondsSinceEpoch.toDouble(),
                max: endDate.millisecondsSinceEpoch.toDouble(),
                labelCount: 6,
                formatType: const AxisValueFormatDate('MMM d'),
              ),
              leftAxis: const AxisConfig(
                formatType: AxisValueFormatCompact(),
              ),
              legend: const LegendConfig(
                enabled: true,
                position: LegendPosition.bottom,
                alignment: LegendAlignment.center,
              ),
              interaction: const InteractionConfig(
                zoomEnabled: false,
                dragEnabled: true,
                highlightEnabled: true,
              ),
              animation: const AnimationConfig(
                enabled: true,
                durationMs: 700,
              ),
              marker: const MarkerConfig(enabled: true),
              defaultLineStyle: const LineStyle(
                lineColor: Colors.blue,
                lineWidth: 2,
                drawCircles: true,
                circleRadius: 0,
                drawValues: false,
                cubic: true,
                fill: LineFillSolid(),
              ),
              perSeriesStyle: lineStyles,
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Gradient fill',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            LineChart(
              series: gradientSeries,
              height: 280,
              xAxis: AxisConfig(
                min: startDate.millisecondsSinceEpoch.toDouble(),
                max: endDate.millisecondsSinceEpoch.toDouble(),
                labelCount: 6,
                formatType: const AxisValueFormatDate('MMM d'),
              ),
              leftAxis: const AxisConfig(
                formatType: AxisValueFormatCompact(),
              ),
              legend: const LegendConfig(
                enabled: true,
                position: LegendPosition.bottom,
                alignment: LegendAlignment.center,
              ),
              interaction: const InteractionConfig(
                zoomEnabled: false,
                dragEnabled: true,
                highlightEnabled: true,
              ),
              animation: const AnimationConfig(
                enabled: true,
                durationMs: 700,
              ),
              marker: const MarkerConfig(enabled: true),
              defaultLineStyle: const LineStyle(
                lineColor: Colors.blue,
                lineWidth: 2,
                drawCircles: true,
                circleRadius: 0,
                drawValues: false,
                cubic: true,
              ),
              perSeriesStyle: gradientStyles,
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Dashed and dotted lines',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            LineChart(
              series: [
                LineSeries(id: 'dashed', label: 'Dashed', points: series1),
                LineSeries(id: 'dotted', label: 'Dotted', points: series2),
              ],
              height: 280,
              xAxis: AxisConfig(
                min: startDate.millisecondsSinceEpoch.toDouble(),
                max: endDate.millisecondsSinceEpoch.toDouble(),
                labelCount: 6,
                formatType: const AxisValueFormatDate('MMM d'),
              ),
              leftAxis: const AxisConfig(
                formatType: AxisValueFormatCompact(),
              ),
              legend: const LegendConfig(
                enabled: true,
                position: LegendPosition.bottom,
                alignment: LegendAlignment.center,
              ),
              interaction: const InteractionConfig(
                zoomEnabled: false,
                dragEnabled: true,
                highlightEnabled: true,
              ),
              marker: const MarkerConfig(enabled: true),
              perSeriesStyle: {
                'dashed': const LineStyle(
                  lineColor: Colors.green,
                  lineWidth: 2,
                  drawCircles: true,
                  circleRadius: 0,
                  lineDrawStyle: LineDrawDashed(length: 10, gap: 5),
                ),
                'dotted': const LineStyle(
                  lineColor: Colors.purple,
                  lineWidth: 2,
                  drawCircles: true,
                  circleRadius: 0,
                  lineDrawStyle: LineDrawDashed(length: 2, gap: 4),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}
