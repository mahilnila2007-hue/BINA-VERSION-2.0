import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/state/triax_app_state.dart';
import '../../sensors/models/sensor_data_model.dart';
import '../widgets/triax_structure_painter.dart';
import '../widgets/correlation_card.dart';

class TriaxStructureScreen extends StatefulWidget {
  const TriaxStructureScreen({super.key});

  @override
  State<TriaxStructureScreen> createState() => _TriaxStructureScreenState();
}

class _TriaxStructureScreenState extends State<TriaxStructureScreen> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  bool _isAutoRotating = true;
  double _rotX = 0.25;
  double _rotY = 0.0;
  double _scale = 1.1;
  String? _selectedNodeId = 'CENTRAL_FUSION';

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..addListener(() {
        if (_isAutoRotating) {
          setState(() {
            _rotY = _rotationController.value * 2 * 3.14159;
          });
        }
      })
      ..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<TriaxAppState>(context);
    final fusionState = appState.fusionState;
    final features = appState.features;
    final correlations = appState.correlations;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("TRIAX Multimodal Topology"),
        actions: [
          IconButton(
            icon: Icon(_isAutoRotating ? Icons.pause_circle_outline : Icons.play_circle_outline),
            tooltip: _isAutoRotating ? "Pause Auto-Rotation" : "Resume Auto-Rotation",
            onPressed: () {
              setState(() {
                _isAutoRotating = !_isAutoRotating;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded),
            tooltip: "Reset Orientation",
            onPressed: () {
              setState(() {
                _rotX = 0.25;
                _rotY = 0.0;
                _scale = 1.1;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 3D Interactive Canvas Box
              GestureDetector(
                onScaleUpdate: (details) {
                  setState(() {
                    if (details.pointerCount == 1) {
                      _isAutoRotating = false;
                      _rotY += details.focalPointDelta.dx * 0.015;
                      _rotX -= details.focalPointDelta.dy * 0.015;
                    } else if (details.pointerCount > 1) {
                      _scale = (_scale * details.scale).clamp(0.7, 1.8);
                    }
                  });
                },
                child: Container(
                  height: 340,
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: TriaxStructurePainter(
                            rotX: _rotX,
                            rotY: _rotY,
                            rotZ: 0.0,
                            scale: _scale,
                            nodeActivities: fusionState.nodeActivities,
                            selectedNodeId: _selectedNodeId,
                            pulsePhase: _rotationController.value,
                          ),
                        ),
                      ),
                      // Top Left Overlay: Multimodal Fusion Index
                      Positioned(
                        top: 14,
                        left: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryNavy.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "FUSION INDEX",
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryNavy,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Text(
                                "${fusionState.fusionIndex.toStringAsFixed(1)} / 100",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryNavy,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Top Right: 3D Control Hints
                      Positioned(
                        top: 14,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.touch_app_outlined, size: 12, color: AppTheme.textMuted),
                              SizedBox(width: 4),
                              Text(
                                "Drag to Rotate • Pinch Zoom",
                                style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Node Selector Carousel
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: const Text(
                  "SELECT TRIAX NODE FOR DEEP INSPECTION",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildNodeFilterChip("CENTRAL_FUSION", "Core Fusion", AppTheme.primaryBlue),
                    _buildNodeFilterChip("NODE_EEG", "EEG (Cortical)", AppTheme.eegPurple),
                    _buildNodeFilterChip("NODE_EMG", "EMG (Myo)", AppTheme.emgGreen),
                    _buildNodeFilterChip("NODE_GSR", "GSR (Skin)", AppTheme.gsrOrange),
                    _buildNodeFilterChip("NODE_MAX", "MAX30102 (Cardio)", AppTheme.maxRed),
                    _buildNodeFilterChip("NODE_FSR", "FSR (Force)", AppTheme.fsrAmber),
                    _buildNodeFilterChip("NODE_DHT", "DHT11 (Ambient)", AppTheme.dhtBlue),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Detailed Node Feature Breakdown Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildSelectedNodeFeatureCard(features, appState.currentData),
              ),

              const SizedBox(height: 24),

              // Cross-Modality Correlation Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "CROSS-MODALITY FEATURE CORRELATION MATRIX",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMuted,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Real-time Pearson coefficients calculated across biological signal channels.",
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 12),
                    ...correlations.map((c) => CorrelationCard(correlation: c)),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNodeFilterChip(String id, String label, Color color) {
    final isSelected = (_selectedNodeId == id);
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedNodeId = selected ? id : null;
          });
        },
        selectedColor: color.withValues(alpha: 0.18),
        backgroundColor: AppTheme.cardBg,
        checkmarkColor: color,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? color : AppTheme.textDark,
        ),
        side: BorderSide(
          color: isSelected ? color : AppTheme.borderLight,
          width: isSelected ? 1.5 : 1.0,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSelectedNodeFeatureCard(ExtractedFeatures f, dynamic data) {
    String title = "Multimodal Feature Fusion";
    String desc = "Central mathematical nexus performing cross-attention across all 6 physiological sensor streams.";
    List<Map<String, String>> metrics = [];

    switch (_selectedNodeId) {
      case 'NODE_EEG':
        title = "EEG Cortical Spectral Bands";
        desc = "Real-time relative power distribution decomposed via continuous Fast Fourier Transform.";
        metrics = [
          {'Delta (0.5-4Hz)': '${f.delta.toStringAsFixed(1)}%'},
          {'Theta (4-8Hz)': '${f.theta.toStringAsFixed(1)}%'},
          {'Alpha (8-13Hz)': '${f.alpha.toStringAsFixed(1)}%'},
          {'Beta (13-30Hz)': '${f.beta.toStringAsFixed(1)}%'},
          {'Gamma (>30Hz)': '${f.gamma.toStringAsFixed(1)}%'},
        ];
        break;
      case 'NODE_EMG':
        title = "EMG Myoelectric Parameters";
        desc = "Brachioradialis muscle fiber action potentials and motor unit recruitment statistics.";
        metrics = [
          {'RMS Amplitude': '${f.emgRms.toStringAsFixed(2)} mV'},
          {'Mean Absolute Val (MAV)': '${f.emgMav.toStringAsFixed(2)} mV'},
          {'Mean Frequency (MNF)': '${f.emgMeanFreq.toStringAsFixed(1)} Hz'},
          {'Median Frequency (MDF)': '${f.emgMedianFreq.toStringAsFixed(1)} Hz'},
          {'Fatigue Index': '${(f.emgFatigueIndex * 100).toStringAsFixed(0)}%'},
        ];
        break;
      case 'NODE_GSR':
        title = "GSR Electrodermal Dynamics";
        desc = "Sympathetic sudomotor innervation and skin conductance fluctuations.";
        metrics = [
          {'Tonic Level (SCL)': '${f.gsrScl.toStringAsFixed(2)} µS'},
          {'Phasic Response (SCR)': '${f.gsrScr.toStringAsFixed(2)} µS'},
          {'Response Amplitude': '${f.gsrResponseAmp.toStringAsFixed(2)} µS'},
          {'Phasic Event Count': '${f.gsrResponseCount}'},
          {'Recovery Half-Time': '${f.gsrRecoveryTime.toStringAsFixed(1)} s'},
        ];
        break;
      case 'NODE_MAX':
        title = "MAX30102 Cardiovascular Hemodynamics";
        desc = "Dual-wavelength optical photoplethysmography and beat-to-beat variability.";
        metrics = [
          {'Heart Rate': '${f.hr.toStringAsFixed(0)} bpm'},
          {'HRV RMSSD': '${f.hrvRmssd.toStringAsFixed(1)} ms'},
          {'SpO2 Saturation': '${f.spo2.toStringAsFixed(1)}%'},
          {'PPG Pulse Amplitude': '${f.ppgAmplitude.toStringAsFixed(1)} a.u.'},
        ];
        break;
      case 'NODE_FSR':
        title = "FSR Biomechanical Load";
        desc = "Isometric strain sensor monitoring muscular force output and contact dynamics.";
        metrics = [
          {'Load Resistance': '${f.fsrPressure.toStringAsFixed(1)} Ω'},
          {'Estimated Force': '${f.fsrForce.toStringAsFixed(2)} N'},
          {'Movement Status': f.movementStatus},
          {'Contact Duration': '${f.contactDuration.toStringAsFixed(0)} s'},
        ];
        break;
      case 'NODE_DHT':
        title = "DHT11 Microclimate Context";
        desc = "Ambient laboratory climate metrics preventing physiological temperature drift artifacts.";
        metrics = [
          {'Surface/Ambient Temp': '${f.temperature.toStringAsFixed(1)} °C'},
          {'Relative Humidity': '${f.humidity.toStringAsFixed(0)}%'},
          {'Thermal Index': 'Nominal'},
        ];
        break;
      default:
        metrics = [
          {'Multimodal Latent Dim': '128-d'},
          {'Active Relational Struts': '12 Struts'},
          {'Global Homeostasis': 'Synchronized'},
        ];
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.borderLight),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: metrics.map((m) {
              final key = m.keys.first;
              final val = m.values.first;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "$key: ",
                      style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                    ),
                    Text(
                      val,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
