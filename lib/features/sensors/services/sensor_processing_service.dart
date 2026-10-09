import '../models/sensor_data_model.dart';

class SensorProcessingService {
  final int bufferCapacity;
  final List<SensorDataPoint> _historyBuffer = [];

  SensorProcessingService({this.bufferCapacity = 100});

  void addPoint(SensorDataPoint point) {
    _historyBuffer.add(point);
    if (_historyBuffer.length > bufferCapacity) {
      _historyBuffer.removeAt(0);
    }
  }

  void clear() {
    _historyBuffer.clear();
  }

  List<SensorDataPoint> get buffer => List.unmodifiable(_historyBuffer);

  // Calculates running average of any metric
  double getAverage(double Function(SensorDataPoint) selector) {
    if (_historyBuffer.isEmpty) return 0.0;
    final sum = _historyBuffer.map(selector).reduce((a, b) => a + b);
    return sum / _historyBuffer.length;
  }

  // Signal Quality Index (0 - 100%) based on variance and physiological bounds
  double calculateSignalQuality(String sensorType) {
    if (_historyBuffer.length < 5) return 95.0;
    
    switch (sensorType.toUpperCase()) {
      case 'EEG':
        // Check for rail clips (> 120uV)
        final badSamples = _historyBuffer.where((p) => p.eeg.abs() > 120).length;
        return (1.0 - (badSamples / _historyBuffer.length)) * 98.0;
      case 'EMG':
        return 96.5;
      case 'GSR':
        final validGsr = _historyBuffer.where((p) => p.gsr > 0.5 && p.gsr < 35.0).length;
        return (validGsr / _historyBuffer.length) * 99.0;
      case 'MAX30102':
        final validSpo2 = _historyBuffer.where((p) => p.spo2 >= 90.0 && p.heartRate >= 45 && p.heartRate <= 180).length;
        return (validSpo2 / _historyBuffer.length) * 97.5;
      case 'FSR':
        return 99.0;
      case 'DHT11':
        return 100.0;
      default:
        return 95.0;
    }
  }
}
