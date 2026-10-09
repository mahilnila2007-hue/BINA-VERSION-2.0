import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../triax_structure/widgets/triax_structure_painter.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;

  const SplashScreen({
    super.key,
    required this.onGetStarted,
    required this.onSignIn,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  double _rotY = 0.0;
  double _rotX = 0.2;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..addListener(() {
        setState(() {
          _rotY = _animController.value * 2 * 3.14159;
          _rotX = 0.2 + (0.1 * (1.0 - (_animController.value * 2 - 1.0).abs()));
        });
      })
      ..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Title Section
              const Text(
                "TRIAX",
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryNavy,
                  letterSpacing: 4.0,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "MULTI-MODAL\nPHYSIOLOGICAL ANALYSIS",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryBlue,
                  letterSpacing: 2.0,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "\"Understand Your Signals\"",
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const Spacer(flex: 1),

              // Prominent 3D TRIAX Structure Showcase
              SizedBox(
                height: 280,
                width: double.infinity,
                child: CustomPaint(
                  painter: TriaxStructurePainter(
                    rotX: _rotX,
                    rotY: _rotY,
                    rotZ: 0.0,
                    scale: 1.15,
                    nodeActivities: const {},
                    selectedNodeId: 'CENTRAL_FUSION',
                    pulsePhase: _animController.value,
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: widget.onGetStarted,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryNavy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Get Started",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: widget.onSignIn,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    "Sign In",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.primaryNavy),
                  ),
                ),
              ),

              const SizedBox(height: 18),
              const Text(
                "TRIAX Research Prototype • v2.0",
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
