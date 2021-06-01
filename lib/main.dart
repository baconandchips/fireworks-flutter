import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'dart:developer' as developer;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Fireworks 1.5 Flutter Edition'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  final List<BluetoothDevice> devicesList = List<BluetoothDevice>.empty(growable: true);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  BluetoothDevice _connectedDevice = null;
  List<BluetoothService> _services = List<BluetoothDevice>.empty(growable: true); // possible problems?

  _addDeviceToList(final BluetoothDevice device) {
    if (!widget.devicesList.contains(device)) {
      setState(() {
        widget.devicesList.add(device);
        developer.log('added device: $device');
      });
    }
  }

  @override
  void initState() {
    super.initState();
    developer.log('initializing state');
    widget.flutterBlue.connectedDevices
      .asStream()
      .listen((List<BluetoothDevice> devices) {
        for (BluetoothDevice device in devices) {
          _addDeviceToList(device);
        }
      });
    widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        _addDeviceToList(result.device);
      }
    });
    widget.flutterBlue.startScan();
  }

  ListView _buildListViewOfDevices() {
    List<Container> containers = List<Container>.empty(growable: true);
    for (BluetoothDevice device in widget.devicesList) {
      containers.add(
        Container(
          height: 50,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text(device.name == '' ? '(unknown device)' : device.name),
                    Text(device.id.toString()),
                  ],
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  primary: Colors.white,
                  backgroundColor: Colors.blue,
                  onSurface: Colors.grey,
                ),
                child: Text(
                  'Connect',
                  // style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  setState(() async {
                    widget.flutterBlue.stopScan();
                    try {
                      await device.connect();
                    } catch (e) {
                      if (e.code != 'already_connected') {
                        throw e;
                      }
                    } finally {
                      _services = await device.discoverServices();
                    }
                    _connectedDevice = device;
                  });
                },
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }

  ListView _buildConnectdeviceView() {
    List<Container> containers = List<Container>.empty(growable: true);
    for (BluetoothService service in _services) {
      containers.add(
        Container(
          height: 50,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text(service.uuid.toString()),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }

  ListView _buildView() {
    if (_connectedDevice != null) {
      return _buildConnectDeviceView();
    }
    return _buildListViewOfDevices();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
         title: Text(widget.title),
       ),
       body: _buildView(),
    );
  }
}
