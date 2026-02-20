import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ar_charts/ar_charts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
    final barSeries = [
      const BarSeries(
        id: 'sales',
        label: 'Sales',
        points: [
          BarPoint(x: 1, y: 5, label: 'Mon'),
          BarPoint(x: 2, y: 3, label: 'Tue'),
          BarPoint(x: 3, y: 7, label: 'Wed'),
          BarPoint(x: 4, y: 4, label: 'Thu'),
          BarPoint(x: 5, y: 6, label: 'Fri'),
        ],
      ),
    ];
    final groupedBarSeries = [
      const BarSeries(
        id: 'salesA',
        label: 'Store A',
        points: [
          BarPoint(x: 0, y: 3),
          BarPoint(x: 1, y: 5),
          BarPoint(x: 2, y: 2),
          BarPoint(x: 3, y: 4),
          BarPoint(x: 4, y: 6),
        ],
      ),
      const BarSeries(
        id: 'salesB',
        label: 'Store B',
        points: [
          BarPoint(x: 0, y: 4),
          BarPoint(x: 1, y: 2),
          BarPoint(x: 2, y: 6),
          BarPoint(x: 3, y: 3),
          BarPoint(x: 4, y: 5),
        ],
      ),
    ];

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Charts Demo')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Line Chart',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              LineChart(
                series: lineSeries,
                height: 280,
                xAxis: const AxisConfig(
                  min: 0,
                  max: totalPoints - 1,
                  labelCount: 6,
                ),
                leftAxis: const AxisConfig(
                  min: 0,
                  max: 100000,
                  labelCount: 6,
                  formatType: AxisValueFormatDecimal(2),
                ),
                // rightAxis: const AxisConfig(enabled: false),
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
                // viewport: const ViewportConfig(
                //   visibleXRangeMax: 50,
                //   initialX: 0,
                // ),
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
              const SizedBox(height: 24),
              const Text(
                'Bar Chart',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              BarChart(
                series: barSeries,
                height: 280,
                xAxis: const AxisConfig(min: 0, max: 6),
                // leftAxis: const AxisConfig(
                //   min: -1,
                //   max: 4,
                //   labelCount: 5,
                // ),
                // rightAxis: const AxisConfig(enabled: false),
                legend: const LegendConfig(
                  enabled: true,
                  position: LegendPosition.bottom,
                  alignment: LegendAlignment.center,
                ),
                interaction: const InteractionConfig(
                  zoomEnabled: false,
                  dragEnabled: false,
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
                defaultBarStyle: const BarStyle(
                  barColor: Colors.orange,
                  barWidth: 0.6,
                  drawValues: true,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Grouped Bar Chart',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              BarChart(
                series: groupedBarSeries,
                height: 280,
                xAxis: const AxisConfig(min: 0, max: 6, labelCount: 6),
                leftAxis: const AxisConfig(min: 0, max: 8, labelCount: 5),
                rightAxis: const AxisConfig(enabled: false),
                legend: const LegendConfig(
                  enabled: true,
                  position: LegendPosition.bottom,
                  alignment: LegendAlignment.center,
                ),
                interaction: const InteractionConfig(
                  zoomEnabled: true,
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
                barGroup: const BarGroupConfig(
                  enabled: true,
                  groupSpace: 0.2,
                  barSpace: 0.05,
                  fromX: 0,
                  centerAxisLabels: true,
                  label: 'Weekly totals',
                ),
                defaultBarStyle: const BarStyle(
                  barColor: Colors.blue,
                  barWidth: 0.35,
                  drawValues: true,
                ),
                perSeriesStyle: const {
                  'salesA': BarStyle(barColor: Colors.teal, barWidth: 0.35),
                  'salesB': BarStyle(barColor: Colors.indigo, barWidth: 0.35),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
