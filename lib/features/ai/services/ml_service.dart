import '../models/ai_inference_model.dart';
import '../../sensors/models/sensor_data_model.dart';

/// ML Service interface abstraction
/// Easily interchangeable with Python Backend, TFLite, or ONNX Runtime
abstract class MLService {
  Future<AIInferenceResult> analyzeArrhythmia(SensorDataPoint data, ExtractedFeatures features);
  Future<AIInferenceResult> analyzeSleep(SensorDataPoint data, ExtractedFeatures features);
  Future<AIInferenceResult> analyzeSeizure(SensorDataPoint data, ExtractedFeatures features);
  Future<AIInferenceResult> analyzeStress(SensorDataPoint data, ExtractedFeatures features);
  Future<AIInferenceResult> analyzeNeuromuscular(SensorDataPoint data, ExtractedFeatures features);
  
  Future<List<AIInferenceResult>> analyzeAll(SensorDataPoint data, ExtractedFeatures features);
}
