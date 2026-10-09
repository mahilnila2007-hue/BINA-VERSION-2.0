import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/state/triax_app_state.dart';
import 'features/splash/screens/splash_screen.dart';
import 'features/device/screens/device_connection_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/triax_structure/screens/triax_structure_screen.dart';
import 'features/analysis/screens/signal_analysis_screen.dart';
import 'features/ai/screens/ai_analysis_screen.dart';
import 'features/assistant/screens/assistant_chat_screen.dart';
import 'features/history/screens/history_screen.dart';
import 'features/settings/screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => TriaxAppState(),
      child: const TriaxApp(),
    ),
  );
}

class TriaxApp extends StatelessWidget {
  const TriaxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TRIAX Physiological Monitor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainNavigationHost(),
    );
  }
}

class MainNavigationHost extends StatefulWidget {
  const MainNavigationHost({super.key});

  @override
  State<MainNavigationHost> createState() => _MainNavigationHostState();
}

class _MainNavigationHostState extends State<MainNavigationHost> {
  bool _hasPassedSplash = false;
  int _currentIndex = 0;
  int _selectedSignalAnalysisTab = 0;

  void _onGetStarted() {
    setState(() {
      _hasPassedSplash = true;
    });
  }

  void _navigateToConnection() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DeviceConnectionScreen(
          onConnectedProceed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _navigateToSignalAnalysis(int sensorIndex) {
    setState(() {
      _selectedSignalAnalysisTab = sensorIndex;
      _currentIndex = 2; // Index of Analysis in bottom nav
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPassedSplash) {
      return SplashScreen(
        onGetStarted: _onGetStarted,
        onSignIn: _onGetStarted,
      );
    }

    final screens = [
      DashboardScreen(
        onSelectSensor: _navigateToSignalAnalysis,
        onOpenConnection: _navigateToConnection,
      ),
      const TriaxStructureScreen(),
      SignalAnalysisScreen(initialSensorIndex: _selectedSignalAnalysisTab),
      const AIAnalysisScreen(),
      const AssistantChatScreen(),
      const HistoryScreen(),
      SettingsScreen(onOpenConnection: _navigateToConnection),
    ];

    // Bottom Navigation: HOME | TRIAX | ANALYSIS | SCREENING | TRIAX AI | HISTORY | SETTINGS
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppTheme.borderLight, width: 1.0),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard_rounded, "HOME"),
                _buildNavItem(1, Icons.hub_outlined, Icons.hub_rounded, "TRIAX"),
                _buildNavItem(2, Icons.show_chart_rounded, Icons.insights_rounded, "ANALYSIS"),
                _buildNavItem(3, Icons.psychology_outlined, Icons.psychology_rounded, "MODELS"),
                _buildNavItem(4, Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, "TRIAX AI"),
                _buildNavItem(5, Icons.history_rounded, Icons.history_rounded, "HISTORY"),
                _buildNavItem(6, Icons.tune_rounded, Icons.tune_rounded, "SETTINGS"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData unselectedIcon, IconData selectedIcon, String label) {
    final isSelected = (_currentIndex == index);
    return InkWell(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              size: 22,
              color: isSelected ? AppTheme.primaryNavy : AppTheme.textMuted,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppTheme.primaryNavy : AppTheme.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
