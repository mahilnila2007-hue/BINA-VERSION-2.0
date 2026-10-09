import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/state/triax_app_state.dart';
import '../../../services/huggingface_ai_service.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback onOpenConnection;

  const SettingsScreen({super.key, required this.onOpenConnection});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<TriaxAppState>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Settings & Lab Config"),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Hardware & Peripheral Links
            _buildSectionHeader("HARDWARE & DATA PIPELINE"),
            _buildSettingCard(
              title: "Hardware Connection",
              subtitle: "Manage ESP32 BLE / Wi-Fi peripheral links",
              icon: Icons.bluetooth_searching_rounded,
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
              onTap: onOpenConnection,
            ),
            const SizedBox(height: 20),

            // Sampling & Calibration
            _buildSectionHeader("SAMPLING & CALIBRATION"),
            _buildSettingCard(
              title: "Sampling Frequency",
              subtitle: "200 Hz (EEG/EMG) • 50 Hz (PPG/GSR/FSR)",
              icon: Icons.speed_rounded,
              trailing: const Text("Optimal", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue)),
              onTap: () {},
            ),
            _buildSettingCard(
              title: "Electrode Impedance Check",
              subtitle: "Verify Ag/AgCl skin contact resistance (<5 kΩ)",
              icon: Icons.check_circle_outline_rounded,
              trailing: const Text("Pass", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.statusNormal)),
              onTap: () {},
            ),
            const SizedBox(height: 20),

            // AI & ML Inference
            _buildSectionHeader("MACHINE LEARNING ENGINE"),
            _buildSettingCard(
              title: "Inference Backend",
              subtitle: "Qwen2.5-7B-Instruct (HF Router)",
              icon: Icons.psychology_outlined,
              trailing: const Text("Router v1", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryNavy)),
              onTap: () {},
            ),
            _buildSettingCard(
              title: "Hugging Face Token (HF_TOKEN)",
              subtitle: HuggingFaceAIService.hasToken ? "● Configured & Active" : "Set API token for real Qwen model",
              icon: Icons.key_rounded,
              trailing: Icon(
                HuggingFaceAIService.hasToken ? Icons.check_circle_rounded : Icons.edit_note_rounded,
                size: 18,
                color: HuggingFaceAIService.hasToken ? AppTheme.statusNormal : AppTheme.primaryBlue,
              ),
              onTap: () => _showTokenDialog(context),
            ),
            const SizedBox(height: 20),

            // About TRIAX
            _buildSectionHeader("RESEARCH PROTOTYPE INFO"),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "TRIAX v2.0 Research Platform",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "TRIAX is an advanced multimodal physiological signal monitoring and feature-fusion architecture developed for research screening.",
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.4),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Safety Notice:\nTRIAX is a research prototype and is not intended for medical diagnosis.",
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB45309),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Mode Selection (Placed last as requested)
            _buildSectionHeader("OPERATING MODE CONFIGURATION"),
            _buildModeSelectorCard(
              isDemoMode: appState.isDemoMode,
              onToggle: (enableDemo) => appState.toggleDemoMode(enableDemo),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted, letterSpacing: 1.0),
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppTheme.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderLight),
        ),
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryNavy.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryNavy, size: 20),
          ),
          title: Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted)),
          trailing: trailing,
        ),
      ),
    );
  }

  Widget _buildModeSelectorCard({
    required bool isDemoMode,
    required ValueChanged<bool> onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDemoMode ? AppTheme.primaryBlue : AppTheme.borderLight,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDemoMode 
                        ? AppTheme.primaryBlue.withValues(alpha: 0.12)
                        : AppTheme.primaryNavy.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isDemoMode ? Icons.auto_graph_rounded : Icons.sensors_off_rounded,
                    color: isDemoMode ? AppTheme.primaryBlue : AppTheme.primaryNavy,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDemoMode ? "Demo Mode (Synthesized)" : "Real Mode (Hardware Baseline)",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isDemoMode
                            ? "Generates dynamic human physiological waveforms"
                            : "Baseline state: All metrics 0, flatline straight graphs",
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isDemoMode,
                  activeThumbColor: AppTheme.primaryBlue,
                  onChanged: onToggle,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => onToggle(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !isDemoMode
                            ? AppTheme.primaryNavy.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: !isDemoMode ? AppTheme.primaryNavy : AppTheme.borderLight,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.show_chart,
                            size: 16,
                            color: !isDemoMode ? AppTheme.primaryNavy : AppTheme.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Real Mode (Default)",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: !isDemoMode ? FontWeight.w700 : FontWeight.w500,
                              color: !isDemoMode ? AppTheme.primaryNavy : AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onToggle(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isDemoMode
                            ? AppTheme.primaryBlue.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDemoMode ? AppTheme.primaryBlue : AppTheme.borderLight,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_search_rounded,
                            size: 16,
                            color: isDemoMode ? AppTheme.primaryBlue : AppTheme.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Demo Mode",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isDemoMode ? FontWeight.w700 : FontWeight.w500,
                              color: isDemoMode ? AppTheme.primaryBlue : AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTokenDialog(BuildContext context) {
    final controller = TextEditingController(text: HuggingFaceAIService.apiToken);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.key_rounded, color: AppTheme.primaryNavy, size: 20),
            SizedBox(width: 8),
            Text("Hugging Face API Token"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter your Hugging Face User Access Token (read permission) to connect TRIAX directly to real Qwen2.5-7B-Instruct via the Hugging Face Inference Router:",
              style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: "hf_xxxxxxxxxxxxxxxxxxxxxxxxx",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              HuggingFaceAIService.setApiToken(controller.text);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Hugging Face Token saved successfully.")),
              );
            },
            child: const Text("Save Token"),
          ),
        ],
      ),
    );
  }
}
