import 'package:flutter/material.dart';

import 'line_chart_example.dart';
import 'bar_chart_example.dart';
import 'grouped_bar_chart_example.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const ChartListPage(),
    );
  }
}

class ChartListPage extends StatelessWidget {
  const ChartListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Charts Demo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('Line Chart'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const LineChartExamplePage(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Bar Chart'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const BarChartExamplePage(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Grouped Bar Chart'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const GroupedBarChartExamplePage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
