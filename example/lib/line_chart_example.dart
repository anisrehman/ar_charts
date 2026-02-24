import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ar_charts/ar_charts.dart';

class LineChartExamplePage extends StatelessWidget {
  const LineChartExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    const totalPoints = 1000;
    final random = Random();
    // Line 1: Y values above 1000 so compact formatter shows 1K, 10K, 50K, etc.
    double y1 = 5000.0;
    final series1 = List.generate(totalPoints, (index) {
      final delta = (random.nextDouble() - 0.5) * 3000.0;
      y1 = (y1 + delta).clamp(1000.0, 100000.0);
      return LinePoint(x: index.toDouble(), y: y1);
    });
    // Line 2: Different random walk, offset range
    double y2 = 30000.0;
    final series2 = List.generate(totalPoints, (index) {
      final delta = (random.nextDouble() - 0.5) * 2000.0;
      y2 = (y2 + delta).clamp(5000.0, 80000.0);
      return LinePoint(x: index.toDouble(), y: y2);
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
      ),
      'volume': const LineStyle(
        lineColor: Colors.orange,
        lineWidth: 2,
        drawCircles: true,
        circleRadius: 0,
        drawValues: false,
        cubic: true,
      ),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Line Chart')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(0),
        child: LineChart(
          series: lineSeries,
          height: 280,
          xAxis: const AxisConfig(
            min: 0,
            max: totalPoints - 1,
            labelCount: 6,
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
          marker: const MarkerConfig(
            enabled: true,
            format: 'x: {x}\ny: {y}',
          ),
          defaultLineStyle: const LineStyle(
            lineColor: Colors.blue,
            lineWidth: 2,
            drawCircles: true,
            circleRadius: 0,
            drawValues: false,
            cubic: true,
          ),
          perSeriesStyle: lineStyles,
        ),
      ),
    );
  }
}
