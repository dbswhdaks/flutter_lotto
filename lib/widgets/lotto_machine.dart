import 'dart:math';
import 'package:flutter/material.dart';
import '../models/ball_physics.dart';
import '../utils/ball_colors.dart';

class LottoMachine extends StatefulWidget {
  final bool isSpinning;
  final double sphereSize;

  const LottoMachine({
    super.key,
    this.isSpinning = false,
    this.sphereSize = 220,
  });

  double get totalWidth => sphereSize + 40;
  double get totalHeight => sphereSize + 160;

  @override
  State<LottoMachine> createState() => LottoMachineState();
}

class LottoMachineState extends State<LottoMachine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<BallPhysics> _balls = [];
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updateBalls);
    _initBalls();
  }

  void _initBalls() {
    final s = widget.sphereSize;
    final cx = s / 2;
    final cy = s / 2;
    final usedNumbers = <int>{};
    _balls = List.generate(28, (_) {
      int n;
      do {
        n = _random.nextInt(45) + 1;
      } while (usedNumbers.contains(n));
      usedNumbers.add(n);
      final angle = _random.nextDouble() * pi * 2;
      final r = _random.nextDouble() * s * 0.25;
      return BallPhysics(
        x: cx + cos(angle) * r,
        y: cy + sin(angle) * r + s * 0.12,
        number: n,
        radius: 13,
      );
    });
  }

  void _updateBalls() {
    if (!widget.isSpinning) return;
    setState(() {
      final s = widget.sphereSize;
      final cx = s / 2;
      final cy = s / 2;
      for (final ball in _balls) {
        ball.update(s / 2 - 8, cx, cy);
      }
    });
  }

  void boostBalls() {
    for (final ball in _balls) {
      ball.boost();
    }
  }

  @override
  void didUpdateWidget(LottoMachine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpinning && !_controller.isAnimating) {
      for (final ball in _balls) {
        ball.boost();
      }
      _controller.repeat();
    } else if (!widget.isSpinning && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.sphereSize;
    final w = widget.totalWidth;
    final h = widget.totalHeight;

    // 주요 위치 계산
    const capH = 20.0;
    const tubeAboveH = 30.0;
    final sphereTop = capH + tubeAboveH;
    final sphereLeft = (w - s) / 2;
    final baseTop = sphereTop + s - 8;
    const baseH = 80.0;

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── 1. 상단 깔때기 캡 ──
          Positioned(
            top: 0,
            left: w / 2 - 30,
            child: Container(
              width: 60,
              height: capH,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE0E0E0), Color(0xFFB0B0B0)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),

          // ── 2. 중앙 수직 튜브 (구체 위 부분) ──
          Positioned(
            top: capH - 2,
            left: w / 2 - 14,
            child: Container(
              width: 28,
              height: tubeAboveH + 8,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.05),
                    Colors.white.withValues(alpha: 0.2),
                    Colors.white.withValues(alpha: 0.35),
                    Colors.white.withValues(alpha: 0.2),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
                border: Border.symmetric(
                  vertical: BorderSide(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          // ── 3. 유리 구체 ──
          Positioned(
            top: sphereTop,
            left: sphereLeft,
            child: SizedBox(
              width: s,
              height: s,
              child: Stack(
                children: [
                  // 구체 본체
                  CustomPaint(
                    size: Size(s, s),
                    painter: _GlassSpherePainter(),
                  ),

                  // 내부 bowl (오목한 그릇 구조)
                  Positioned(
                    bottom: s * 0.12,
                    left: s * 0.12,
                    child: CustomPaint(
                      size: Size(s * 0.76, s * 0.28),
                      painter: _BowlPainter(),
                    ),
                  ),

                  // 중앙 튜브 (구체 내부 관통)
                  Positioned(
                    top: 0,
                    left: s / 2 - 12,
                    child: Container(
                      width: 24,
                      height: s * 0.6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.03),
                            Colors.white.withValues(alpha: 0.12),
                            Colors.white.withValues(alpha: 0.2),
                            Colors.white.withValues(alpha: 0.12),
                            Colors.white.withValues(alpha: 0.03),
                          ],
                        ),
                        border: Border.symmetric(
                          vertical: BorderSide(
                            color: Colors.white.withValues(alpha: 0.12),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 튜브 하단 입구 (구체 내부)
                  Positioned(
                    top: s * 0.55,
                    left: s / 2 - 16,
                    child: Container(
                      width: 32,
                      height: 10,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: Colors.white.withValues(alpha: 0.08),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                  ),

                  // 공들
                  ..._balls.map((ball) => Positioned(
                        left: ball.x - ball.radius,
                        top: ball.y - ball.radius,
                        child: _MachineBall(
                          number: ball.number,
                          size: ball.radius * 2,
                        ),
                      )),
                ],
              ),
            ),
          ),

          // ── 4. 투명 받침대 (직사각형 하우징) ──
          Positioned(
            top: baseTop,
            left: w / 2 - s * 0.38,
            child: Container(
              width: s * 0.76,
              height: baseH,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.white.withValues(alpha: 0.04),
                    Colors.white.withValues(alpha: 0.06),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // 내부 메커니즘 느낌 (가로 줄)
                  Positioned(
                    top: 20,
                    left: 10,
                    right: 10,
                    child: Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  Positioned(
                    top: 45,
                    left: 10,
                    right: 10,
                    child: Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  // 기어/메커니즘 힌트
                  Positioned(
                    top: 25,
                    left: 15,
                    child: _GearIcon(size: 16),
                  ),
                  Positioned(
                    top: 25,
                    right: 15,
                    child: _GearIcon(size: 16),
                  ),
                ],
              ),
            ),
          ),

          // ── 5. 받침대 하단 베이스 ──
          Positioned(
            top: baseTop + baseH - 2,
            left: w / 2 - s * 0.45,
            child: Container(
              width: s * 0.9,
              height: 12,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFB0B0B0), Color(0xFF888888)],
                ),
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
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

// ── 유리 구체 페인터 ──
class _GlassSpherePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 외곽 테두리
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: [
          Colors.white.withValues(alpha: 0.4),
          Colors.white.withValues(alpha: 0.15),
          Colors.white.withValues(alpha: 0.25),
        ],
        stops: const [0, 0.5, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, borderPaint);

    // 유리 내부 그라데이션
    final glassPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.25),
        radius: 0.85,
        colors: [
          Colors.white.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.04),
          Colors.white.withValues(alpha: 0.01),
          Colors.black.withValues(alpha: 0.03),
        ],
        stops: const [0, 0.3, 0.7, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius - 2, glassPaint);

    // 좌상단 큰 하이라이트
    final highlightPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        colors: [
          Colors.white.withValues(alpha: 0.2),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCenter(
          center: Offset(size.width * 0.3, size.height * 0.22),
          width: size.width * 0.5,
          height: size.height * 0.2,
        ),
      );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.3, size.height * 0.22),
        width: size.width * 0.45,
        height: size.height * 0.15,
      ),
      highlightPaint,
    );

    // 우하단 반사
    final rimPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        colors: [
          Colors.white.withValues(alpha: 0.06),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCenter(
          center: Offset(size.width * 0.7, size.height * 0.78),
          width: size.width * 0.4,
          height: size.height * 0.1,
        ),
      );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.7, size.height * 0.78),
        width: size.width * 0.35,
        height: size.height * 0.08,
      ),
      rimPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── 내부 Bowl 페인터 ──
class _BowlPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(
        size.width / 2,
        size.height * 1.2,
        size.width,
        0,
      );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withValues(alpha: 0.12);
    canvas.drawPath(path, paint);

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.04),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final fillPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(
        size.width / 2,
        size.height * 1.2,
        size.width,
        0,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── 기어 아이콘 ──
class _GearIcon extends StatelessWidget {
  final double size;
  const _GearIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Center(
        child: Container(
          width: size * 0.4,
          height: size * 0.4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ),
    );
  }
}

// ── 구체 내부 공 ──
class _MachineBall extends StatelessWidget {
  final int number;
  final double size;

  const _MachineBall({required this.number, required this.size});

  @override
  Widget build(BuildContext context) {
    final colors = BallColors.getGradient(number);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.4),
          radius: 0.8,
          colors: [
            Color.lerp(colors[0], Colors.white, 0.3)!,
            colors[0],
            colors[1],
            Color.lerp(colors[1], Colors.black, 0.2)!,
          ],
          stops: const [0, 0.3, 0.7, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: size * 0.1,
            left: size * 0.12,
            child: Container(
              width: size * 0.28,
              height: size * 0.14,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ),
          Center(
            child: Text(
              '$number',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.36,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
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
