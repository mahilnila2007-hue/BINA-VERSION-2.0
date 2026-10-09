enum PatternStatus {
  normal,
  elevated,
  abnormalityIndicator,
  screeningRequired,
}

class AIInferenceResult {
  final String categoryTitle;
  final String modelArchitecture; // e.g. "1D-CNN", "LSTM", "CNN-LSTM", "XGBoost", "SVM"
  final PatternStatus status;
  final String statusText;
  final double confidence; // 0.0 to 1.0 (e.g. 0.82)
  final String signalContribution; // e.g. "MAX30102 (PPG + HR variability)"
  final String summary;
  final List<String> clinicalNotes;
  final double severityScore; // 0.0 to 100.0 for gauge

  AIInferenceResult({
    required this.categoryTitle,
    required this.modelArchitecture,
    required this.status,
    required this.statusText,
    required this.confidence,
    required this.signalContribution,
    required this.summary,
    required this.clinicalNotes,
    required this.severityScore,
  });
}
