import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/doublejack_result.dart';
import 'doublejack_ai_page.dart';

class DoublejackPage extends StatefulWidget {
  const DoublejackPage({super.key});

  @override
  State<DoublejackPage> createState() => _DoublejackPageState();
}

class _DoublejackPageState extends State<DoublejackPage>
    with TickerProviderStateMixin {
  int _drawCount = 0;
  bool _isDrawing = false;
  DoublejackResult? _currentResult;
  final List<int> _revealedJack = [];
  final List<int> _revealedMidas = [];
  final List<DoublejackResult> _history = [];
  bool _showConfetti = false;

  late final List<AnimationController> _jackControllers;
  late final List<AnimationController> _midasControllers;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _jackControllers = List.generate(
      6,
      (_) => AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      ),
    );
    _midasControllers = List.generate(
      6,
      (_) => AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      ),
    );
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    for (final c in _jackControllers) {
      c.dispose();
    }
    for (final c in _midasControllers) {
      c.dispose();
    }
    _glowController.dispose();
    super.dispose();
  }

  Color _ballColor(int number) {
    if (number <= 9) return const Color(0xFFFFB300);
    if (number <= 18) return const Color(0xFFFF8F00);
    if (number <= 27) return const Color(0xFFFFA726);
    if (number <= 36) return const Color(0xFFEF6C00);
    return const Color(0xFFE65100);
  }

  Future<void> _startDraw() async {
    if (_isDrawing) return;

    setState(() {
      _isDrawing = true;
      _showConfetti = false;
      _drawCount++;
      _revealedJack.clear();
      _revealedMidas.clear();
      _currentResult = DoublejackResult.generate(_drawCount);
    });

    _glowController.repeat(reverse: true);
    await Future.delayed(const Duration(milliseconds: 400));

    for (int i = 0; i < 6; i++) {
      if (!mounted) return;
      _jackControllers[i].forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      setState(() => _revealedJack.add(_currentResult!.jackNumbers[i]));
      await Future.delayed(const Duration(milliseconds: 150));
    }

    await Future.delayed(const Duration(milliseconds: 400));

    for (int i = 0; i < 6; i++) {
      if (!mounted) return;
      _midasControllers[i].forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      setState(() => _revealedMidas.add(_currentResult!.midasNumbers[i]));
      await Future.delayed(const Duration(milliseconds: 150));
    }

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    _glowController.stop();
    _glowController.value = 0;

    setState(() {
      _isDrawing = false;
      _showConfetti = true;
      _history.insert(0, _currentResult!);
    });

    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) setState(() => _showConfetti = false);
  }

  void _reset() {
    _glowController.stop();
    _glowController.value = 0;
    for (final c in [..._jackControllers, ..._midasControllers]) {
      c.reset();
    }
    setState(() {
      _isDrawing = false;
      _drawCount = 0;
      _currentResult = null;
      _revealedJack.clear();
      _revealedMidas.clear();
      _history.clear();
      _showConfetti = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 8),
                          _buildHeader(),
                          const SizedBox(height: 16),
                          _buildMachine(),
                          const SizedBox(height: 16),
                          _buildButtons(),
                          const SizedBox(height: 16),
                          _buildHistory(),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  );
                },
              ),
              if (_showConfetti) _buildConfettiOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child:
                  const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          const Expanded(
            child: Column(
              children: [
                Text(
                  '👑 더블잭마이더스',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '잭 6개 + 마이더스 6개 추첨!',
                  style: TextStyle(
                    color: Color(0xFFFFD54F),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _reset,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.3),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2), width: 1.5),
              ),
              child: Icon(Icons.refresh,
                  color: Colors.white.withValues(alpha: 0.9), size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMachine() {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final glow = _glowController.value;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2A1F00),
                Color(0xFF1E1600),
                Color(0xFF161000),
              ],
            ),
            border: Border.all(
              color: Color.lerp(
                const Color(0xFF5A4A00),
                const Color(0xFFFFD700),
                glow * 0.5,
              )!,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFB300)
                    .withValues(alpha: 0.1 + glow * 0.15),
                blurRadius: 20 + glow * 15,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSetLabel('JACK', const Color(0xFFFFD700)),
              const SizedBox(height: 8),
              _buildBallRow(_revealedJack, _jackControllers),
              const SizedBox(height: 14),
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _buildSetLabel('MIDAS', const Color(0xFFFF6F00)),
              const SizedBox(height: 8),
              _buildBallRow(_revealedMidas, _midasControllers),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSetLabel(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildBallRow(
      List<int> revealed, List<AnimationController> controllers) {
    return Row(
      children: List.generate(6, (i) {
        final hasNumber = i < revealed.length;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: AspectRatio(
              aspectRatio: 1,
              child: AnimatedBuilder(
                animation: controllers[i],
                builder: (context, _) {
                  final bounce = hasNumber
                      ? 1.0 +
                          (1 - controllers[i].value).clamp(0.0, 1.0) * 0.2
                      : 1.0;
                  final color = hasNumber
                      ? _ballColor(revealed[i])
                      : Colors.white.withValues(alpha: 0.06);
                  return Transform.scale(
                    scale: bounce,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: hasNumber
                            ? RadialGradient(
                                center: const Alignment(-0.3, -0.3),
                                radius: 0.8,
                                colors: [
                                  Color.lerp(color, Colors.white, 0.4)!,
                                  color,
                                  Color.lerp(color, Colors.black, 0.2)!,
                                ],
                              )
                            : null,
                        color: hasNumber ? null : color,
                        boxShadow: hasNumber
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                  spreadRadius: -2,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Text(
                              hasNumber ? '${revealed[i]}' : '?',
                              style: TextStyle(
                                color: hasNumber
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.2),
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                shadows: hasNumber
                                    ? const [
                                        Shadow(
                                          color: Color(0x55000000),
                                          offset: Offset(0, 1),
                                          blurRadius: 3,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _DrawButton(
                  onPressed: _isDrawing ? null : _startDraw,
                  isDrawing: _isDrawing,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _BuyButton()),
            ],
          ),
          const SizedBox(height: 10),
          _AiButton(
            onPressed: _isDrawing
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const DoublejackAiPage()),
                    );
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    if (_history.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      constraints: const BoxConstraints(maxHeight: 250),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                Icon(Icons.history,
                    color: Colors.white.withValues(alpha: 0.5), size: 16),
                const SizedBox(width: 6),
                Text(
                  '추첨 이력',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _history.length,
              itemBuilder: (context, index) =>
                  _HistoryRow(result: _history[index], ballColor: _ballColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfettiOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: _DJConfetti(key: ValueKey(_drawCount)),
      ),
    );
  }
}

// ── 버튼 ──

class _DrawButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isDrawing;

  const _DrawButton({required this.onPressed, required this.isDrawing});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB300), Color(0xFFFF8F00), Color(0xFFEF6C00)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB300).withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isDrawing ? Icons.hourglass_top : Icons.casino,
                  color: Colors.white.withValues(alpha: enabled ? 1 : 0.5),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  isDrawing ? '추첨 중...' : '번호 추첨',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: enabled ? 1 : 0.5),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AiButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _AiButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF4F8CFF), Color(0xFF6FA3FF)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F8CFF).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome,
                    color: Colors.white.withValues(alpha: enabled ? 1 : 0.5),
                    size: 18),
                const SizedBox(width: 8),
                Text(
                  'AI 데이터 분석 추천',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: enabled ? 1 : 0.5),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BuyButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF38B2AC), Color(0xFF4FD1C5)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38B2AC).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            try {
              await launchUrl(
                Uri.parse('https://el.dhlottery.co.kr/game/TotalGame.jsp?LottoId=LD20'),
                mode: LaunchMode.externalApplication,
              );
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('브라우저를 열 수 없습니다')),
                );
              }
            }
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart, color: Colors.white, size: 17),
                SizedBox(width: 6),
                Text('구매',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 이력 ──

class _HistoryRow extends StatelessWidget {
  final DoublejackResult result;
  final Color Function(int) ballColor;

  const _HistoryRow({required this.result, required this.ballColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Text(
              '${result.round}회  ',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 10,
              ),
            ),
            _badge('J', const Color(0xFFFFD700)),
            const SizedBox(width: 3),
            ...result.jackNumbers.map((n) => Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: _mini(n),
                )),
            const SizedBox(width: 4),
            _badge('M', const Color(0xFFFF6F00)),
            const SizedBox(width: 3),
            ...result.midasNumbers.map((n) => Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: _mini(n),
                )),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: color.withValues(alpha: 0.15),
      ),
      child: Text(label,
          style:
              TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800)),
    );
  }

  Widget _mini(int n) {
    final c = ballColor(n);
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [c, Color.lerp(c, Colors.black, 0.2)!],
        ),
      ),
      child: Center(
        child: Text(
          '$n',
          style: const TextStyle(
              color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ── 컨페티 ──

class _DJConfetti extends StatefulWidget {
  const _DJConfetti({super.key});

  @override
  State<_DJConfetti> createState() => _DJConfettiState();
}

class _DJConfettiState extends State<_DJConfetti>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _particles = List.generate(45, (_) => _Particle(rng));
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _ConfettiPainter(
              particles: _particles, progress: _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Particle {
  final double x, speed, size, drift, rotation;
  final Color color;

  _Particle(Random r)
      : x = r.nextDouble(),
        speed = 0.3 + r.nextDouble() * 0.7,
        size = 4 + r.nextDouble() * 6,
        drift = (r.nextDouble() - 0.5) * 0.3,
        rotation = r.nextDouble() * pi * 2,
        color = [
          const Color(0xFFFFD700),
          const Color(0xFFFFB300),
          const Color(0xFFFF8F00),
          const Color(0xFFEF6C00),
          const Color(0xFFFFC107),
          const Color(0xFFFFECB3),
        ][r.nextInt(6)];
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = -20 + progress * size.height * p.speed * 1.5;
      final x = p.x * size.width +
          sin(progress * pi * 3 + p.rotation) * 30 * p.drift;
      final opacity = (1 - progress).clamp(0.0, 1.0);
      final paint = Paint()..color = p.color.withValues(alpha: opacity * 0.8);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * pi * 2 * p.speed + p.rotation);
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset.zero, width: p.size, height: p.size * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}
