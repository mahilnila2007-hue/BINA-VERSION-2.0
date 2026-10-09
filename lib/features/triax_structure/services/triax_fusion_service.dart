import 'dart:math' as math;
import '../../sensors/models/sensor_data_model.dart';
import '../../ai/models/ai_inference_model.dart';

class TRIAXFusionState {
  final double fusionIndex; // 0.0 to 100.0 Multimodal Stability Score
  final double networkEntropy; // Physiological complexity
  final Map<String, double> nodeActivities; // Node ID -> Activity (0.0 to 1.0)
  final List<String> activeSignalPathways;

  TRIAXFusionState({
    required this.fusionIndex,
    required this.networkEntropy,
    required this.nodeActivities,
    required this.activeSignalPathways,
  });
}

class TRIAXFusionService {
  TRIAXFusionState fuse({
    required SensorDataPoint data,
    required ExtractedFeatures features,
    required List<AIInferenceResult> aiResults,
  }) {
    final isAllZero = data.eeg == 0.0 &&
        data.emg == 0.0 &&
        data.gsr == 0.0 &&
        data.heartRate == 0.0 &&
        data.fsr == 0.0 &&
        data.temperature == 0.0;

    if (isAllZero) {
      return TRIAXFusionState(
        fusionIndex: 0.0,
        networkEntropy: 0.0,
        nodeActivities: {
          'CENTRAL_FUSION': 0.0,
          'NODE_EEG': 0.0,
          'NODE_EMG': 0.0,
          'NODE_GSR': 0.0,
          'NODE_MAX': 0.0,
          'NODE_FSR': 0.0,
          'NODE_DHT': 0.0,
        },
        activeSignalPathways: [
          'Real-Time Mode (Waiting for ESP32 stream)',
        ],
      );
    }

    // Central Node: Multimodal Feature Fusion
    final eegAct = (features.alpha + features.beta) / 100.0;
    final emgAct = (data.emg / 4.0).clamp(0.0, 1.0);
    final gsrAct = (data.gsr / 20.0).clamp(0.0, 1.0);
    final cardAct = ((data.heartRate - 50) / 70.0).clamp(0.0, 1.0);
    final fsrAct = (data.fsr / 40.0).clamp(0.0, 1.0);
    final envAct = (data.temperature / 40.0).clamp(0.0, 1.0);

    final fusionScore = (eegAct * 0.25 + emgAct * 0.15 + gsrAct * 0.2 + cardAct * 0.25 + fsrAct * 0.1 + envAct * 0.05) * 100.0;

    final entropy = 1.45 + (math.sin(features.delta * 0.05) * 0.2);

    return TRIAXFusionState(
      fusionIndex: fusionScore.clamp(10.0, 99.0),
      networkEntropy: entropy,
      nodeActivities: {
        'CENTRAL_FUSION': (fusionScore / 100.0).clamp(0.1, 1.0),
        'NODE_EEG': eegAct.clamp(0.1, 1.0),
        'NODE_EMG': emgAct.clamp(0.1, 1.0),
        'NODE_GSR': gsrAct.clamp(0.1, 1.0),
        'NODE_MAX': cardAct.clamp(0.1, 1.0),
        'NODE_FSR': fsrAct.clamp(0.1, 1.0),
        'NODE_DHT': envAct.clamp(0.1, 1.0),
      },
      activeSignalPathways: [
        'Central ↔ EEG (Cortical Channel)',
        'Central ↔ MAX30102 (Photoplethysmography Sync)',
        'EEG ↔ GSR (Sympathetic Tone Interlock)',
        'EMG ↔ FSR (Neuromechanical Feedback)',
      ],
    );
  }
}
