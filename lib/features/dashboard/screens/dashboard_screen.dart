import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/state/triax_app_state.dart';
import '../../sensors/services/hardware_service.dart';
import '../../sensors/widgets/sensor_dashboard_card.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int sensorIndex) onSelectSensor;
  final VoidCallback onOpenConnection;

  const DashboardScreen({
    super.key,
    required this.onSelectSensor,
    required this.onOpenConnection,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<TriaxAppState>(context);
    final data = appState.currentData;
    final buffer = appState.signalBuffer;

    final eegWave = buffer.map((p) => p.eeg).toList();
    final emgWave = buffer.map((p) => p.emg).toList();
    final gsrWave = buffer.map((p) => p.gsr).toList();
    final ppgWave = buffer.map((p) => p.ppg).toList();
    final fsrWave = buffer.map((p) => p.fsr).toList();
    final tempWave = buffer.map((p) => p.temperature).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("TRIAX Physiological Monitor"),
        actions: [
          // Live Recording Toggle
          IconButton(
            icon: Icon(
              appState.isRecording ? Icons.fiber_manual_record : Icons.fiber_manual_record_outlined,
              color: appState.isRecording ? AppTheme.statusWarning : AppTheme.textMuted,
            ),
            tooltip: appState.isRecording ? "Stop Recording" : "Record Session",
            onPressed: () {
              if (appState.isRecording) {
                appState.stopRecording();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Session recorded & saved to History.")),
                );
              } else {
                appState.startRecording();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Live multimodal session recording started.")),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.hub_outlined),
            onPressed: onOpenConnection,
            tooltip: "Hardware Settings",
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Hardware Status Bar
              _buildTopStatusBar(context, appState),
              const SizedBox(height: 16),

              // Multimodal Sensor Cards Grid (6 Sensors)
              const Text(
                "ACTIVE SENSOR MODALITIES",
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),

              // 1. EEG Card
              SensorDashboardCard(
                title: "EEG (Electroencephalogram)",
                metricValue: data.eeg.toStringAsFixed(1),
                unit: "µV",
                secondaryInfo: "Frontal Cortical Montage",
                icon: Icons.psychology_outlined,
                themeColor: AppTheme.eegPurple,
                waveformData: eegWave,
                signalQuality: appState.getSignalQuality('EEG'),
                onTap: () => onSelectSensor(0),
              ),
              const SizedBox(height: 12),

              // 2. EMG Card
              SensorDashboardCard(
                title: "EMG (Electromyogram)",
                metricValue: data.emg.toStringAsFixed(2),
                unit: "mV",
                secondaryInfo: "Brachioradialis Muscle Activation",
                icon: Icons.fitness_center_rounded,
                themeColor: AppTheme.emgGreen,
                waveformData: emgWave,
                signalQuality: appState.getSignalQuality('EMG'),
                onTap: () => onSelectSensor(1),
              ),
              const SizedBox(height: 12),

              // 3. GSR Card
              SensorDashboardCard(
                title: "GSR (Galvanic Skin Response)",
                metricValue: data.gsr.toStringAsFixed(2),
                unit: "µS",
                secondaryInfo: "Electrodermal Tonic + Phasic",
                icon: Icons.water_drop_outlined,
                themeColor: AppTheme.gsrOrange,
                waveformData: gsrWave,
                signalQuality: appState.getSignalQuality('GSR'),
                onTap: () => onSelectSensor(2),
              ),
              const SizedBox(height: 12),

              // 4. MAX30102 Card
              SensorDashboardCard(
                title: "MAX30102 (Cardiovascular)",
                metricValue: "${data.heartRate.toStringAsFixed(0)} bpm  |  ${data.spo2.toStringAsFixed(1)}%",
                unit: "HR & SpO2",
                secondaryInfo: "Photoplethysmogram (PPG)",
                icon: Icons.favorite_border_rounded,
                themeColor: AppTheme.maxRed,
                waveformData: ppgWave,
                signalQuality: appState.getSignalQuality('MAX30102'),
                onTap: () => onSelectSensor(3),
              ),
              const SizedBox(height: 12),

              // 5. FSR Card
              SensorDashboardCard(
                title: "FSR (Force Sensitive Resistor)",
                metricValue: data.fsr.toStringAsFixed(1),
                unit: "N",
                secondaryInfo: "Biomechanical Isometric Force",
                icon: Icons.touch_app_outlined,
                themeColor: AppTheme.fsrAmber,
                waveformData: fsrWave,
                signalQuality: appState.getSignalQuality('FSR'),
                onTap: () => onSelectSensor(4),
              ),
              const SizedBox(height: 12),

              // 6. DHT11 Card
              SensorDashboardCard(
                title: "DHT11 (Ambient Environment)",
                metricValue: "${data.temperature.toStringAsFixed(1)}°C  |  ${data.humidity.toStringAsFixed(0)}%",
                unit: "Temp & RH",
                secondaryInfo: "Microclimate Ambient Readings",
                icon: Icons.thermostat_outlined,
                themeColor: AppTheme.dhtBlue,
                waveformData: tempWave,
                signalQuality: appState.getSignalQuality('DHT11'),
                onTap: () => onSelectSensor(5),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopStatusBar(BuildContext context, TriaxAppState state) {
    final isConnected = state.connectionStatus == HardwareConnectionStatus.connected;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isConnected ? AppTheme.statusNormal : AppTheme.statusWarning,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isConnected ? AppTheme.statusNormal : AppTheme.statusWarning).withValues(alpha: 0.4),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected 
                      ? "● TRIAX Hardware Connected"
                      : "○ TRIAX Hardware Disconnected",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                Text(
                  state.isDemoMode ? "Live Synthesizer Stream (20 Hz)" : "ESP32 Hardware Stream",
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          if (state.isRecording)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.statusWarning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.circle, size: 8, color: AppTheme.statusWarning),
                  SizedBox(width: 4),
                  Text(
                    "REC",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.statusWarning,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
