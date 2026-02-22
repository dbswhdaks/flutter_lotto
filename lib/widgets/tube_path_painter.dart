import 'dart:math' as math;
import 'dart:ui' show Tangent;
import 'package:flutter/material.dart';

class TubePathPainter extends CustomPainter {
  final Path centerPath;
  final bool visible;
  final double tubeWidth;

  TubePathPainter({
    required this.centerPath,
    this.visible = true,
    this.tubeWidth = 32,
  });

  static Path buildCenterPath({
    required double cx,
    required double cy,
    required double tubeTop,
    required double radius,
    required double endX,
    required double endY,
  }) {
    final leftEdge = cx - radius - 35;

    return Path()
      ..moveTo(cx, cy)
      ..lineTo(cx, tubeTop)
      ..cubicTo(
        cx - 50, tubeTop - 30,
        leftEdge - 10, tubeTop - 15,
        leftEdge, cy - 10,
      )
      ..cubicTo(
        leftEdge + 5, cy + radius * 0.5,
        leftEdge + 30, cy + radius + 15,
        cx - 30, cy + radius + 35,
      )
      ..cubicTo(
        cx + 10, cy + radius + 45,
        endX + 10, endY - 25,
        endX, endY,
      );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (!visible) return;

    final metricsList = centerPath.computeMetrics().toList();
    if (metricsList.isEmpty) return;

    double totalLen = 0;
    for (final m in metricsList) {
      totalLen += m.length;
    }

    const steps = 150;
    final halfW = tubeWidth / 2;
    final centerPoints = <Offset>[];
    final leftOuter = <Offset>[];
    final rightOuter = <Offset>[];
    final leftInner = <Offset>[];
    final rightInner = <Offset>[];

    const wallThickness = 2.5;

    for (int i = 0; i <= steps; i++) {
      final dist = totalLen * (i / steps);

      Tangent? tangent;
      double accumulated = 0;
      for (final metric in metricsList) {
        if (accumulated + metric.length >= dist) {
          tangent = metric.getTangentForOffset(dist - accumulated);
          break;
        }
        accumulated += metric.length;
      }
      if (tangent == null) continue;

      final pos = tangent.position;
      final angle = tangent.angle;

      final nx = -math.sin(angle);
      final ny = math.cos(angle);

      centerPoints.add(pos);
      leftOuter.add(Offset(pos.dx + nx * halfW, pos.dy + ny * halfW));
      rightOuter.add(Offset(pos.dx - nx * halfW, pos.dy - ny * halfW));
      leftInner.add(
          Offset(pos.dx + nx * (halfW - wallThickness), pos.dy + ny * (halfW - wallThickness)));
      rightInner.add(
          Offset(pos.dx - nx * (halfW - wallThickness), pos.dy - ny * (halfW - wallThickness)));
    }

    if (leftOuter.length < 2) return;

    // ── 1) 유리 내부 (투명 채우기) ──
    final innerFill = _buildClosedPath(leftInner, rightInner);
    canvas.drawPath(
      innerFill,
      Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0x08FFFFFF),
    );

    // ── 2) 유리 벽 두께 (좌측 = 밝은쪽, 우측 = 어두운쪽) ──
    final leftWallPath = _buildStripPath(leftOuter, leftInner);
    final rightWallPath = _buildStripPath(rightOuter, rightInner);

    // 좌측 벽 (빛 받는 쪽 - 밝게)
    canvas.drawPath(
      leftWallPath,
      Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.white.withValues(alpha: 0.12),
    );

    // 우측 벽 (그림자 쪽 - 약간 어둡게)
    canvas.drawPath(
      rightWallPath,
      Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.white.withValues(alpha: 0.06),
    );

    // ── 3) 외벽 테두리 (선명한 유리 엣지) ──
    final leftOuterPath = _buildSmoothPath(leftOuter);
    final rightOuterPath = _buildSmoothPath(rightOuter);

    // 좌측 외벽 (밝은 엣지)
    canvas.drawPath(
      leftOuterPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = Colors.white.withValues(alpha: 0.4),
    );

    // 우측 외벽
    canvas.drawPath(
      rightOuterPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.25),
    );

    // ── 4) 내벽 테두리 (유리 안쪽 반사) ──
    final leftInnerPath = _buildSmoothPath(leftInner);
    final rightInnerPath = _buildSmoothPath(rightInner);

    canvas.drawPath(
      leftInnerPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = Colors.white.withValues(alpha: 0.12),
    );
    canvas.drawPath(
      rightInnerPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = Colors.white.withValues(alpha: 0.08),
    );

    // ── 5) 세로 하이라이트 반사선 (유리 표면 반사) ──
    // 좌측 강한 반사 (유리관 이미지의 밝은 세로줄)
    final highlight1 = <Offset>[];
    for (int i = 0; i < leftOuter.length; i++) {
      final l = leftOuter[i];
      final r = rightOuter[i];
      highlight1.add(Offset(
        l.dx * 0.75 + r.dx * 0.25,
        l.dy * 0.75 + r.dy * 0.25,
      ));
    }
    canvas.drawPath(
      _buildSmoothPath(highlight1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = Colors.white.withValues(alpha: 0.15),
    );

    // 우측 약한 반사
    final highlight2 = <Offset>[];
    for (int i = 0; i < leftOuter.length; i++) {
      final l = leftOuter[i];
      final r = rightOuter[i];
      highlight2.add(Offset(
        l.dx * 0.2 + r.dx * 0.8,
        l.dy * 0.2 + r.dy * 0.8,
      ));
    }
    canvas.drawPath(
      _buildSmoothPath(highlight2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.07),
    );

    // ── 6) 중앙 미세 반사 (유리 깊이감) ──
    final centerHighlight = <Offset>[];
    for (int i = 0; i < leftOuter.length; i++) {
      final l = leftInner[i];
      final r = rightInner[i];
      centerHighlight.add(Offset(
        l.dx * 0.55 + r.dx * 0.45,
        l.dy * 0.55 + r.dy * 0.45,
      ));
    }
    canvas.drawPath(
      _buildSmoothPath(centerHighlight),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = Colors.white.withValues(alpha: 0.05),
    );
  }

  Path _buildSmoothPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    return path;
  }

  Path _buildClosedPath(List<Offset> side1, List<Offset> side2) {
    final path = Path()..moveTo(side1.first.dx, side1.first.dy);
    for (final p in side1) {
      path.lineTo(p.dx, p.dy);
    }
    for (final p in side2.reversed) {
      path.lineTo(p.dx, p.dy);
    }
    path.close();
    return path;
  }

  Path _buildStripPath(List<Offset> outer, List<Offset> inner) {
    final path = Path()..moveTo(outer.first.dx, outer.first.dy);
    for (final p in outer) {
      path.lineTo(p.dx, p.dy);
    }
    for (final p in inner.reversed) {
      path.lineTo(p.dx, p.dy);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant TubePathPainter oldDelegate) =>
      oldDelegate.visible != visible;
}
