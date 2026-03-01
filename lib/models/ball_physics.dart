import 'dart:math';

class BallPhysics {
  double x, y, vx, vy;
  final int number;
  final double radius;

  /// 공마다 다른 물리 특성 (0~1, 번호 기반 시드)
  final double _gravityFactor;
  final double _bounceFactor;
  final double _turbulenceFactor;
  final double _swirlFactor;
  int _tick = 0;

  BallPhysics({
    required this.x,
    required this.y,
    required this.number,
    this.radius = 18,
    double? vx,
    double? vy,
  })  : _gravityFactor = 0.12 + (number % 10) / 80,
        _bounceFactor = 0.78 + (number % 7) / 80,
        _turbulenceFactor = 1.2 + (number % 5) / 8,
        _swirlFactor = (number % 3 - 1) * 0.25,
        vx = vx ?? (Random().nextDouble() - 0.5) * 10,
        vy = vy ?? (Random().nextDouble() - 0.5) * 10;

  void update(double containerRadius, double cx, double cy, {bool isSpinning = true}) {
    _tick++;

    // 공마다 다른 중력 (항상 적용 - 추첨 끝나면 하단으로 떨어짐)
    vy += 0.2 * _gravityFactor;

    if (isSpinning) {
      // 강한 난류 (매 프레임 다른 방향)
      final r = Random(number + _tick);
      vx += (r.nextDouble() - 0.5) * _turbulenceFactor;
      vy += (r.nextDouble() - 0.5) * _turbulenceFactor;

      // 12~25프레임마다 미세한 충격 (공마다 다른 주기로 다양하게)
      if (_tick % (12 + number % 14) == number % 5) {
        vx += (r.nextDouble() - 0.5) * 2.5;
        vy += (r.nextDouble() - 0.5) * 2.5;
      }

      // 소용돌이 (공마다 다른 방향·강도)
      final dx = x - cx;
      final dy = y - cy;
      final dist = sqrt(dx * dx + dy * dy);
      if (dist > 5) {
        final tangentX = -dy / dist;
        final tangentY = dx / dist;
        final swirl = _swirlFactor * (0.8 + 0.4 * sin(_tick * 0.1 + number * 0.5));
        vx += tangentX * swirl;
        vy += tangentY * swirl;
      }
    } else {
      // 추첨 끝: 속도 감쇠 (바닥에 안정적으로 정착)
      vx *= 0.96;
      vy *= 0.96;
    }

    x += vx;
    y += vy;

    final dxNew = x - cx;
    final dyNew = y - cy;
    final distNew = sqrt(dxNew * dxNew + dyNew * dyNew);
    final maxR = containerRadius - radius;

    if (distNew > maxR) {
      final angle = atan2(dyNew, dxNew);
      x = cx + cos(angle) * maxR;
      y = cy + sin(angle) * maxR;

      final nx = cos(angle);
      final ny = sin(angle);
      final dot = vx * nx + vy * ny;
      vx -= 2 * dot * nx;
      vy -= 2 * dot * ny;
      vx *= _bounceFactor;
      vy *= _bounceFactor;
    }
  }

  void boost() {
    final random = Random();
    final angle = random.nextDouble() * pi * 2;
    final strength = 14 + random.nextDouble() * 16;
    vx += cos(angle) * strength + (random.nextDouble() - 0.5) * 10;
    vy += sin(angle) * strength - 2 + (random.nextDouble() - 0.5) * 10;
  }
}
