import 'dart:convert';
import '../../sensors/models/sensor_data_model.dart';
import '../../ai/models/ai_inference_model.dart';
import '../../triax_structure/services/triax_fusion_service.dart';

enum MessageSender {
  user,
  assistant,
  system,
}

enum LocalModelStatus {
  online,
  offline,
  loading,
  error,
}

enum UserIntent {
  generalChat,
  triaxPhysiologicalQuery,
}

class TriaxChatMessage {
  final String id;
  final MessageSender sender;
  final String text;
  final DateTime timestamp;
  final bool isThinking;
  final Map<String, dynamic>? structuredContext;

  TriaxChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.isThinking = false,
    this.structuredContext,
  });

  TriaxChatMessage copyWith({
    String? id,
    MessageSender? sender,
    String? text,
    DateTime? timestamp,
    bool? isThinking,
    Map<String, dynamic>? structuredContext,
  }) {
    return TriaxChatMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isThinking: isThinking ?? this.isThinking,
      structuredContext: structuredContext ?? this.structuredContext,
    );
  }
}

class TriaxStructuredPayload {
  final double heartRate;
  final double hrv;
  final double spo2;
  final double gsr;
  final double emgRms;
  final double fsrPressure;
  final double temperature;
  final double humidity;
  final double fusionIndex;
  final Map<String, String> existingMlPatterns;
  final List<String> keyRelationships;

  TriaxStructuredPayload({
    required this.heartRate,
    required this.hrv,
    required this.spo2,
    required this.gsr,
    required this.emgRms,
    required this.fsrPressure,
    required this.temperature,
    required this.humidity,
    required this.fusionIndex,
    required this.existingMlPatterns,
    required this.keyRelationships,
  });

  factory TriaxStructuredPayload.fromState({
    required SensorDataPoint data,
    required ExtractedFeatures features,
    required TRIAXFusionState fusionState,
    required List<AIInferenceResult> aiResults,
  }) {
    final patternMap = <String, String>{};
    for (final res in aiResults) {
      patternMap[res.categoryTitle] = "${res.statusText} (${res.modelArchitecture}, ${(res.confidence * 100).toStringAsFixed(0)}% conf)";
    }

    return TriaxStructuredPayload(
      heartRate: data.heartRate,
      hrv: data.hrv,
      spo2: data.spo2,
      gsr: data.gsr,
      emgRms: features.emgRms,
      fsrPressure: features.fsrPressure,
      temperature: data.temperature,
      humidity: data.humidity,
      fusionIndex: fusionState.fusionIndex,
      existingMlPatterns: patternMap,
      keyRelationships: fusionState.activeSignalPathways,
    );
  }

  Map<String, dynamic> toJson() => {
    'heart_rate': heartRate > 0 ? double.parse(heartRate.toStringAsFixed(1)) : 0.0,
    'hrv': hrv > 0 ? double.parse(hrv.toStringAsFixed(1)) : 0.0,
    'spo2': spo2 > 0 ? double.parse(spo2.toStringAsFixed(1)) : 0.0,
    'gsr': gsr > 0 ? double.parse(gsr.toStringAsFixed(2)) : 0.0,
    'emg_rms': emgRms > 0 ? double.parse(emgRms.toStringAsFixed(2)) : 0.0,
    'fsr_pressure': fsrPressure > 0 ? double.parse(fsrPressure.toStringAsFixed(1)) : 0.0,
    'temperature': temperature > 0 ? double.parse(temperature.toStringAsFixed(1)) : 0.0,
    'humidity': humidity > 0 ? double.parse(humidity.toStringAsFixed(0)) : 0.0,
    'fusion_index': fusionIndex > 0 ? double.parse(fusionIndex.toStringAsFixed(1)) : 0.0,
    'existing_ml_patterns': existingMlPatterns,
    'key_relationships': keyRelationships,
  };

  String toFormattedJsonString() {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(toJson());
  }
}

class TriaxIntentClassifier {
  static const Set<String> _triaxKeywords = {
    'eeg',
    'emg',
    'gsr',
    'max30102',
    'max',
    'heart rate',
    'hr',
    'bpm',
    'hrv',
    'rmssd',
    'spo2',
    'oxygen',
    'ppg',
    'photoplethysmogram',
    'fsr',
    'pressure',
    'force',
    'temperature',
    'temp',
    'humidity',
    'dht11',
    'stress',
    'sympathetic',
    'parasympathetic',
    'sleep',
    'circadian',
    'seizure',
    'arrhythmia',
    'myoelectric',
    'neuromuscular',
    'physiological',
    'signals',
    'sensor',
    'sensors',
    'triax',
    'montage',
    'fusion',
    'ml results',
    'session summary',
    'my readings',
    'my current',
    'current signals',
    'current session',
    'previous session',
  };

  static UserIntent classify(String userPrompt) {
    final lower = userPrompt.toLowerCase().trim();
    if (lower.isEmpty) return UserIntent.generalChat;

    // Check specific conversational greetings / general queries first
    if (lower == 'hi' ||
        lower == 'hello' ||
        lower == 'hey' ||
        lower == 'how are you' ||
        lower == 'how are you?' ||
        lower == 'who are you' ||
        lower == 'who are you?' ||
        lower == 'good morning' ||
        lower == 'good evening' ||
        lower == 'help' ||
        lower == 'what can you do' ||
        lower == 'what can you do?') {
      return UserIntent.generalChat;
    }

    for (final keyword in _triaxKeywords) {
      if (lower.contains(keyword)) {
        return UserIntent.triaxPhysiologicalQuery;
      }
    }

    return UserIntent.generalChat;
  }
}
