import 'dart:math';

class BallPhysics {
  double x, y, vx, vy;
  final int number;
  final double radius;

  BallPhysics({
    required this.x,
    required this.y,
    required this.number,
    this.radius = 18,
    double? vx,
    double? vy,
  })  : vx = vx ?? (Random().nextDouble() - 0.5) * 4,
        vy = vy ?? (Random().nextDouble() - 0.5) * 4;

  void update(double containerRadius, double cx, double cy) {
    vy += 0.2;
    x += vx;
    y += vy;

    final dx = x - cx;
    final dy = y - cy;
    final dist = sqrt(dx * dx + dy * dy);
    final maxR = containerRadius - radius;

    if (dist > maxR) {
      final angle = atan2(dy, dx);
      x = cx + cos(angle) * maxR;
      y = cy + sin(angle) * maxR;

      final nx = cos(angle);
      final ny = sin(angle);
      final dot = vx * nx + vy * ny;
      vx -= 2 * dot * nx;
      vy -= 2 * dot * ny;
      vx *= 0.8;
      vy *= 0.8;
    }
  }

  void boost() {
    final random = Random();
    vx += (random.nextDouble() - 0.5) * 12;
    vy += (random.nextDouble() - 0.5) * 12 - 4;
  }
}
