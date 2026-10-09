import '../../sensors/models/sensor_data_model.dart';
import '../../ai/models/ai_inference_model.dart';

class SessionRecord {
  final String id;
  final DateTime date;
  final Duration duration;
  final List<String> availableSensors;
  final double avgHeartRate;
  final double avgSpo2;
  final double stressScore; // 0 to 100
  final double eegAlphaBetaRatio;
  final String primaryPatternStatus;
  final List<AIInferenceResult> aiPatterns;
  final List<SensorDataPoint> sampledPoints;

  SessionRecord({
    required this.id,
    required this.date,
    required this.duration,
    required this.availableSensors,
    required this.avgHeartRate,
    required this.avgSpo2,
    required this.stressScore,
    required this.eegAlphaBetaRatio,
    required this.primaryPatternStatus,
    required this.aiPatterns,
    required this.sampledPoints,
  });
}
