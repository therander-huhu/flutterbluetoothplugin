import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:indbluetooth/indbluetooth.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  
  List<dynamic> devices = [];
  static const EventChannel deviceListChannel = EventChannel(Indbluetooth.deviceListChannelName);
  static const EventChannel heartrateChannel = EventChannel(Indbluetooth.heartrateChannelName);

  @override
  void initState() {
    super.initState();
    initPlatformState();
    // 这里的 data 就是原生端发送过来的数据
    deviceListChannel.receiveBroadcastStream().listen((data) {
      Map<String, dynamic> resp = jsonDecode(data);
      if (deviceListNotContain(resp)) {
        devices.add(resp);
        setState(() {
          devices = devices;
        });
      }//streamController.sink.add(data);
    });
    heartrateChannel.receiveBroadcastStream().listen((data) {
      print("myheartRate: $data");//streamController.sink.add(data);
    });
  }

  bool deviceListNotContain(resp) {
    return devices.where((item) {
      return item['address'] == resp['address'];
    }).isEmpty;
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await Indbluetooth.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<void> startScan() async {
    try {
      setState(() {
        devices.clear();
      });
      await Indbluetooth.startScan;
    } on PlatformException {
    }
    if (!mounted) return;
  }

  Future<void> stopScan() async {
    try {
      await Indbluetooth.stopScan;
    } on PlatformException {
    }
    if (!mounted) return;
    setState(() {
    });
  }

  Future<void> startRead({String deviceAddress}) async {
    print('start read');
    try {
      await Indbluetooth.startRead(deviceAddress);
    } on PlatformException {
    }
    if (!mounted) return;
    setState(() {
    });
  }
  Future<void> stopRead() async {
    try {
      await Indbluetooth.stopRead;
    } on PlatformException {
    }
    if (!mounted) return;
    setState(() {
    });
  }

  @override
  Widget build(BuildContext context) {
    print('build');
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              Text('Running on: $_platformVersion\n'),
              GestureDetector(
                onTap: () {
                  startScan();
                },
                child: Container(
                  color: Colors.blue,
                  height: 40,
                  child: Text('startScan'),
                ),
              ),
              GestureDetector(
                onTap: () {
                  stopScan();
                },
                child: Container(
                  color: Colors.yellow,
                  height: 40,
                  child: Text('stopScan'),
                ),
              ),
              GestureDetector(
                onTap: () {
                  stopRead();
                },
                child: Container(
                  color: Colors.yellow,
                  height: 40,
                  child: Text('stopRead'),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: devices.length,
                    itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      startRead(deviceAddress:devices[index]['address']);
                    },
                    child: Container(
                      child: Column(
                        children: <Widget>[
                          Text(devices[index]['name']),
                          Text(devices[index]['address']),
                        ],
                      ),
                    ),
                  );
                }),
              )
            ],
          ),
        ),
      ),
    );
  }
}
