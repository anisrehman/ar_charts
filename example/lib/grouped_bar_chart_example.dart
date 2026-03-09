import 'package:flutter/material.dart';
import 'package:ar_charts/ar_charts.dart';

class GroupedBarChartExamplePage extends StatelessWidget {
  const GroupedBarChartExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    final groupedBarData = BarChartData(
      dataSets: const [
        BarChartDataSet(
          id: 'salesA',
          label: 'Store A',
          entries: [
            BarChartDataEntry(x: 0, y: 3),
            BarChartDataEntry(x: 1, y: 5),
            BarChartDataEntry(x: 2, y: 2),
            BarChartDataEntry(x: 3, y: 4),
            BarChartDataEntry(x: 4, y: 6),
          ],
        ),
        BarChartDataSet(
          id: 'salesB',
          label: 'Store B',
          entries: [
            BarChartDataEntry(x: 0, y: 4),
            BarChartDataEntry(x: 1, y: 2),
            BarChartDataEntry(x: 2, y: 6),
            BarChartDataEntry(x: 4, y: 5),
            BarChartDataEntry(x: 3, y: 3),
          ],
        ),
      ],
      group: const BarGroupConfig(
        enabled: true,
        groupSpace: 0.2,
        barSpace: 0.05,
        fromX: 0,
        centerAxisLabels: true,
        label: 'Weekly totals',
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Grouped Bar Chart')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: BarChart(
          data: groupedBarData,
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
          marker: const MarkerConfig(enabled: true),
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
      ),
    );
  }
}
