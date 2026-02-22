import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/powerball_result.dart';
import 'powerball_ai_page.dart';

class PowerballPage extends StatefulWidget {
  const PowerballPage({super.key});

  @override
  State<PowerballPage> createState() => _PowerballPageState();
}

class _PowerballPageState extends State<PowerballPage>
    with TickerProviderStateMixin {
  int _drawCount = 0;
  bool _isDrawing = false;
  PowerballResult? _currentResult;
  final List<int> _revealedNumbers = [];
  bool _showPowerball = false;
  final List<PowerballResult> _history = [];
  bool _showConfetti = false;

  late final List<AnimationController> _ballControllers;
  late final AnimationController _powerballController;
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _ballControllers = List.generate(
      5,
      (_) => AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: this,
      ),
    );
    _powerballController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    for (final c in _ballControllers) {
      c.dispose();
    }
    _powerballController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _startDraw() async {
    if (_isDrawing) return;

    setState(() {
      _isDrawing = true;
      _showConfetti = false;
      _drawCount++;
      _revealedNumbers.clear();
      _showPowerball = false;
      _currentResult = PowerballResult.generate(_drawCount);
    });

    _glowController.repeat(reverse: true);
    await Future.delayed(const Duration(milliseconds: 400));

    for (int i = 0; i < 5; i++) {
      if (!mounted) return;
      _ballControllers[i].forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      setState(() => _revealedNumbers.add(_currentResult!.numbers[i]));
      await Future.delayed(const Duration(milliseconds: 150));
    }

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    _powerballController.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _showPowerball = true);

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
    for (final c in _ballControllers) {
      c.reset();
    }
    _powerballController.reset();
    setState(() {
      _isDrawing = false;
      _drawCount = 0;
      _currentResult = null;
      _revealedNumbers.clear();
      _showPowerball = false;
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
                          const SizedBox(height: 24),
                          _buildMachine(),
                          const SizedBox(height: 24),
                          _buildResultDisplay(),
                          const SizedBox(height: 24),
                          _buildButtons(),
                          const SizedBox(height: 24),
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
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.arrow_back,
                  color: Colors.white, size: 20),
            ),
          ),
          const Expanded(
            child: Column(
              children: [
                Text(
                  '⚡ 파워볼',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '1~28 중 5개 + 파워볼 0~9',
                  style: TextStyle(
                    color: Color(0xFFFF4757),
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
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2A1B3D),
                Color(0xFF1E1233),
                Color(0xFF16102B),
              ],
            ),
            border: Border.all(
              color: Color.lerp(
                const Color(0xFF4A3560),
                const Color(0xFFFF4757),
                glow * 0.5,
              )!,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4757)
                    .withValues(alpha: 0.1 + glow * 0.15),
                blurRadius: 20 + glow * 15,
                spreadRadius: -2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildNumberBalls(),
              const SizedBox(height: 16),
              _buildPowerballSlot(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNumberBalls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final revealed = i < _revealedNumbers.length;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AspectRatio(
              aspectRatio: 1,
              child: AnimatedBuilder(
                animation: _ballControllers[i],
                builder: (context, _) {
                  final scale = revealed
                      ? 1.0 +
                          (1 - _ballControllers[i].value).clamp(0.0, 1.0) * 0.2
                      : 1.0;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: revealed
                            ? const RadialGradient(
                                center: Alignment(-0.3, -0.3),
                                radius: 0.8,
                                colors: [
                                  Color(0xFF5B9CFF),
                                  Color(0xFF3B7DDB),
                                  Color(0xFF2563AB),
                                ],
                              )
                            : RadialGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.08),
                                  Colors.white.withValues(alpha: 0.03),
                                ],
                              ),
                        boxShadow: revealed
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF3B7DDB)
                                      .withValues(alpha: 0.5),
                                  blurRadius: 12,
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
                              revealed ? '${_revealedNumbers[i]}' : '?',
                              style: TextStyle(
                                color: revealed
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.2),
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                shadows: revealed
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

  Widget _buildPowerballSlot() {
    return AnimatedBuilder(
      animation: _powerballController,
      builder: (context, _) {
        final scale = _showPowerball
            ? 1.0 +
                (1 - _powerballController.value).clamp(0.0, 1.0) * 0.3
            : 1.0;
        return Transform.scale(
          scale: scale,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'POWER',
                style: TextStyle(
                  color: _showPowerball
                      ? const Color(0xFFFF4757)
                      : Colors.white.withValues(alpha: 0.3),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _showPowerball
                      ? const RadialGradient(
                          center: Alignment(-0.3, -0.3),
                          radius: 0.8,
                          colors: [
                            Color(0xFFFF6B81),
                            Color(0xFFFF4757),
                            Color(0xFFCC2936),
                          ],
                        )
                      : RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.08),
                            Colors.white.withValues(alpha: 0.03),
                          ],
                        ),
                  boxShadow: _showPowerball
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFF4757)
                                .withValues(alpha: 0.5),
                            blurRadius: 16,
                            spreadRadius: -2,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    _showPowerball ? '${_currentResult!.powerball}' : '?',
                    style: TextStyle(
                      color: _showPowerball
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.2),
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      shadows: _showPowerball
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildResultDisplay() {
    if (_currentResult == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.05),
              Colors.white.withValues(alpha: 0.02),
            ],
          ),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Center(
          child: Text(
            '추첨 버튼을 눌러 파워볼을 뽑아보세요!',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    final allRevealed = _revealedNumbers.length == 5 && _showPowerball;
    return AnimatedOpacity(
      opacity: allRevealed ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF4757), Color(0xFFCC2936)],
          ),
          border: Border.all(
            color: const Color(0xFFFF6B81).withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF4757).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bolt, color: Color(0xFFFFD700), size: 20),
              const SizedBox(width: 6),
              ...List.generate(5, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Text(
                    '${_currentResult!.numbers[i]}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                );
              }),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '+',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'P ${_currentResult!.powerball}',
                  style: const TextStyle(
                    color: Color(0xFF1A1A2E),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.bolt, color: Color(0xFFFFD700), size: 20),
            ],
          ),
        ),
      ),
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
                child: _PowerballDrawButton(
                  onPressed: _isDrawing ? null : _startDraw,
                  isDrawing: _isDrawing,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PowerballBuyButton(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _PowerballAiButton(
            onPressed: _isDrawing
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const PowerballAiPage()),
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
              itemBuilder: (context, index) {
                return _PowerballHistoryRow(result: _history[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfettiOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: _PowerballConfetti(key: ValueKey(_drawCount)),
      ),
    );
  }
}

// ── 버튼 위젯 ──

class _PowerballDrawButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isDrawing;

  const _PowerballDrawButton({
    required this.onPressed,
    required this.isDrawing,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFFF4757), Color(0xFFFF6B81), Color(0xFFFF8A9B)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4757).withValues(alpha: 0.35),
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
                  isDrawing ? Icons.hourglass_top : Icons.bolt,
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

class _PowerballAiButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _PowerballAiButton({required this.onPressed});

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

class _PowerballBuyButton extends StatelessWidget {
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
                Uri.parse('https://el.dhlottery.co.kr/game/TotalGame.jsp?LottoId=LD14'),
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
                Text(
                  '구매',
                  style: TextStyle(
                    color: Colors.white,
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

// ── 이력 행 ──

class _PowerballHistoryRow extends StatelessWidget {
  final PowerballResult result;

  const _PowerballHistoryRow({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom:
              BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              child: Text(
                '${result.round}회',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 4),
            ...result.numbers.map((n) => _SmallBall(number: n)),
            const SizedBox(width: 6),
            Text('+',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 13,
                )),
            const SizedBox(width: 6),
            _SmallPowerball(number: result.powerball),
          ],
        ),
      ),
    );
  }
}

class _SmallBall extends StatelessWidget {
  final int number;

  const _SmallBall({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF5B9CFF), Color(0xFF3B7DDB)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$number',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SmallPowerball extends StatelessWidget {
  final int number;

  const _SmallPowerball({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B81), Color(0xFFFF4757)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4757).withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$number',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ── 컨페티 ──

class _PowerballConfetti extends StatefulWidget {
  const _PowerballConfetti({super.key});

  @override
  State<_PowerballConfetti> createState() => _PowerballConfettiState();
}

class _PowerballConfettiState extends State<_PowerballConfetti>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _particles = List.generate(40, (_) => _Particle(rng));
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
          painter:
              _ConfettiPainter(particles: _particles, progress: _controller.value),
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
          const Color(0xFFFF4757),
          const Color(0xFFFF6B81),
          const Color(0xFF5B9CFF),
          const Color(0xFF3B7DDB),
          const Color(0xFFFFD700),
          const Color(0xFF6BCB77),
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
      final x =
          p.x * size.width + sin(progress * pi * 3 + p.rotation) * 30 * p.drift;
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
