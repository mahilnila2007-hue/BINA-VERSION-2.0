import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/state/triax_app_state.dart';
import '../../sensors/services/hardware_service.dart';

class DeviceConnectionScreen extends StatefulWidget {
  final VoidCallback onConnectedProceed;

  const DeviceConnectionScreen({super.key, required this.onConnectedProceed});

  @override
  State<DeviceConnectionScreen> createState() => _DeviceConnectionScreenState();
}

class _DeviceConnectionScreenState extends State<DeviceConnectionScreen> {
  ConnectionType _selectedType = ConnectionType.ble;
  List<DiscoveredDevice> _discoveredDevices = [];
  bool _isScanning = false;
  String? _connectingDeviceId;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  void _startScan() async {
    final state = Provider.of<TriaxAppState>(context, listen: false);
    setState(() {
      _isScanning = true;
      _discoveredDevices = [];
    });

    final devices = await state.hardwareService.scanDevices(type: _selectedType);
    if (mounted) {
      setState(() {
        _isScanning = false;
        _discoveredDevices = devices;
      });
    }
  }

  void _connectDevice(DiscoveredDevice device) async {
    final state = Provider.of<TriaxAppState>(context, listen: false);
    setState(() {
      _connectingDeviceId = device.deviceId;
    });

    final success = await state.hardwareService.connect(device.deviceId, type: device.type);
    if (mounted) {
      setState(() {
        _connectingDeviceId = null;
      });
      if (success) {
        widget.onConnectedProceed();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<TriaxAppState>(context);
    final status = appState.connectionStatus;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Hardware Connection"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isScanning ? null : _startScan,
            tooltip: "Rescan",
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryNavy, Color(0xFF1E3A8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Connect TRIAX Hardware",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            appState.isDemoMode ? "DEMO SENSORS" : "HARDWARE",
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Link multimodal ESP32 embedded node via Low-Energy Bluetooth or Lab Wi-Fi socket.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFFCBD5E1),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Connection Type Switcher
              const Text(
                "COMMUNICATION INTERFACE",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildTypeOption(
                      type: ConnectionType.ble,
                      title: "Bluetooth / BLE",
                      icon: Icons.bluetooth_rounded,
                      active: _selectedType == ConnectionType.ble,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTypeOption(
                      type: ConnectionType.wifi,
                      title: "Wi-Fi (Socket)",
                      icon: Icons.wifi_rounded,
                      active: _selectedType == ConnectionType.wifi,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Discovered Hardware Nodes Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "DISCOVERED NODES",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                  if (_isScanning)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (_discoveredDevices.isEmpty && !_isScanning)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const Icon(Icons.bluetooth_searching_rounded, size: 36, color: AppTheme.textMuted),
                      const SizedBox(height: 10),
                      const Text(
                        "No TRIAX ESP32 nodes found",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Ensure ESP32 node power is on and broadcasting.",
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: _startScan,
                        child: const Text("Scan Again"),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _discoveredDevices.length,
                  itemBuilder: (context, index) {
                    final device = _discoveredDevices[index];
                    final isConnecting = (_connectingDeviceId == device.deviceId);
                    final isConnected = (status == HardwareConnectionStatus.connected);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isConnected ? AppTheme.primaryBlue : AppTheme.borderLight,
                          width: isConnected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryNavy.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.memory_rounded, color: AppTheme.primaryNavy, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  device.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.signal_cellular_alt_rounded, size: 13, color: AppTheme.textMuted),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${device.rssi} dBm",
                                      style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.battery_5_bar_rounded, size: 14, color: AppTheme.statusNormal),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${device.batteryLevel}%",
                                      style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (isConnecting)
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            )
                          else if (isConnected)
                            OutlinedButton(
                              onPressed: () => appState.hardwareService.disconnect(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.statusWarning,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              child: const Text("Disconnect", style: TextStyle(fontSize: 12)),
                            )
                          else
                            ElevatedButton(
                              onPressed: () => _connectDevice(device),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              child: const Text("Connect", style: TextStyle(fontSize: 13)),
                            ),
                        ],
                      ),
                    );
                  },
                ),

              const SizedBox(height: 20),

              // Demo Mode Switcher Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Autonomous Demo Mode",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            "Synthesizes biological waveforms for development testing without physical ESP32.",
                            style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: appState.isDemoMode,
                      activeThumbColor: AppTheme.primaryBlue,
                      onChanged: (val) {
                        appState.toggleDemoMode(val);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Bottom Proceed Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: widget.onConnectedProceed,
                  child: const Text("Proceed to Dashboard", style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeOption({
    required ConnectionType type,
    required String title,
    required IconData icon,
    required bool active,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
        _startScan();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: active ? AppTheme.primaryBlue.withValues(alpha: 0.08) : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? AppTheme.primaryBlue : AppTheme.borderLight,
            width: active ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: active ? AppTheme.primaryBlue : AppTheme.textMuted),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? AppTheme.primaryBlue : AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
