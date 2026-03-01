import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/ball_colors.dart';

class TravelingBall extends StatefulWidget {
  final int number;
  final Path path;
  final VoidCallback onArrived;
  final Duration duration;

  const TravelingBall({
    super.key,
    required this.number,
    required this.path,
    required this.onArrived,
    this.duration = const Duration(milliseconds: 1100),
  });

  @override
  State<TravelingBall> createState() => _TravelingBallState();
}

class _TravelingBallState extends State<TravelingBall>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<PathMetric> _metrics;
  double _totalLength = 0;
  Offset _position = Offset.zero;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _metrics = widget.path.computeMetrics().toList();
    for (final m in _metrics) {
      _totalLength += m.length;
    }

    if (_metrics.isNotEmpty) {
      final initial = _metrics.first.getTangentForOffset(0);
      if (initial != null) _position = initial.position;
      _ready = true;
    }

    _controller.addListener(_onTick);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onArrived();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  void _onTick() {
    if (!_ready) return;
    final eased = Curves.easeInCubic.transform(_controller.value);
    final targetDist = _totalLength * eased;
    double accumulated = 0;

    for (final metric in _metrics) {
      if (accumulated + metric.length >= targetDist) {
        final localDist = targetDist - accumulated;
        final tangent = metric.getTangentForOffset(localDist);
        if (tangent != null && mounted) {
          setState(() => _position = tangent.position);
        }
        return;
      }
      accumulated += metric.length;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.shrink();

    final colors = BallColors.getGradient(widget.number);
    const ballSize = 30.0;

    return Positioned(
      left: _position.dx - ballSize / 2,
      top: _position.dy - ballSize / 2,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _controller.value < 0.85 ? 1.0 : 0.0,
        child: Container(
          width: ballSize,
          height: ballSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.3, -0.35),
              radius: 0.75,
              colors: [
                Color.lerp(colors[0], Colors.white, 0.3)!,
                colors[0],
                colors[1],
                Color.lerp(colors[1], Colors.black, 0.2)!,
              ],
              stops: const [0, 0.25, 0.7, 1],
            ),
            boxShadow: [
              BoxShadow(
                color: colors[0].withValues(alpha: 0.5),
                blurRadius: 10,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 3,
                left: 5,
                child: Container(
                  width: 9,
                  height: 5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ),
              Center(
                child: Text(
                  '${widget.number}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        offset: const Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
