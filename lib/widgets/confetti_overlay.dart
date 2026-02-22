import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiOverlay extends StatefulWidget {
  final bool trigger;

  const ConfettiOverlay({super.key, required this.trigger});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<_Particle> _particles = [];
  final _random = Random();

  static const _colors = [
    Color(0xFFFFD32A),
    Color(0xFF3498DB),
    Color(0xFFE74C3C),
    Color(0xFF2ECC71),
    Color(0xFFFF6B81),
    Color(0xFFA29BFE),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _spawnParticles();
    }
  }

  void _spawnParticles() {
    _particles = List.generate(40, (_) {
      return _Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble() * 0.5,
        vx: (_random.nextDouble() - 0.5) * 0.02,
        vy: _random.nextDouble() * 0.01 + 0.005,
        color: _colors[_random.nextInt(_colors.length)],
        size: _random.nextDouble() * 6 + 4,
      );
    });
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.isAnimating) return const SizedBox.shrink();

    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _ConfettiPainter(
          particles: _particles,
          progress: _controller.value,
        ),
      ),
    );
  }
}

class _Particle {
  double x, y, vx, vy;
  final Color color;
  final double size;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final opacity = (1 - progress).clamp(0.0, 1.0);
      final paint = Paint()..color = p.color.withValues(alpha: opacity);

      final x = (p.x + p.vx * progress * 60) * size.width;
      final y = (p.y + p.vy * progress * 60) * size.height;
      final s = p.size * (1 - progress * 0.5);

      canvas.drawCircle(Offset(x, y), s, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
