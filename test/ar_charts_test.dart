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

  test('getPlatformVersion', () async {
    ArCharts arChartsPlugin = ArCharts();
    MockArChartsPlatform fakePlatform = MockArChartsPlatform();
    ArChartsPlatform.instance = fakePlatform;

    expect(await arChartsPlugin.getPlatformVersion(), '42');
  });
}
