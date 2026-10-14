import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ar_charts/ar_charts.dart';
import 'package:ar_charts/ar_charts_platform_interface.dart';
import 'package:ar_charts/ar_charts_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockArChartsPlatform
    with MockPlatformInterfaceMixin
    implements ArChartsPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final ArChartsPlatform initialPlatform = ArChartsPlatform.instance;

  test('$MethodChannelArCharts is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelArCharts>());
  });

  test('XAxisMark serializes x and label without a y value', () {
    const mark = XAxisMark(x: 10, label: r'$3.2K', color: Color(0xFF00AA00));

    expect(mark.toMap(), {
      'x': 10,
      'label': r'$3.2K',
      'color': 0xFF00AA00,
      'tooltip': null,
    });
    expect(mark.toMap().containsKey('y'), isFalse);
  });

  test('XAxisMark serializes a tooltip that differs from the label', () {
    const mark = XAxisMark(x: 10, label: 'Div', tooltip: r'$3.2K');

    expect(mark.toMap()['tooltip'], r'$3.2K');
    expect(mark.toMap().containsKey('y'), isFalse);
  });

  test('getPlatformVersion', () async {
    ArCharts arChartsPlugin = ArCharts();
    MockArChartsPlatform fakePlatform = MockArChartsPlatform();
    ArChartsPlatform.instance = fakePlatform;

    expect(await arChartsPlugin.getPlatformVersion(), '42');
  });
}
