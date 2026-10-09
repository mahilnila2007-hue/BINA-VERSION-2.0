import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v64;
import '../../../core/theme/app_theme.dart';

class TriaxNode3D {
  final String id;
  final String label;
  final String sensorModality;
  final v64.Vector3 position;
  final double radius;
  final Color color;
  final bool isCentral;
  final bool isMajor;
  final List<String> features;

  TriaxNode3D({
    required this.id,
    required this.label,
    required this.sensorModality,
    required this.position,
    required this.radius,
    required this.color,
    this.isCentral = false,
    this.isMajor = true,
    required this.features,
  });
}

class TriaxEdge3D {
  final int startIndex;
  final int endIndex;
  final bool isMajorTriangular;
  final Color? customColor;

  TriaxEdge3D({
    required this.startIndex,
    required this.endIndex,
    this.isMajorTriangular = true,
    this.customColor,
  });
}

class TriaxStructurePainter extends CustomPainter {
  final double rotX;
  final double rotY;
  final double rotZ;
  final double scale;
  final Map<String, double> nodeActivities;
  final String? selectedNodeId;
  final double pulsePhase;

  late final List<TriaxNode3D> nodes;
  late final List<TriaxEdge3D> edges;

  TriaxStructurePainter({
    required this.rotX,
    required this.rotY,
    required this.rotZ,
    required this.scale,
    required this.nodeActivities,
    required this.selectedNodeId,
    required this.pulsePhase,
  }) {
    _initGeometry();
  }

  void _initGeometry() {
    // Exact TRIAX Multimodal Geometry:
    // Central Multimodal Fusion Node (0, 0, 0)
    // 4 Outer Major Spherical Nodes forming a symmetrical 3D diamond/octahedral diamond frame
    // 6 Intermediate relational feature nodes interconnected with triangular & horizontal struts

    nodes = [
      // Index 0: Central Spherical Node (Multimodal Feature Fusion)
      TriaxNode3D(
        id: 'CENTRAL_FUSION',
        label: 'Multimodal Fusion',
        sensorModality: 'CENTRAL CORE',
        position: v64.Vector3(0, 0, 0),
        radius: 20.0,
        color: AppTheme.primaryBlue,
        isCentral: true,
        features: ['Multimodal Cross-Attention', 'Latent Fusion Vector', 'Global Homeostasis'],
      ),

      // Outer Major Nodes (4 Major Outer Spheres)
      // Index 1: Top Apex (EEG)
      TriaxNode3D(
        id: 'NODE_EEG',
        label: 'EEG Cortical',
        sensorModality: 'EEG',
        position: v64.Vector3(0, -95, 0),
        radius: 15.0,
        color: AppTheme.eegPurple,
        features: ['Delta', 'Theta', 'Alpha', 'Beta', 'Gamma'],
      ),
      // Index 2: Bottom Base (DHT11 Ambient)
      TriaxNode3D(
        id: 'NODE_DHT',
        label: 'DHT11 Ambient',
        sensorModality: 'DHT11',
        position: v64.Vector3(0, 95, 0),
        radius: 14.0,
        color: AppTheme.dhtBlue,
        features: ['Temperature', 'Humidity', 'Thermal Comfort Index'],
      ),
      // Index 3: Left Major Node (EMG)
      TriaxNode3D(
        id: 'NODE_EMG',
        label: 'EMG Myoelectric',
        sensorModality: 'EMG',
        position: v64.Vector3(-90, 0, -20),
        radius: 15.0,
        color: AppTheme.emgGreen,
        features: ['RMS', 'MAV', 'Mean Freq', 'Median Freq', 'Fatigue'],
      ),
      // Index 4: Right Major Node (MAX30102 Cardiovascular)
      TriaxNode3D(
        id: 'NODE_MAX',
        label: 'MAX30102 Pulse',
        sensorModality: 'MAX30102',
        position: v64.Vector3(90, 0, -20),
        radius: 15.0,
        color: AppTheme.maxRed,
        features: ['HR', 'HRV RMSSD', 'SpO2', 'PPG Amplitude'],
      ),

      // Smaller Intermediate Nodes & Secondary Modalities (GSR, FSR & Relational Struts)
      // Index 5: Front Upper Intermediate (GSR)
      TriaxNode3D(
        id: 'NODE_GSR',
        label: 'GSR Electrodermal',
        sensorModality: 'GSR',
        position: v64.Vector3(0, -45, 55),
        radius: 12.0,
        color: AppTheme.gsrOrange,
        isMajor: false,
        features: ['SCL (Tonic)', 'SCR (Phasic)', 'Response Amplitude', 'Recovery Time'],
      ),
      // Index 6: Front Lower Intermediate (FSR Pressure)
      TriaxNode3D(
        id: 'NODE_FSR',
        label: 'FSR Pressure',
        sensorModality: 'FSR',
        position: v64.Vector3(0, 45, 55),
        radius: 12.0,
        color: AppTheme.fsrAmber,
        isMajor: false,
        features: ['Pressure', 'Force (N)', 'Movement Status', 'Contact Duration'],
      ),
      // Index 7: Left-Top Strut Node
      TriaxNode3D(
        id: 'NODE_REL_1',
        label: 'EEG-EMG Relational',
        sensorModality: 'Corticomuscular',
        position: v64.Vector3(-45, -48, -10),
        radius: 8.0,
        color: const Color(0xFF6366F1),
        isMajor: false,
        features: ['Motor Coherence', 'Phase Lag'],
      ),
      // Index 8: Right-Top Strut Node
      TriaxNode3D(
        id: 'NODE_REL_2',
        label: 'EEG-PPG Relational',
        sensorModality: 'Neurocardiac',
        position: v64.Vector3(45, -48, -10),
        radius: 8.0,
        color: const Color(0xFFA855F7),
        isMajor: false,
        features: ['Baroreflex Coupling', 'Vagal Index'],
      ),
      // Index 9: Left-Bottom Strut Node
      TriaxNode3D(
        id: 'NODE_REL_3',
        label: 'EMG-FSR Relational',
        sensorModality: 'Neuromechanical',
        position: v64.Vector3(-45, 48, -10),
        radius: 8.0,
        color: const Color(0xFF059669),
        isMajor: false,
        features: ['Strain Factor', 'Force Sync'],
      ),
      // Index 10: Right-Bottom Strut Node
      TriaxNode3D(
        id: 'NODE_REL_4',
        label: 'DHT-PPG Relational',
        sensorModality: 'Thermoregulatory',
        position: v64.Vector3(45, 48, -10),
        radius: 8.0,
        color: const Color(0xFF0EA5E9),
        isMajor: false,
        features: ['Vasomotor Tone', 'Perfusion Index'],
      ),
    ];

    // Connect nodes into the symmetrical TRIAX triangulated network
    edges = [
      // Central Node Connections to Major Vertices
      TriaxEdge3D(startIndex: 0, endIndex: 1),
      TriaxEdge3D(startIndex: 0, endIndex: 2),
      TriaxEdge3D(startIndex: 0, endIndex: 3),
      TriaxEdge3D(startIndex: 0, endIndex: 4),
      TriaxEdge3D(startIndex: 0, endIndex: 5),
      TriaxEdge3D(startIndex: 0, endIndex: 6),

      // Triangular Outer Facets
      // Top Diamond Struts
      TriaxEdge3D(startIndex: 1, endIndex: 7),
      TriaxEdge3D(startIndex: 7, endIndex: 3),
      TriaxEdge3D(startIndex: 1, endIndex: 8),
      TriaxEdge3D(startIndex: 8, endIndex: 4),
      
      // Bottom Diamond Struts
      TriaxEdge3D(startIndex: 3, endIndex: 9),
      TriaxEdge3D(startIndex: 9, endIndex: 2),
      TriaxEdge3D(startIndex: 4, endIndex: 10),
      TriaxEdge3D(startIndex: 10, endIndex: 2),

      // Front Intermediate Triangular Connections (GSR & FSR to Diamond Outer Edges)
      TriaxEdge3D(startIndex: 1, endIndex: 5),
      TriaxEdge3D(startIndex: 5, endIndex: 3),
      TriaxEdge3D(startIndex: 5, endIndex: 4),
      TriaxEdge3D(startIndex: 2, endIndex: 6),
      TriaxEdge3D(startIndex: 6, endIndex: 3),
      TriaxEdge3D(startIndex: 6, endIndex: 4),
      TriaxEdge3D(startIndex: 5, endIndex: 6, isMajorTriangular: false),

      // Horizontal Equator Strut
      TriaxEdge3D(startIndex: 3, endIndex: 4, isMajorTriangular: false),
    ];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Transformation Matrix
    final matrix = v64.Matrix4.identity()
      ..rotateX(rotX)
      ..rotateY(rotY)
      ..rotateZ(rotZ);

    // Transform all 3D points to 2D screen space with perspective projection
    final transformedNodes = <_RenderNode>[];
    const cameraDistance = 380.0;

    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final transformed = matrix.transformed3(node.position);
      
      final z = transformed.z;
      // Perspective division
      final fov = cameraDistance / (cameraDistance - z);
      final screenX = center.dx + transformed.x * fov * scale;
      final screenY = center.dy + transformed.y * fov * scale;
      final projRadius = node.radius * fov * scale;

      transformedNodes.add(_RenderNode(
        index: i,
        node: node,
        screenPos: Offset(screenX, screenY),
        radius: projRadius,
        depthZ: z,
      ));
    }

    // Depth Sorting (Back-to-Front Painter's Algorithm for authentic 3D depth)
    final sortedEdges = [...edges];
    sortedEdges.sort((a, b) {
      final depthA = (transformedNodes[a.startIndex].depthZ + transformedNodes[a.endIndex].depthZ) / 2;
      final depthB = (transformedNodes[b.startIndex].depthZ + transformedNodes[b.endIndex].depthZ) / 2;
      return depthA.compareTo(depthB);
    });

    final sortedNodes = [...transformedNodes];
    sortedNodes.sort((a, b) => a.depthZ.compareTo(b.depthZ));

    // 1. Draw 3D Connecting Struts & Geometric Triangles
    for (final edge in sortedEdges) {
      final p1 = transformedNodes[edge.startIndex];
      final p2 = transformedNodes[edge.endIndex];
      final avgZ = (p1.depthZ + p2.depthZ) / 2;
      
      // Calculate depth fading and lighting
      final depthFactor = ((avgZ + 120) / 240).clamp(0.2, 1.0);
      final isConnectedToCentral = (edge.startIndex == 0 || edge.endIndex == 0);

      final linePaint = Paint()
        ..strokeWidth = isConnectedToCentral ? (2.2 * scale) : (1.4 * scale)
        ..style = PaintingStyle.stroke;

      if (isConnectedToCentral) {
        // Gradient shader connecting core to modality
        final c1 = p1.node.color.withValues(alpha: 0.4 * depthFactor + 0.3);
        final c2 = p2.node.color.withValues(alpha: 0.4 * depthFactor + 0.3);
        linePaint.shader = LinearGradient(
          colors: [c1, c2],
        ).createShader(Rect.fromPoints(p1.screenPos, p2.screenPos));
      } else {
        linePaint.color = (edge.customColor ?? AppTheme.primaryNavy).withValues(
          alpha: edge.isMajorTriangular ? (0.25 * depthFactor + 0.15) : (0.15 * depthFactor + 0.08),
        );
      }

      canvas.drawLine(p1.screenPos, p2.screenPos, linePaint);

      // Subtle pulse particle traveling down struts
      final pulsePos = (pulsePhase + (edge.startIndex * 0.2)) % 1.0;
      final particlePos = Offset.lerp(p1.screenPos, p2.screenPos, pulsePos)!;
      final particlePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.7 * depthFactor)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(particlePos, 1.8 * scale, particlePaint);
    }

    // 2. Draw Spherical 3D Nodes with Radial Shading & Glow
    for (final rNode in sortedNodes) {
      final node = rNode.node;
      final pos = rNode.screenPos;
      final r = rNode.radius;
      final isSelected = (selectedNodeId == node.id);
      final activity = nodeActivities[node.id] ?? 0.5;

      // Outer soft glow for active or selected nodes
      if (node.isCentral || isSelected || activity > 0.6) {
        final glowRadius = r * (1.6 + (math.sin(pulsePhase * math.pi * 2) * 0.15));
        final glowPaint = Paint()
          ..shader = RadialGradient(
            colors: [
              node.color.withValues(alpha: isSelected ? 0.45 : 0.22),
              node.color.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromCircle(center: pos, radius: glowRadius));
        canvas.drawCircle(pos, glowRadius, glowPaint);
      }

      // 3D Spherical Radial Lighting Shader (Simulates soft top-left specular highlight)
      final sphereShader = RadialGradient(
        center: const Alignment(-0.35, -0.4),
        radius: 0.85,
        colors: [
          Colors.white.withValues(alpha: 0.92),
          node.color,
          Color.lerp(node.color, Colors.black, 0.45)!,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: pos, radius: r));

      final spherePaint = Paint()
        ..shader = sphereShader
        ..style = PaintingStyle.fill;

      canvas.drawCircle(pos, r, spherePaint);

      // Node border ring for crisp research look
      final ringPaint = Paint()
        ..color = isSelected ? Colors.white : Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = isSelected ? 2.5 : 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(pos, r, ringPaint);

      // Node Label (Visible when scale is comfortable)
      if (rNode.depthZ > -40) {
        final textSpan = TextSpan(
          text: node.sensorModality,
          style: TextStyle(
            color: AppTheme.textDark.withValues(alpha: ((rNode.depthZ + 80) / 160).clamp(0.3, 1.0)),
            fontSize: node.isCentral ? 11 : 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(
          canvas,
          Offset(pos.dx - textPainter.width / 2, pos.dy + r + 4),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant TriaxStructurePainter oldDelegate) {
    return oldDelegate.rotX != rotX ||
        oldDelegate.rotY != rotY ||
        oldDelegate.rotZ != rotZ ||
        oldDelegate.scale != scale ||
        oldDelegate.pulsePhase != pulsePhase ||
        oldDelegate.selectedNodeId != selectedNodeId ||
        oldDelegate.nodeActivities != nodeActivities;
  }
}

class _RenderNode {
  final int index;
  final TriaxNode3D node;
  final Offset screenPos;
  final double radius;
  final double depthZ;

  _RenderNode({
    required this.index,
    required this.node,
    required this.screenPos,
    required this.radius,
    required this.depthZ,
  });
}
