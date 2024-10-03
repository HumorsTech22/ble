import 'package:flutter/material.dart';

import 'ble/BleManager.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BleScreen(),
    );
  }
}

class BleScreen extends StatefulWidget {
  @override
  _BleScreenState createState() => _BleScreenState();
}

class _BleScreenState extends State<BleScreen> {
  final BleManager _bleManager = BleManager();  // Access the BLE Manager
  final TextEditingController _customDataController = TextEditingController();

  String _connectionStatus = "Disconnected";
  String _receivedData = "";  // This will hold the received data

  @override
  void initState() {
    super.initState();

    // Set the callback for connection status
    _bleManager.onConnectionStatusChange = (status) {
      setState(() {
        _connectionStatus = status;
      });
    };

    // Set the callback for data reception
    _bleManager.onDataReceivedCallback = (data) {
      // Call the method to handle the received data
      _onDataReceived(data);
    };
  }

  @override
  void dispose() {
    _customDataController.dispose();
    _bleManager.dispose();
    super.dispose();
  }

  void _startScan() {
    _bleManager.startScan("RESPYR_LUNG_2.0");
  }

  void _sendCustomData() {
    final customData = _customDataController.text;
    if (customData.isNotEmpty) {
      _bleManager.sendData(_stringToBytes(customData));
    }
  }

  List<int> _stringToBytes(String input) {
    return input.codeUnits;
  }

  // Method to handle the received data from BLE
  void _onDataReceived(String data) {
    setState(() {
      _receivedData = data;
    });
    print("Data received in UI: $data");  // Log the data for debugging
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("BLE Example"),
      ),
      body: Center(
        child: _connectionStatus == "Disconnected"
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Connection Status: $_connectionStatus"),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _startScan,
              child: Text("Start Scan and Connect"),
            ),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Connection Status: $_connectionStatus'),
            SizedBox(height: 20),
            TextField(
              controller: _customDataController,
              decoration: InputDecoration(
                labelText: "Enter custom data to send",
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendCustomData,
              child: Text("Send Custom Data"),
            ),
            SizedBox(height: 20),
           // Text('Received Data: $_receivedData'),  // Display the received data
          ],
        ),
      ),
    );
  }
}
