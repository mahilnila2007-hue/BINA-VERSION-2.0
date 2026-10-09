import 'ml_service.dart';
import '../models/ai_inference_model.dart';
import '../../sensors/models/sensor_data_model.dart';

class MockMLServiceImpl implements MLService {
  @override
  Future<AIInferenceResult> analyzeArrhythmia(SensorDataPoint data, ExtractedFeatures features) async {
    if (data.heartRate == 0.0 && data.eeg == 0.0) {
      return AIInferenceResult(
        categoryTitle: "ARRHYTHMIA PATTERN",
        modelArchitecture: "1D-CNN",
        status: PatternStatus.normal,
        statusText: "Idle (Awaiting Live ESP32 ECG/PPG)",
        confidence: 0.0,
        signalContribution: "MAX30102 (Offline / 0 bpm)",
        summary: "Real-time Mode is active. Waiting for physical ESP32 pulse packets.",
        clinicalNotes: [
          "PPG Peak-to-Peak: 0.0 a.u.",
          "HRV RMSSD: 0.0 ms",
          "Estimated Mean PR Interval: 0 ms",
        ],
        severityScore: 0.0,
      );
    }
    // 1D-CNN Pattern Classifier
    final isNormal = data.heartRate >= 60 && data.heartRate <= 100 && features.hrvRmssd >= 35;
    return AIInferenceResult(
      categoryTitle: "ARRHYTHMIA PATTERN",
      modelArchitecture: "1D-CNN",
      status: isNormal ? PatternStatus.normal : PatternStatus.abnormalityIndicator,
      statusText: isNormal ? "Normal Sinus Rhythm Pattern" : "Abnormality Indicator: Ectopic Pulse Interval",
      confidence: 0.88,
      signalContribution: "MAX30102 (PPG Pulse Morphology & R-R Variance)",
      summary: isNormal 
          ? "R-R intervals exhibit consistent morphology with typical respiratory sinus arrhythmia."
          : "Mild irregularity detected in inter-beat interval sequence. Requires clinical evaluation.",
      clinicalNotes: [
        "PPG Peak-to-Peak: ${features.ppgAmplitude.toStringAsFixed(1)} a.u.",
        "HRV RMSSD: ${features.hrvRmssd.toStringAsFixed(1)} ms",
        "Estimated Mean PR Interval: 154 ms",
      ],
      severityScore: isNormal ? 15.0 : 68.0,
    );
  }

  @override
  Future<AIInferenceResult> analyzeSleep(SensorDataPoint data, ExtractedFeatures features) async {
    // LSTM Sequence Model
    final isAwake = features.beta > 20 || features.alpha > 35;
    return AIInferenceResult(
      categoryTitle: "SLEEP & CIRCADIAN PATTERNS",
      modelArchitecture: "LSTM",
      status: PatternStatus.normal,
      statusText: isAwake ? "Alert Wakefulness Pattern" : "Transitional N1/N2 Rest Pattern",
      confidence: 0.85,
      signalContribution: "EEG (Delta/Theta Ratios) + Accelerometer/FSR",
      summary: "Physiological rhythms indicate active cognitive state with balanced cortical power distribution.",
      clinicalNotes: [
        "Delta Spectral Power: ${features.delta.toStringAsFixed(1)}%",
        "Theta Spectral Power: ${features.theta.toStringAsFixed(1)}%",
        "Alpha / Beta Ratio: ${(features.alpha / (features.beta + 0.1)).toStringAsFixed(2)}",
      ],
      severityScore: 12.0,
    );
  }

  @override
  Future<AIInferenceResult> analyzeSeizure(SensorDataPoint data, ExtractedFeatures features) async {
    // CNN-LSTM Spatiotemporal Model
    final highGammaSpike = features.gamma > 45 || data.eeg.abs() > 85;
    return AIInferenceResult(
      categoryTitle: "SEIZURE-LIKE EEG PATTERNS",
      modelArchitecture: "CNN-LSTM",
      status: highGammaSpike ? PatternStatus.abnormalityIndicator : PatternStatus.normal,
      statusText: highGammaSpike ? "Abnormality Indicator: Paroxysmal Waveform" : "Normal Background EEG",
      confidence: 0.94,
      signalContribution: "EEG Raw uV + Spectral Band Power",
      summary: highGammaSpike 
          ? "Spike-and-wave synchronous bursts observed across virtual montage channels."
          : "No paroxysmal high-amplitude rhythmic discharges detected in current temporal window.",
      clinicalNotes: [
        "Peak-to-Peak EEG: ${data.eeg.toStringAsFixed(1)} µV",
        "Gamma Rhythm Ratio: ${features.gamma.toStringAsFixed(1)}%",
        "Bilateral Synchrony Index: 0.91",
      ],
      severityScore: highGammaSpike ? 82.0 : 8.0,
    );
  }

  @override
  Future<AIInferenceResult> analyzeStress(SensorDataPoint data, ExtractedFeatures features) async {
    // XGBoost Feature Classifier
    final isElevated = features.gsrScl > 12.0 || data.heartRate > 88;
    return AIInferenceResult(
      categoryTitle: "PSYCHOLOGICAL STRESS PATTERN",
      modelArchitecture: "XGBoost",
      status: isElevated ? PatternStatus.elevated : PatternStatus.normal,
      statusText: isElevated ? "Elevated Sympathetic Pattern" : "Normal Homeostatic Pattern",
      confidence: 0.91,
      signalContribution: "GSR + HR + EEG (Frontal Asymmetry)",
      summary: isElevated
          ? "Skin conductance phasic spikes accompanied by reduced heart rate variability indicate sympathetic arousal."
          : "Sympathetic/parasympathetic balance is within baseline relaxation boundaries.",
      clinicalNotes: [
        "Tonic Skin Conductance (SCL): ${features.gsrScl.toStringAsFixed(1)} µS",
        "Phasic Skin Responses (SCR): ${features.gsrScr.toStringAsFixed(2)} µS",
        "Stress Index Composite: ${(features.gsrScl * 4.2 + (data.heartRate * 0.4)).toStringAsFixed(0)} / 100",
      ],
      severityScore: isElevated ? 65.0 : 22.0,
    );
  }

  @override
  Future<AIInferenceResult> analyzeNeuromuscular(SensorDataPoint data, ExtractedFeatures features) async {
    // SVM Classifier
    final isFatigued = features.emgFatigueIndex > 0.4;
    return AIInferenceResult(
      categoryTitle: "NEUROMUSCULAR ABNORMALITIES",
      modelArchitecture: "SVM",
      status: isFatigued ? PatternStatus.elevated : PatternStatus.normal,
      statusText: isFatigued ? "Pattern Detected: Muscular Fatigue Indicator" : "Normal Neuromuscular Pattern",
      confidence: 0.86,
      signalContribution: "EMG (RMS, Median Freq) + FSR Pressure",
      summary: isFatigued
          ? "Spectral compression towards lower frequencies indicates localized muscular fatigue onset."
          : "Stable motor unit recruitment with normal frequency distribution and force proportionality.",
      clinicalNotes: [
        "EMG RMS Amplitude: ${features.emgRms.toStringAsFixed(2)} mV",
        "Mean Frequency: ${features.emgMeanFreq.toStringAsFixed(1)} Hz",
        "Median Spectral Shift: ${features.emgMedianFreq.toStringAsFixed(1)} Hz",
      ],
      severityScore: isFatigued ? 48.0 : 18.0,
    );
  }

  @override
  Future<List<AIInferenceResult>> analyzeAll(SensorDataPoint data, ExtractedFeatures features) async {
    return Future.wait([
      analyzeArrhythmia(data, features),
      analyzeStress(data, features),
      analyzeSeizure(data, features),
      analyzeSleep(data, features),
      analyzeNeuromuscular(data, features),
    ]);
  }
}
