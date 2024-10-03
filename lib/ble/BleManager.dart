import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleManager {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;

  DiscoveredDevice? _connectedDevice;
  List<DiscoveredService> _discoveredServices = [];
  QualifiedCharacteristic? _rxCharacteristic;
  QualifiedCharacteristic? _txCharacteristic;

  Function(String)? onConnectionStatusChange;
  Function(String)? onDataReceivedCallback;  // Callback function for received data

  String _connectionStatus = "Disconnected";

  // Singleton pattern to ensure only one instance of BLEManager
  static final BleManager _instance = BleManager._internal();

  factory BleManager() {
    return _instance;
  }

  BleManager._internal();

  // Getter for connection status
  String get connectionStatus => _connectionStatus;

  // Start scanning for BLE devices
  void startScan(String targetDeviceName) {
    _connectionStatus = "Scanning...";
    _scanSubscription = _ble.scanForDevices(withServices: []).listen(
          (device) {
        if (device.name == targetDeviceName) {
          _scanSubscription?.cancel();
          _connectToDevice(device);
        }
      },
      onError: (error) {
        _handleScanError(error);
      },
    );
  }

  // Stop the scanning
  void stopScan() {
    _scanSubscription?.cancel();
  }

  // Connect to a BLE device
  void _connectToDevice(DiscoveredDevice device) {
    _connectionStatus = "Connecting to ${device.name}...";
    onConnectionStatusChange?.call(_connectionStatus);

    _connectionSubscription = _ble.connectToDevice(id: device.id).listen(
          (connectionState) {
        if (connectionState.connectionState == DeviceConnectionState.connected) {
          _connectedDevice = device;
          _connectionStatus = "Connected to ${device.name}";
          onConnectionStatusChange?.call(_connectionStatus);
          _discoverServices(device.id);
        } else if (connectionState.connectionState == DeviceConnectionState.disconnected) {
          _connectionStatus = "Disconnected";
          onConnectionStatusChange?.call(_connectionStatus);
        }
      },
      onError: (error) {
        _connectionStatus = "Connection error";
        onConnectionStatusChange?.call(_connectionStatus);
      },
    );
  }

  // Discover services and characteristics
  Future<void> _discoverServices(String deviceId) async {
    _discoveredServices = await _ble.discoverServices(deviceId);

    for (var service in _discoveredServices) {
      for (var characteristic in service.characteristics) {
        if (characteristic.isWritableWithResponse && characteristic.isNotifiable) {
          _txCharacteristic = QualifiedCharacteristic(
            serviceId: service.serviceId,
            characteristicId: characteristic.characteristicId,
            deviceId: deviceId,
          );
          _rxCharacteristic = _txCharacteristic;
          _subscribeToNotifications(_rxCharacteristic!);
        }
      }
    }
  }

  // Send data to BLE device
  void sendData(List<int> data) async {
    if (_txCharacteristic != null) {
      await _ble.writeCharacteristicWithResponse(_txCharacteristic!, value: data);
    }
  }

  // Subscribe to notifications from the BLE device
  void _subscribeToNotifications(QualifiedCharacteristic characteristic) {
    _ble.subscribeToCharacteristic(characteristic).listen((data) {
      String receivedString = _bytesToString(data);  // Convert byte data to string
      if (onDataReceivedCallback != null) {
        onDataReceivedCallback!(receivedString);  // Call the callback method in the UI class
      }
    });
  }

  // Helper function to convert byte list to string
  String _bytesToString(List<int> bytes) {
    return String.fromCharCodes(bytes);
  }

  // Handle scan errors (with retry)
  void _handleScanError(dynamic error) {
    if (error.toString().contains("ScanFailure.unknown")) {
      Future.delayed(Duration(seconds: 10), () {
        startScan(_connectedDevice?.name ?? "RESPYR_LUNG_2.0");
      });
    }
  }

  // Clean up resources
  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
  }
}
