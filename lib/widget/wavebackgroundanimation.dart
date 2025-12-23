import 'dart:ui';

import 'package:flutter/material.dart';

class WaveBackground extends StatefulWidget {
  const WaveBackground({super.key});

  @override
  State<WaveBackground> createState() => _WaveBackgroundState();
}

class _WaveBackgroundState extends State<WaveBackground>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = [
      AnimationController(vsync: this, duration: const Duration(seconds: 30))..repeat(),
      AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat(),
      AnimationController(vsync: this, duration: const Duration(seconds: 30))..repeat(),
      AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(),
    ];
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          Container(color: const Color(0xFF3586FF)),
          _buildWaveLayers(),
        ],
      ),
    );
  }

  Widget _buildWaveLayers() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 150, // Increased height area for waves
        child: Stack(
          children: [
            _buildWaveLayer(controller: _controllers[0], offset: 0, opacity: 1, speed: 1),
            _buildWaveLayer(controller: _controllers[1], offset: 20, opacity: 0.5, speed: -1),
            _buildWaveLayer(controller: _controllers[2], offset: 40, opacity: 0.2, speed: 1),
            _buildWaveLayer(controller: _controllers[3], offset: 60, opacity: 0.7, speed: -1),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveLayer({
    required AnimationController controller,
    required double offset,
    required double opacity,
    required double speed,
  }) {
    return Positioned(
      bottom: offset,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size(MediaQuery.of(context).size.width, 150),
            painter: WavePainter(
              animationValue: controller.value,
              speed: speed,
              opacity: opacity,
            ),
          );
        },
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final double animationValue;
  final double speed;
  final double opacity;

  WavePainter({
    required this.animationValue,
    required this.speed,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    final path = Path();
    const waveHeight = 40.0; // Increased wave height
    final baseHeight = size.height - waveHeight;

    path.moveTo(0, baseHeight);

    final waveWidth = size.width * 2;
    final offset = animationValue * waveWidth * speed;

    for (double x = 0; x < size.width + 100; x += 100) {
      final xOffset = x - offset;
      path.quadraticBezierTo(
        xOffset + 50, baseHeight - waveHeight,
        xOffset + 100, baseHeight,
      );
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
          oldDelegate.speed != speed ||
          oldDelegate.opacity != opacity;
}