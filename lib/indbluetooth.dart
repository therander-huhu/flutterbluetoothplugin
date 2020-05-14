import 'dart:async';

import 'package:flutter/services.dart';

class Indbluetooth {
  static const START_SCAN = "startScan";
  static const STOP_SCAN = "stopScan";
  static const START_READ = "startRead";
  static const STOP_READ = "stopRead";
  static const pluginName = "IndbluetoothPluginName";
  static const deviceListChannelName = "deviceListChannelName";
  static const heartrateChannelName = "heartrateChannelName";

  static const MethodChannel _channel =
      const MethodChannel(pluginName);

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<String> get startScan async {
    final String start = await _channel.invokeMethod(START_SCAN);
    return start;
  }
  static Future<String> get stopScan async {
    final String stop = await _channel.invokeMethod(STOP_SCAN);
    return stop;
  }

  static Future<String> startRead(String deviceAddress) async {
    final String start = await _channel.invokeMethod(START_READ, deviceAddress);
    return start;
  }
  static Future<String> get stopRead async {
    final String stop = await _channel.invokeMethod(STOP_READ);
    return stop;
  }

}
