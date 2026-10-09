import 'dart:async';
import 'package:flutter/material.dart';
import '../../features/sensors/models/sensor_data_model.dart';
import '../../features/sensors/services/hardware_service.dart';
import '../../features/sensors/services/hardware_service_impl.dart';
import '../../features/sensors/services/sensor_processing_service.dart';
import '../../features/sensors/services/feature_extraction_service.dart';
import '../../features/triax_structure/services/triax_fusion_service.dart';
import '../../features/ai/services/ml_service.dart';
import '../../features/ai/services/mock_ml_service.dart';
import '../../features/ai/models/ai_inference_model.dart';
import '../../features/history/models/session_model.dart';

class TriaxAppState extends ChangeNotifier {
  final HardwareService hardwareService;
  final SensorProcessingService processingService;
  final FeatureExtractionService featureService;
  final TRIAXFusionService fusionService;
  final MLService mlService;

  StreamSubscription? _sensorSub;
  StreamSubscription? _statusSub;
  Timer? _aiTimer;

  SensorDataPoint _currentData = SensorDataPoint.zero();
  ExtractedFeatures _features = ExtractedFeatures.fromSensorData(SensorDataPoint.zero(), 0.0);
  TRIAXFusionState _fusionState = TRIAXFusionState(
    fusionIndex: 0.0,
    networkEntropy: 0.0,
    nodeActivities: {},
    activeSignalPathways: [],
  );
  List<ModalityCorrelation> _correlations = [];
  List<AIInferenceResult> _aiResults = [];
  HardwareConnectionStatus _connectionStatus = HardwareConnectionStatus.connected;
  
  // History sessions list
  final List<SessionRecord> _historyRecords = [];

  // Active recording session
  bool _isRecording = false;
  DateTime? _sessionStartTime;
  final List<SensorDataPoint> _currentSessionPoints = [];

  TriaxAppState({
    HardwareService? hwService,
    SensorProcessingService? procService,
    FeatureExtractionService? featService,
    TRIAXFusionService? fusService,
    MLService? mlServ,
  })  : hardwareService = hwService ?? HardwareServiceImpl(),
        processingService = procService ?? SensorProcessingService(bufferCapacity: 120),
        featureService = featService ?? FeatureExtractionService(),
        fusionService = fusService ?? TRIAXFusionService(),
        mlService = mlServ ?? MockMLServiceImpl() {
    _initStreams();
    _seedMockHistory();
  }

  SensorDataPoint get currentData => _currentData;
  ExtractedFeatures get features => _features;
  TRIAXFusionState get fusionState => _fusionState;
  List<ModalityCorrelation> get correlations => _correlations;
  List<AIInferenceResult> get aiResults => _aiResults;
  HardwareConnectionStatus get connectionStatus => _connectionStatus;
  List<SensorDataPoint> get signalBuffer => processingService.buffer;
  List<SessionRecord> get historyRecords => List.unmodifiable(_historyRecords);
  bool get isRecording => _isRecording;
  bool get isDemoMode => hardwareService.isDemoMode;

  void _initStreams() {
    _statusSub = hardwareService.statusStream.listen((status) {
      _connectionStatus = status;
      notifyListeners();
    });

    _sensorSub = hardwareService.sensorStream.listen((point) {
      _currentData = point;
      processingService.addPoint(point);
      
      _features = featureService.extract(point);
      _correlations = featureService.computeCorrelations(processingService.buffer);
      _fusionState = fusionService.fuse(
        data: point,
        features: _features,
        aiResults: _aiResults,
      );

      if (_isRecording) {
        _currentSessionPoints.add(point);
      }

      notifyListeners();
    });

    // Periodic AI inference update (every 1.5 seconds)
    _aiTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
      if (_connectionStatus == HardwareConnectionStatus.connected) {
        final results = await mlService.analyzeAll(_currentData, _features);
        _aiResults = results;
        notifyListeners();
      }
    });
  }

  void toggleDemoMode(bool enable) {
    hardwareService.setDemoMode(enable);
    processingService.clear();
    if (!enable) {
      _currentData = SensorDataPoint.zero();
      _features = ExtractedFeatures.fromSensorData(SensorDataPoint.zero(), 0.0);
      _fusionState = TRIAXFusionState(
        fusionIndex: 0.0,
        networkEntropy: 0.0,
        nodeActivities: {},
        activeSignalPathways: [],
      );
      // Pre-fill buffer with flat zero points for clean straight lines
      for (int i = 0; i < 60; i++) {
        processingService.addPoint(SensorDataPoint.zero());
      }
    }
    notifyListeners();
  }

  void startRecording() {
    _isRecording = true;
    _sessionStartTime = DateTime.now();
    _currentSessionPoints.clear();
    notifyListeners();
  }

  void stopRecording() {
    if (!_isRecording) return;
    _isRecording = false;
    final endTime = DateTime.now();
    final duration = endTime.difference(_sessionStartTime ?? endTime);

    final avgHr = _currentSessionPoints.isNotEmpty
        ? _currentSessionPoints.map((p) => p.heartRate).reduce((a, b) => a + b) / _currentSessionPoints.length
        : 72.0;

    final avgSpo2 = _currentSessionPoints.isNotEmpty
        ? _currentSessionPoints.map((p) => p.spo2).reduce((a, b) => a + b) / _currentSessionPoints.length
        : 98.4;

    final newRecord = SessionRecord(
      id: 'REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      date: _sessionStartTime ?? DateTime.now(),
      duration: duration.inSeconds < 1 ? const Duration(seconds: 45) : duration,
      availableSensors: ['EEG', 'EMG', 'GSR', 'MAX30102', 'FSR', 'DHT11'],
      avgHeartRate: avgHr,
      avgSpo2: avgSpo2,
      stressScore: 24.0,
      eegAlphaBetaRatio: 1.42,
      primaryPatternStatus: "Normal Homeostatic Pattern",
      aiPatterns: List.from(_aiResults),
      sampledPoints: List.from(_currentSessionPoints),
    );

    _historyRecords.insert(0, newRecord);
    notifyListeners();
  }

  double getSignalQuality(String sensor) => processingService.calculateSignalQuality(sensor);

  void _seedMockHistory() {
    _historyRecords.addAll([
      SessionRecord(
        id: 'REC-89214',
        date: DateTime.now().subtract(const Duration(hours: 3, minutes: 20)),
        duration: const Duration(minutes: 18, seconds: 45),
        availableSensors: ['EEG', 'EMG', 'GSR', 'MAX30102', 'FSR', 'DHT11'],
        avgHeartRate: 71.4,
        avgSpo2: 98.8,
        stressScore: 22.0,
        eegAlphaBetaRatio: 1.48,
        primaryPatternStatus: "Normal Pattern",
        aiPatterns: [],
        sampledPoints: [],
      ),
      SessionRecord(
        id: 'REC-87612',
        date: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        duration: const Duration(minutes: 34, seconds: 10),
        availableSensors: ['EEG', 'EMG', 'GSR', 'MAX30102', 'FSR', 'DHT11'],
        avgHeartRate: 78.2,
        avgSpo2: 97.9,
        stressScore: 48.0,
        eegAlphaBetaRatio: 1.12,
        primaryPatternStatus: "Elevated Sympathetic Pattern",
        aiPatterns: [],
        sampledPoints: [],
      ),
      SessionRecord(
        id: 'REC-84190',
        date: DateTime.now().subtract(const Duration(days: 3, hours: 5)),
        duration: const Duration(minutes: 25, seconds: 0),
        availableSensors: ['EEG', 'EMG', 'GSR', 'MAX30102', 'FSR', 'DHT11'],
        avgHeartRate: 69.5,
        avgSpo2: 99.1,
        stressScore: 18.5,
        eegAlphaBetaRatio: 1.62,
        primaryPatternStatus: "Normal Pattern",
        aiPatterns: [],
        sampledPoints: [],
      ),
    ]);
  }

  @override
  void dispose() {
    _sensorSub?.cancel();
    _statusSub?.cancel();
    _aiTimer?.cancel();
    if (hardwareService is HardwareServiceImpl) {
      (hardwareService as HardwareServiceImpl).dispose();
    }
    super.dispose();
  }
}
