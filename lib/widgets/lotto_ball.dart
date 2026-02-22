import 'package:flutter/material.dart';
import '../utils/ball_colors.dart';

class LottoBall extends StatelessWidget {
  final int number;
  final double size;
  final bool isBonus;

  const LottoBall({
    super.key,
    required this.number,
    this.size = 52,
    this.isBonus = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = BallColors.getGradient(number);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.35),
          radius: 0.75,
          colors: [
            Color.lerp(colors[0], Colors.white, 0.35)!,
            colors[0],
            colors[1],
            Color.lerp(colors[1], Colors.black, 0.25)!,
          ],
          stops: const [0, 0.25, 0.7, 1],
        ),
        border: isBonus
            ? Border.all(color: Colors.white.withValues(alpha: 0.85), width: 3)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: colors[0].withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Stack(
        children: [
          // 주 하이라이트
          Positioned(
            top: size * 0.08,
            left: size * 0.12,
            child: Container(
              width: size * 0.35,
              height: size * 0.18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.55),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // 미니 하이라이트
          Positioned(
            top: size * 0.22,
            left: size * 0.2,
            child: Container(
              width: size * 0.1,
              height: size * 0.06,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ),
          Center(
            child: Text(
              '$number',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.38,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    offset: const Offset(0, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedLottoBall extends StatefulWidget {
  final int number;
  final double size;
  final bool isBonus;
  final Duration delay;

  const AnimatedLottoBall({
    super.key,
    required this.number,
    this.size = 52,
    this.isBonus = false,
    this.delay = Duration.zero,
  });

  @override
  State<AnimatedLottoBall> createState() => _AnimatedLottoBallState();
}

class _AnimatedLottoBallState extends State<AnimatedLottoBall>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;
  late Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
      ),
    );
    _slide = Tween<Offset>(
      begin: const Offset(3.0, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutCubic),
      ),
    );
    _rotation = Tween<double>(begin: 3.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutCubic),
      ),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _opacity,
        child: AnimatedBuilder(
          animation: _rotation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotation.value,
              child: child,
            );
          },
          child: LottoBall(
            number: widget.number,
            size: widget.size,
            isBonus: widget.isBonus,
          ),
        ),
      ),
    );
  }
}
