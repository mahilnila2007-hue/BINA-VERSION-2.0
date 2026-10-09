import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/state/triax_app_state.dart';
import '../../sensors/models/sensor_data_model.dart';
import '../../sensors/widgets/live_waveform_widget.dart';

class SignalAnalysisScreen extends StatefulWidget {
  final int initialSensorIndex;

  const SignalAnalysisScreen({super.key, this.initialSensorIndex = 0});

  @override
  State<SignalAnalysisScreen> createState() => _SignalAnalysisScreenState();
}

class _SignalAnalysisScreenState extends State<SignalAnalysisScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _sensorTabs = [
    'EEG',
    'EMG',
    'GSR',
    'MAX30102',
    'FSR',
    'DHT11',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _sensorTabs.length,
      vsync: this,
      initialIndex: widget.initialSensorIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<TriaxAppState>(context);
    final data = appState.currentData;
    final feat = appState.features;
    final buffer = appState.signalBuffer;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Signal Analysis"),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primaryNavy,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.primaryNavy,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: _sensorTabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEegTab(buffer.map((p) => p.eeg).toList(), data, feat),
          _buildEmgTab(buffer.map((p) => p.emg).toList(), data, feat),
          _buildGsrTab(buffer.map((p) => p.gsr).toList(), data, feat),
          _buildMaxTab(buffer.map((p) => p.ppg).toList(), data, feat),
          _buildFsrTab(buffer.map((p) => p.fsr).toList(), data, feat),
          _buildDhtTab(buffer.map((p) => p.temperature).toList(), data, feat),
        ],
      ),
    );
  }

  // 1. EEG Tab
  Widget _buildEegTab(List<double> rawWave, SensorDataPoint data, ExtractedFeatures feat) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGraphContainer(
            title: "Raw EEG Signal (µV)",
            subtitle: "Electrode montage: Fp1-Fp2 differential • Sample Rate: 200 Hz",
            waveformData: rawWave,
            color: AppTheme.eegPurple,
            currentVal: "${data.eeg.toStringAsFixed(1)} µV",
          ),
          const SizedBox(height: 16),
          const Text(
            "EEG FREQUENCY BAND SPECTRUM",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 1.0),
          ),
          const SizedBox(height: 10),
          _buildBandBar("Delta (0.5 – 4 Hz)", feat.delta, "Deep sleep, unconscious repair", const Color(0xFF6366F1)),
          _buildBandBar("Theta (4 – 8 Hz)", feat.theta, "Drowsiness, meditation, memory consolidation", const Color(0xFF8B5CF6)),
          _buildBandBar("Alpha (8 – 13 Hz)", feat.alpha, "Relaxed alertness, cognitive readiness", const Color(0xFF3B82F6)),
          _buildBandBar("Beta (13 – 30 Hz)", feat.beta, "Active focus, problem solving", const Color(0xFF10B981)),
          _buildBandBar("Gamma (> 30 Hz)", feat.gamma, "High-level multimodal cross-binding", const Color(0xFFF59E0B)),
        ],
      ),
    );
  }

  // 2. EMG Tab
  Widget _buildEmgTab(List<double> rawWave, SensorDataPoint data, ExtractedFeatures feat) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGraphContainer(
            title: "Raw EMG Envelope (mV)",
            subtitle: "Bipolar surface electrodes • Forearm flexor bundle",
            waveformData: rawWave,
            color: AppTheme.emgGreen,
            currentVal: "${data.emg.toStringAsFixed(2)} mV",
          ),
          const SizedBox(height: 16),
          _buildFeatureGrid([
            {'RMS Amplitude': '${feat.emgRms.toStringAsFixed(2)} mV'},
            {'Mean Absolute Val': '${feat.emgMav.toStringAsFixed(2)} mV'},
            {'Mean Frequency': '${feat.emgMeanFreq.toStringAsFixed(1)} Hz'},
            {'Median Frequency': '${feat.emgMedianFreq.toStringAsFixed(1)} Hz'},
            {'Fatigue Index': '${(feat.emgFatigueIndex * 100).toStringAsFixed(0)}%'},
            {'Motor Recruitment': feat.emgRms > 1.5 ? 'Active High' : 'Basal Tonus'},
          ]),
        ],
      ),
    );
  }

  // 3. GSR Tab
  Widget _buildGsrTab(List<double> rawWave, SensorDataPoint data, ExtractedFeatures feat) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGraphContainer(
            title: "Skin Conductance Waveform (µS)",
            subtitle: "Ag/AgCl palmar electrodes • Sympathetic electrodermal level",
            waveformData: rawWave,
            color: AppTheme.gsrOrange,
            currentVal: "${data.gsr.toStringAsFixed(2)} µS",
          ),
          const SizedBox(height: 16),
          _buildFeatureGrid([
            {'Tonic Level (SCL)': '${feat.gsrScl.toStringAsFixed(2)} µS'},
            {'Phasic SCR Amplitude': '${feat.gsrScr.toStringAsFixed(2)} µS'},
            {'Mean Peak Amplitude': '${feat.gsrResponseAmp.toStringAsFixed(2)} µS'},
            {'Phasic Burst Events': '${feat.gsrResponseCount} / min'},
            {'Recovery Half-Time': '${feat.gsrRecoveryTime.toStringAsFixed(1)} s'},
            {'Sympathetic Tone': feat.gsrScl > 10 ? 'Elevated' : 'Homeostatic'},
          ]),
        ],
      ),
    );
  }

  // 4. MAX30102 Tab
  Widget _buildMaxTab(List<double> rawWave, SensorDataPoint data, ExtractedFeatures feat) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGraphContainer(
            title: "Photoplethysmography (PPG)",
            subtitle: "Infrared / Red optical reflection • Pulsatile arterial waveform",
            waveformData: rawWave,
            color: AppTheme.maxRed,
            currentVal: "${data.heartRate.toStringAsFixed(0)} bpm",
          ),
          const SizedBox(height: 16),
          _buildFeatureGrid([
            {'Heart Rate': '${feat.hr.toStringAsFixed(0)} bpm'},
            {'HRV (RMSSD)': '${feat.hrvRmssd.toStringAsFixed(1)} ms'},
            {'SpO2 Blood Oxygen': '${feat.spo2.toStringAsFixed(1)} %'},
            {'Pulse Amplitude': '${feat.ppgAmplitude.toStringAsFixed(1)} a.u.'},
            {'Perfusion Quality': 'Optimal (98%)'},
            {'Dicrotic Notch': 'Clearly Defined'},
          ]),
        ],
      ),
    );
  }

  // 5. FSR Tab
  Widget _buildFsrTab(List<double> rawWave, SensorDataPoint data, ExtractedFeatures feat) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGraphContainer(
            title: "Force & Pressure Transduction (N)",
            subtitle: "Piezoresistive polymer tactile sensor array",
            waveformData: rawWave,
            color: AppTheme.fsrAmber,
            currentVal: "${data.fsr.toStringAsFixed(1)} N",
          ),
          const SizedBox(height: 16),
          _buildFeatureGrid([
            {'Piezoresistance': '${feat.fsrPressure.toStringAsFixed(1)} Ω'},
            {'Measured Force': '${feat.fsrForce.toStringAsFixed(2)} N'},
            {'Biomechanical State': feat.movementStatus},
            {'Contact Duration': '${feat.contactDuration.toStringAsFixed(0)} s'},
          ]),
        ],
      ),
    );
  }

  // 6. DHT11 Tab
  Widget _buildDhtTab(List<double> rawWave, SensorDataPoint data, ExtractedFeatures feat) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGraphContainer(
            title: "Ambient Microclimate Temperature (°C)",
            subtitle: "Environmental capacitive humidity & thermistor sensor",
            waveformData: rawWave,
            color: AppTheme.dhtBlue,
            currentVal: "${data.temperature.toStringAsFixed(1)} °C",
          ),
          const SizedBox(height: 16),
          _buildFeatureGrid([
            {'Temperature': '${feat.temperature.toStringAsFixed(1)} °C'},
            {'Relative Humidity': '${feat.humidity.toStringAsFixed(0)} %'},
            {'Dew Point Estimate': '16.4 °C'},
            {'Sensor Drift State': 'Calibrated (Zero Drift)'},
          ]),
        ],
      ),
    );
  }

  Widget _buildGraphContainer({
    required String title,
    required String subtitle,
    required List<double> waveformData,
    required Color color,
    required String currentVal,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                  ),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
              Text(
                currentVal,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 140,
              width: double.infinity,
              color: color.withValues(alpha: 0.04),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: LiveWaveformWidget(
                values: waveformData,
                color: color,
                height: 124,
                strokeWidth: 2.2,
                showFill: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBandBar(String title, double percentage, String description, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
              Text("${percentage.toStringAsFixed(1)}%", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (percentage / 100.0).clamp(0.0, 1.0),
              backgroundColor: AppTheme.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid(List<Map<String, String>> metrics) {
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
          const Text(
            "EXTRACTED PHYSIOLOGICAL PARAMETERS",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 1.0),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: metrics.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.2,
            ),
            itemBuilder: (context, idx) {
              final item = metrics[idx];
              final key = item.keys.first;
              final val = item.values.first;

              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(key, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    const SizedBox(height: 2),
                    Text(
                      val,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
