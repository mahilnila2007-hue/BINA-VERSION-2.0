import 'dart:async';
import '../models/sensor_data_model.dart';

enum ConnectionType { ble, wifi }

enum HardwareConnectionStatus {
  disconnected,
  searching,
  connecting,
  connected,
  error,
}

class DiscoveredDevice {
  final String name;
  final String deviceId;
  final int rssi; // Signal strength dBm
  final int batteryLevel; // %
  final ConnectionType type;

  DiscoveredDevice({
    required this.name,
    required this.deviceId,
    required this.rssi,
    required this.batteryLevel,
    required this.type,
  });
}

/// Hardware service abstraction
/// Enables easy swap between Demo Generator, Real BLE ESP32, and Real WebSocket ESP32
abstract class HardwareService {
  Stream<HardwareConnectionStatus> get statusStream;
  HardwareConnectionStatus get currentStatus;
  
  Stream<SensorDataPoint> get sensorStream;
  
  Future<List<DiscoveredDevice>> scanDevices({required ConnectionType type});
  Future<bool> connect(String deviceId, {required ConnectionType type});
  Future<void> disconnect();
  
  void setDemoMode(bool enabled);
  bool get isDemoMode;
}
