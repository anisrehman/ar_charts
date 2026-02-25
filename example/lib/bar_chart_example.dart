import 'package:flutter/material.dart';
import 'package:ar_charts/ar_charts.dart';

class BarChartExamplePage extends StatelessWidget {
  const BarChartExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      appBar: AppBar(title: const Text('Bar Chart')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: BarChart(
          series: barSeries,
          height: 280,
          xAxis: const AxisConfig(min: 0, max: 6),
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
          marker: const MarkerConfig(enabled: true),
          defaultBarStyle: const BarStyle(
            barColor: Colors.orange,
            barWidth: 0.6,
            drawValues: true,
          ),
        ),
      ),
    );
  }
}
