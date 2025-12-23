import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class Background extends StatelessWidget {
  const Background({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4e54c8), Color(0xFF8f94fb)],
        ),
      ),
    );
  }
}

class CirclesAnimation extends StatefulWidget {
  const CirclesAnimation({super.key});

  @override
  State<CirclesAnimation> createState() => _CirclesAnimationState();
}

class _CirclesAnimationState extends State<CirclesAnimation> {
  final List<CircleData> circles = [
    CircleData(left: 0.25, size: 80, delay: 0, duration: 25),
    CircleData(left: 0.10, size: 20, delay: 2, duration: 12),
    CircleData(left: 0.70, size: 20, delay: 4, duration: 25),
    CircleData(left: 0.40, size: 60, delay: 0, duration: 18),
    CircleData(left: 0.65, size: 20, delay: 0, duration: 25),
    CircleData(left: 0.75, size: 110, delay: 3, duration: 25),
    CircleData(left: 0.35, size: 150, delay: 7, duration: 25),
    CircleData(left: 0.50, size: 25, delay: 15, duration: 45),
    CircleData(left: 0.20, size: 15, delay: 2, duration: 35),
    CircleData(left: 0.85, size: 150, delay: 0, duration: 11),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      child: Stack(
        children: circles.map((circle) => AnimatedCircle(data: circle)).toList(),
      ),
    );
  }
}

class AnimatedCircle extends StatefulWidget {
  final CircleData data;

  const AnimatedCircle({super.key, required this.data});

  @override
  State<AnimatedCircle> createState() => _AnimatedCircleState();
}

class _AnimatedCircleState extends State<AnimatedCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.data.duration),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    Timer(Duration(seconds: widget.data.delay), () {
      _controller.repeat();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          left: widget.data.left * screenWidth,
          bottom: -widget.data.size.toDouble(),
          child: Transform.translate(
            offset: Offset(0, -_animation.value * (screenHeight + 150)),
            child: Transform.rotate(
              angle: _animation.value * 4 * pi,
              child: Opacity(
                opacity: 1 - _animation.value,
                child: Container(
                  width: widget.data.size.toDouble(),
                  height: widget.data.size.toDouble(),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(
                        _animation.value * widget.data.size / 2),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class CircleData {
  final double left;
  final int size;
  final int delay;
  final int duration;

  CircleData({
    required this.left,
    required this.size,
    required this.delay,
    required this.duration,
  });
}