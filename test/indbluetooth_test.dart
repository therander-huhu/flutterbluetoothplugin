import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:indbluetooth/indbluetooth.dart';

void main() {
  const MethodChannel channel = MethodChannel('indbluetooth');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await Indbluetooth.platformVersion, '42');
  });
}
