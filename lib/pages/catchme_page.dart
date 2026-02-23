import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/catchme_result.dart';
import '../services/sound_service.dart';
import 'catchme_ai_page.dart';

class CatchmePage extends StatefulWidget {
  const CatchmePage({super.key});

  @override
  State<CatchmePage> createState() => _CatchmePageState();
}

class _CatchmePageState extends State<CatchmePage>
    with TickerProviderStateMixin {
  int _drawCount = 0;
  bool _isDrawing = false;
  int? _selectedNumber;
  CatchmeResult? _currentResult;
  bool _revealed = false;
  final List<CatchmeResult> _history = [];
  bool _showConfetti = false;
  final SoundService _sound = SoundService();

  late AnimationController _revealController;
  late AnimationController _glowController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _sound.init();
    _sound.setGameType(GameType.catchme);
    _revealController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _revealController.dispose();
    _glowController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Color _ballColor(int number) {
    if (number <= 9) return const Color(0xFFFF6B9D);
    if (number <= 18) return const Color(0xFFE91E63);
    if (number <= 27) return const Color(0xFFC2185B);
    if (number <= 36) return const Color(0xFFAD1457);
    return const Color(0xFF880E4F);
  }

  Future<void> _startDraw() async {
    if (_isDrawing || _selectedNumber == null) return;

    setState(() {
      _isDrawing = true;
      _showConfetti = false;
      _revealed = false;
      _drawCount++;
      _currentResult =
          CatchmeResult.generate(_drawCount, _selectedNumber!);
    });

    _sound.playStart();
    _glowController.repeat(reverse: true);

    for (int i = 0; i < 15; i++) {
      if (!mounted) return;
      if (i % 3 == 0) _sound.playBounce();
      setState(() {});
      await Future.delayed(Duration(milliseconds: 80 + i * 20));
    }

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    _glowController.stop();
    _glowController.value = 0;
    _sound.playWhoosh();
    _revealController.forward(from: 0);

    setState(() => _revealed = true);

    if (_currentResult!.isMatch) {
      _sound.playHit();
      _pulseController.repeat(reverse: true);
      setState(() => _showConfetti = true);
      await Future.delayed(const Duration(milliseconds: 3000));
      _pulseController.stop();
      _pulseController.value = 0;
    } else {
      _sound.playMiss();
      await Future.delayed(const Duration(milliseconds: 1500));
    }

    if (!mounted) return;

    setState(() {
      _isDrawing = false;
      _history.insert(0, _currentResult!);
    });

    if (_showConfetti) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) setState(() => _showConfetti = false);
    }
  }

  void _reset() {
    _glowController.stop();
    _glowController.value = 0;
    _revealController.reset();
    _pulseController.stop();
    _pulseController.value = 0;
    setState(() {
      _isDrawing = false;
      _drawCount = 0;
      _selectedNumber = null;
      _currentResult = null;
      _revealed = false;
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
                          const SizedBox(height: 14),
                          _buildMatchArea(),
                          const SizedBox(height: 14),
                          _buildNumberGrid(),
                          const SizedBox(height: 14),
                          _buildButtons(),
                          const SizedBox(height: 14),
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
                  '🎯 캐치미',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '1개 번호를 골라 맞춰보세요!',
                  style: TextStyle(
                    color: Color(0xFFFF80AB),
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

  Widget _buildMatchArea() {
    return AnimatedBuilder(
      animation: Listenable.merge([_glowController, _pulseController]),
      builder: (context, _) {
        final glow = _glowController.value;
        final pulse = _pulseController.value;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2A1525),
                Color(0xFF1E0F1A),
                Color(0xFF160A14),
              ],
            ),
            border: Border.all(
              color: Color.lerp(
                const Color(0xFF5A2050),
                const Color(0xFFFF80AB),
                glow * 0.5 + pulse * 0.5,
              )!,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE91E63)
                    .withValues(alpha: 0.1 + glow * 0.12),
                blurRadius: 20 + glow * 12,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMyBall(),
              _buildVsLabel(),
              _buildDrawnBall(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMyBall() {
    return Column(
      children: [
        _buildSetLabel('MY PICK', const Color(0xFFFF80AB)),
        const SizedBox(height: 8),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: _selectedNumber != null
                ? RadialGradient(
                    center: const Alignment(-0.3, -0.3),
                    radius: 0.8,
                    colors: [
                      Color.lerp(
                          _ballColor(_selectedNumber!), Colors.white, 0.35)!,
                      _ballColor(_selectedNumber!),
                      Color.lerp(
                          _ballColor(_selectedNumber!), Colors.black, 0.2)!,
                    ],
                  )
                : null,
            color: _selectedNumber == null
                ? Colors.white.withValues(alpha: 0.06)
                : null,
            boxShadow: _selectedNumber != null
                ? [
                    BoxShadow(
                      color: _ballColor(_selectedNumber!)
                          .withValues(alpha: 0.5),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              _selectedNumber != null ? '$_selectedNumber' : '?',
              style: TextStyle(
                color: _selectedNumber != null
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.2),
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVsLabel() {
    final matchResult = _revealed && _currentResult != null;
    return Column(
      children: [
        const SizedBox(height: 24),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: matchResult
              ? Text(
                  _currentResult!.isMatch ? '🎉' : '💔',
                  key: ValueKey(_currentResult!.isMatch),
                  style: const TextStyle(fontSize: 32),
                )
              : Text(
                  'VS',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildDrawnBall() {
    final hasDrawn = _revealed && _currentResult != null;
    final num = hasDrawn ? _currentResult!.drawnNumber : null;
    final isMatch = hasDrawn && _currentResult!.isMatch;

    return Column(
      children: [
        _buildSetLabel('DRAWN', const Color(0xFFFFD700)),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _revealController,
          builder: (context, _) {
            final scale = hasDrawn
                ? 1.0 +
                    (1 - _revealController.value).clamp(0.0, 1.0) * 0.3
                : 1.0;
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: hasDrawn
                      ? RadialGradient(
                          center: const Alignment(-0.3, -0.3),
                          radius: 0.8,
                          colors: isMatch
                              ? [
                                  const Color(0xFFFFF176),
                                  const Color(0xFFFFD700),
                                  const Color(0xFFFF8F00),
                                ]
                              : [
                                  Color.lerp(
                                      _ballColor(num!), Colors.white, 0.35)!,
                                  _ballColor(num),
                                  Color.lerp(
                                      _ballColor(num), Colors.black, 0.2)!,
                                ],
                        )
                      : null,
                  color: hasDrawn
                      ? null
                      : Colors.white.withValues(alpha: 0.06),
                  boxShadow: hasDrawn
                      ? [
                          BoxShadow(
                            color: (isMatch
                                    ? const Color(0xFFFFD700)
                                    : _ballColor(num!))
                                .withValues(alpha: 0.5),
                            blurRadius: 14,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    hasDrawn ? '$num' : '?',
                    style: TextStyle(
                      color: hasDrawn
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.2),
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      shadows: hasDrawn
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
            );
          },
        ),
      ],
    );
  }

  Widget _buildSetLabel(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildNumberGrid() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.03),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '번호를 선택하세요 (1~45)',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // 5열 x 9행 그리드
          ...List.generate(9, (row) {
            return Padding(
              padding: EdgeInsets.only(top: row > 0 ? 4 : 0),
              child: Row(
                children: List.generate(5, (col) {
                  final num = row * 5 + col + 1;
                  if (num > 45) return const Expanded(child: SizedBox());
                  final selected = _selectedNumber == num;
                  final c = _ballColor(num);
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: col > 0 ? 4 : 0),
                      child: GestureDetector(
                        onTap: _isDrawing
                            ? null
                            : () => setState(() => _selectedNumber = num),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: selected
                                  ? RadialGradient(
                                      center: const Alignment(-0.3, -0.3),
                                      radius: 0.8,
                                      colors: [
                                        Color.lerp(c, Colors.white, 0.3)!,
                                        c,
                                        Color.lerp(c, Colors.black, 0.15)!,
                                      ],
                                    )
                                  : null,
                              color: selected
                                  ? null
                                  : Colors.white.withValues(alpha: 0.06),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: c.withValues(alpha: 0.4),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '$num',
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : Colors.white
                                            .withValues(alpha: 0.5),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
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
                child: _DrawButton(
                  onPressed: (_isDrawing || _selectedNumber == null)
                      ? null
                      : _startDraw,
                  isDrawing: _isDrawing,
                  hasSelection: _selectedNumber != null,
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
                          builder: (_) => const CatchmeAiPage()),
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
      constraints: const BoxConstraints(maxHeight: 200),
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
                final r = _history[index];
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                          color: Colors.white.withValues(alpha: 0.05)),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 34,
                        child: Text(
                          '${r.round}회',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 10,
                          ),
                        ),
                      ),
                      _miniBall(r.myNumber, _ballColor(r.myNumber)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          'vs',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3),
                            fontSize: 10,
                          ),
                        ),
                      ),
                      _miniBall(
                        r.drawnNumber,
                        r.isMatch
                            ? const Color(0xFFFFD700)
                            : _ballColor(r.drawnNumber),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: r.isMatch
                              ? const Color(0xFFFFD700)
                                  .withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.06),
                        ),
                        child: Text(
                          r.isMatch ? '적중!' : '미적중',
                          style: TextStyle(
                            color: r.isMatch
                                ? const Color(0xFFFFD700)
                                : Colors.white.withValues(alpha: 0.4),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniBall(int n, Color c) {
    return Container(
      width: 28,
      height: 28,
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
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildConfettiOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: _CatchConfetti(key: ValueKey(_drawCount)),
      ),
    );
  }
}

// ── 버튼 ──

class _DrawButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isDrawing;
  final bool hasSelection;

  const _DrawButton({
    required this.onPressed,
    required this.isDrawing,
    required this.hasSelection,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFFC2185B), Color(0xFFAD1457)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE91E63).withValues(alpha: 0.35),
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
                  isDrawing
                      ? Icons.hourglass_top
                      : hasSelection
                          ? Icons.play_arrow
                          : Icons.touch_app,
                  color: Colors.white.withValues(alpha: enabled ? 1 : 0.5),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  isDrawing
                      ? '추첨 중...'
                      : hasSelection
                          ? '캐치!'
                          : '번호 선택',
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
                Uri.parse('https://el.dhlottery.co.kr/game/TotalGame.jsp?LottoId=LI23'),
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

// ── 컨페티 ──

class _CatchConfetti extends StatefulWidget {
  const _CatchConfetti({super.key});

  @override
  State<_CatchConfetti> createState() => _CatchConfettiState();
}

class _CatchConfettiState extends State<_CatchConfetti>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _particles = List.generate(50, (_) => _Particle(rng));
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2500),
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
        size = 4 + r.nextDouble() * 7,
        drift = (r.nextDouble() - 0.5) * 0.3,
        rotation = r.nextDouble() * pi * 2,
        color = [
          const Color(0xFFFF80AB),
          const Color(0xFFE91E63),
          const Color(0xFFFFD700),
          const Color(0xFFF48FB1),
          const Color(0xFFFF6090),
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
