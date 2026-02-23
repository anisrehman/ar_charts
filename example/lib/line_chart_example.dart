import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ar_charts/ar_charts.dart';

class LineChartExamplePage extends StatelessWidget {
  const LineChartExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    const totalPoints = 1000;
    final random = Random();
    // Y values above 1000 so compact formatter shows 1K, 10K, 50K, etc.
    double y = 5000.0;
    final lineSeries = [
      LineSeries(
        id: 'price',
        label: 'Price',
        points: List.generate(totalPoints, (index) {
          final delta = (random.nextDouble() - 0.5) * 3000.0;
          y = (y + delta).clamp(1000.0, 100000.0);
          return LinePoint(x: index.toDouble(), y: y);
        }),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Line Chart')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
            format: 'x: {x}, y: {y}',
          ),
          defaultLineStyle: const LineStyle(
            lineColor: Colors.blue,
            lineWidth: 2,
            drawCircles: true,
            circleRadius: 0,
            drawValues: false,
            cubic: true,
          ),
          perSeriesStyle: const {},
        ),
      ),
    );
  }
}
