import 'dart:async';
import 'dart:math' as math;
import '../models/sensor_data_model.dart';
import 'hardware_service.dart';

class HardwareServiceImpl implements HardwareService {
  final _statusController = StreamController<HardwareConnectionStatus>.broadcast();
  final _sensorController = StreamController<SensorDataPoint>.broadcast();
  
  HardwareConnectionStatus _status = HardwareConnectionStatus.connected;
  bool _isDemoMode = false;
  Timer? _generatorTimer;
  double _phase = 0.0;
  final math.Random _rng = math.Random();

  HardwareServiceImpl() {
    _statusController.add(_status);
    _startDataLoop();
  }

  @override
  Stream<HardwareConnectionStatus> get statusStream => _statusController.stream;

  @override
  HardwareConnectionStatus get currentStatus => _status;

  @override
  Stream<SensorDataPoint> get sensorStream => _sensorController.stream;

  @override
  bool get isDemoMode => _isDemoMode;

  @override
  void setDemoMode(bool enabled) {
    _isDemoMode = enabled;
    _startDataLoop();
  }

  void _startDataLoop() {
    _generatorTimer?.cancel();
    // 20Hz update loop (every 50ms) for ultra-smooth real-time biological charts
    _generatorTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_status != HardwareConnectionStatus.connected) return;

      final now = DateTime.now();

      if (!_isDemoMode) {
        // Real-Time Mode default: When no physical ESP32 packet is streaming,
        // all sensor metrics remain zero and waveforms are flat straight lines.
        _sensorController.add(SensorDataPoint.zero());
        return;
      }

      _phase += 0.1;
      if (_phase > 10000) _phase = 0.0;

      if (_isDemoMode) {
        // High-fidelity Multimodal Signal Generation
        
        // 1. EEG: Alpha (8-12Hz) + Beta (13-30Hz) rhythms + biological noise (uV)
        final eegAlpha = math.sin(_phase * 2.1) * 18.0;
        final eegBeta = math.sin(_phase * 5.4) * 8.0;
        final eegDelta = math.cos(_phase * 0.4) * 22.0;
        final eegNoise = (_rng.nextDouble() - 0.5) * 6.0;
        final eegVal = eegAlpha + eegBeta + eegDelta + eegNoise;

        // 2. EMG: Muscle bursts + baseline (mV)
        final emgBurst = (math.sin(_phase * 0.3) > 0.6) 
            ? ((_rng.nextDouble() * 2.8) + 1.2) 
            : (_rng.nextDouble() * 0.25 + 0.05);

        // 3. GSR: Tonic baseline (~8.5 uS) with slow phasic skin conductance responses
        final gsrTonic = 8.5 + math.sin(_phase * 0.05) * 1.8;
        final gsrPhasic = (math.sin(_phase * 0.15).clamp(0.0, 1.0)) * 2.5;
        final gsrVal = (gsrTonic + gsrPhasic + (_rng.nextDouble() * 0.08)).clamp(1.0, 30.0);

        // 4. MAX30102 PPG & Vitals: Pulsatile dicrotic notch waveform
        final ppgPhase = (_phase * 2.5) % (2 * math.pi);
        final ppgRaw = math.sin(ppgPhase) + (0.4 * math.sin(2 * ppgPhase + 1.2));
        final hrVal = 72.0 + math.sin(_phase * 0.08) * 5.0 + (_rng.nextDouble() * 1.5);
        final hrvVal = 62.0 + math.cos(_phase * 0.06) * 12.0;
        final spo2Val = 98.4 + (math.sin(_phase * 0.02) * 0.8).clamp(-1.0, 1.0);

        // 5. FSR: Periodic isometric load force (N)
        final fsrVal = (math.sin(_phase * 0.2) > 0.2) 
            ? (18.0 + math.sin(_phase * 0.8) * 10.0 + _rng.nextDouble() * 2.0)
            : (2.0 + _rng.nextDouble() * 1.0);

        // 6. DHT11: Environmental temperature & humidity
        final tempVal = 36.6 + math.sin(_phase * 0.01) * 0.4;
        final humVal = 52.0 + math.cos(_phase * 0.01) * 2.0;

        final point = SensorDataPoint(
          timestamp: now,
          eeg: eegVal,
          emg: emgBurst,
          gsr: gsrVal,
          heartRate: hrVal,
          hrv: hrvVal,
          spo2: spo2Val,
          fsr: fsrVal,
          temperature: tempVal,
          humidity: humVal,
          ppg: ppgRaw,
        );

        _sensorController.add(point);
      }
    });
  }

  @override
  Future<List<DiscoveredDevice>> scanDevices({required ConnectionType type}) async {
    _status = HardwareConnectionStatus.searching;
    _statusController.add(_status);
    
    // Simulate real hardware discovery delay
    await Future.delayed(const Duration(milliseconds: 1500));
    
    _status = HardwareConnectionStatus.disconnected;
    _statusController.add(_status);

    return [
      DiscoveredDevice(
        name: "TRIAX_ESP32_DEV",
        deviceId: "ESP32-TX-89A4",
        rssi: -58,
        batteryLevel: 94,
        type: type,
      ),
      DiscoveredDevice(
        name: "TRIAX_LAB_NODE_02",
        deviceId: "ESP32-TX-91B2",
        rssi: -74,
        batteryLevel: 82,
        type: type,
      ),
    ];
  }

  @override
  Future<bool> connect(String deviceId, {required ConnectionType type}) async {
    _status = HardwareConnectionStatus.connecting;
    _statusController.add(_status);
    
    await Future.delayed(const Duration(milliseconds: 1200));
    
    _status = HardwareConnectionStatus.connected;
    _statusController.add(_status);
    _startDataLoop();
    return true;
  }

  @override
  Future<void> disconnect() async {
    _status = HardwareConnectionStatus.disconnected;
    _statusController.add(_status);
  }

  /// Entry point for real ESP32 JSON / BLE packets
  void injectRealDataPacket(Map<String, dynamic> rawJson) {
    if (!_isDemoMode && _status == HardwareConnectionStatus.connected) {
      final point = SensorDataPoint.fromJson(rawJson);
      _sensorController.add(point);
    }
  }

  void dispose() {
    _generatorTimer?.cancel();
    _statusController.close();
    _sensorController.close();
  }
}
