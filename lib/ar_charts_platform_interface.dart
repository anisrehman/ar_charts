import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'ar_charts_method_channel.dart';

abstract class ArChartsPlatform extends PlatformInterface {
  /// Constructs a ArChartsPlatform.
  ArChartsPlatform() : super(token: _token);

  static final Object _token = Object();

  static ArChartsPlatform _instance = MethodChannelArCharts();

  /// The default instance of [ArChartsPlatform] to use.
  ///
  /// Defaults to [MethodChannelArCharts].
  static ArChartsPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ArChartsPlatform] when
  /// they register themselves.
  static set instance(ArChartsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
