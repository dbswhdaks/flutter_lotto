import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/megabingo_result.dart';
import '../services/sound_service.dart';
import 'megabingo_ai_page.dart';

class MegabingoPage extends StatefulWidget {
  const MegabingoPage({super.key});

  @override
  State<MegabingoPage> createState() => _MegabingoPageState();
}

class _MegabingoPageState extends State<MegabingoPage>
    with TickerProviderStateMixin {
  int _drawCount = 0;
  bool _isDrawing = false;
  MegabingoResult? _currentResult;
  final Set<int> _revealedDrawn = {}; // 지금까지 공개된 추첨 번호
  int _revealIndex = 0;
  final List<MegabingoResult> _history = [];
  bool _showConfetti = false;
  final SoundService _sound = SoundService();

  late AnimationController _glowController;
  late AnimationController _bingoFlashController;

  @override
  void initState() {
    super.initState();
    _sound.init();
    _sound.setGameType(GameType.megabingo);
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _bingoFlashController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _bingoFlashController.dispose();
    super.dispose();
  }

  Future<void> _startDraw() async {
    if (_isDrawing) return;

    setState(() {
      _isDrawing = true;
      _showConfetti = false;
      _drawCount++;
      _revealedDrawn.clear();
      _revealIndex = 0;
      _currentResult = MegabingoResult.generate(_drawCount);
    });

    _sound.playStart();
    _glowController.repeat(reverse: true);
    await Future.delayed(const Duration(milliseconds: 400));

    for (int i = 0; i < 20; i++) {
      if (!mounted) return;
      _sound.playBounce();
      setState(() {
        _revealedDrawn.add(_currentResult!.drawnNumbers[i]);
        _revealIndex = i + 1;
      });
      _sound.playBall(i % 7);
      await Future.delayed(const Duration(milliseconds: 180));
    }

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    _glowController.stop();
    _glowController.value = 0;

    if (_currentResult!.bingoCount > 0) {
      _sound.playHit();
      _bingoFlashController.repeat(reverse: true);
      await Future.delayed(const Duration(milliseconds: 1200));
      _bingoFlashController.stop();
      _bingoFlashController.value = 0;
    }

    _sound.playComplete();
    setState(() {
      _isDrawing = false;
      _showConfetti = _currentResult!.bingoCount > 0;
      _history.insert(0, _currentResult!);
    });

    if (_showConfetti) {
      await Future.delayed(const Duration(milliseconds: 2500));
      if (mounted) setState(() => _showConfetti = false);
    }
  }

  void _reset() {
    _glowController.stop();
    _glowController.value = 0;
    _bingoFlashController.stop();
    _bingoFlashController.value = 0;
    setState(() {
      _isDrawing = false;
      _drawCount = 0;
      _currentResult = null;
      _revealedDrawn.clear();
      _revealIndex = 0;
      _history.clear();
      _showConfetti = false;
    });
  }

  Color _numColor(int number) {
    if (number <= 10) return const Color(0xFFE74C8B);
    if (number <= 20) return const Color(0xFFFF922B);
    if (number <= 30) return const Color(0xFF2ECC71);
    return const Color(0xFF4D96FF);
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
                          _buildBingoGrid(),
                          const SizedBox(height: 10),
                          _buildDrawnNumbers(),
                          const SizedBox(height: 10),
                          _buildBingoStatus(),
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
                  '🎯 메가빙고',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '4×4 빙고판으로 행운을!',
                  style: TextStyle(
                    color: Color(0xFFDA70D6),
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

  Widget _buildBingoGrid() {
    final completedLineIndices = <int>{};
    if (_currentResult != null && _revealIndex == 20) {
      for (final line in _currentResult!.completedLines) {
        completedLineIndices.addAll(line);
      }
    }

    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final glow = _glowController.value;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2D1B4E),
                Color(0xFF1E1040),
                Color(0xFF180D35),
              ],
            ),
            border: Border.all(
              color: Color.lerp(
                const Color(0xFF5A3D7A),
                const Color(0xFFDA70D6),
                glow * 0.5,
              )!,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFDA70D6)
                    .withValues(alpha: 0.08 + glow * 0.12),
                blurRadius: 20 + glow * 12,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Column(
            children: List.generate(4, (row) {
              return Padding(
                padding: EdgeInsets.only(top: row > 0 ? 6 : 0),
                child: Row(
                  children: List.generate(4, (col) {
                    final idx = row * 4 + col;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: col > 0 ? 6 : 0),
                        child: _buildBingoCell(
                          idx,
                          completedLineIndices.contains(idx),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildBingoCell(int index, bool isOnBingoLine) {
    final hasCard = _currentResult != null && index < _currentResult!.cardNumbers.length;
    final number = hasCard ? _currentResult!.cardNumbers[index] : null;
    final isMatched = number != null && _revealedDrawn.contains(number);

    return AnimatedBuilder(
      animation: _bingoFlashController,
      builder: (context, _) {
        final flashVal =
            isOnBingoLine ? _bingoFlashController.value : 0.0;
        final baseColor = isMatched
            ? (isOnBingoLine
                ? Color.lerp(
                    const Color(0xFFDA70D6),
                    const Color(0xFFFF6B9D),
                    flashVal,
                  )!
                : const Color(0xFF8E44AD))
            : Colors.white.withValues(alpha: 0.06);

        return AspectRatio(
          aspectRatio: 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: isMatched
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(baseColor, Colors.white, 0.15)!,
                        baseColor,
                        Color.lerp(baseColor, Colors.black, 0.1)!,
                      ],
                    )
                  : null,
              color: isMatched ? null : baseColor,
              border: isOnBingoLine
                  ? Border.all(
                      color: const Color(0xFFFFD700)
                          .withValues(alpha: 0.5 + flashVal * 0.5),
                      width: 2,
                    )
                  : null,
              boxShadow: isMatched
                  ? [
                      BoxShadow(
                        color: baseColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: -1,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: number != null
                      ? Text(
                          '$number',
                          style: TextStyle(
                            color: isMatched
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.8),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            shadows: isMatched
                                ? const [
                                    Shadow(
                                      color: Color(0x66000000),
                                      offset: Offset(0, 1),
                                      blurRadius: 3,
                                    ),
                                  ]
                                : null,
                          ),
                        )
                      : Text(
                          '?',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.15),
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawnNumbers() {
    if (_currentResult == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.casino,
                  color: Colors.white.withValues(alpha: 0.5), size: 14),
              const SizedBox(width: 6),
              Text(
                '추첨 번호 ($_revealIndex/20)',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: List.generate(20, (i) {
              final revealed = i < _revealIndex;
              final num = revealed ? _currentResult!.drawnNumbers[i] : null;
              final c = num != null ? _numColor(num) : Colors.white.withValues(alpha: 0.08);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: revealed
                      ? LinearGradient(
                          colors: [c, Color.lerp(c, Colors.black, 0.15)!],
                        )
                      : null,
                  color: revealed ? null : c,
                ),
                child: Center(
                  child: Text(
                    revealed ? '$num' : '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildBingoStatus() {
    if (_currentResult == null || _revealIndex < 20) {
      return const SizedBox.shrink();
    }
    final count = _currentResult!.bingoCount;
    final matchCount = _currentResult!.matchedIndices.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: count > 0
              ? [
                  const Color(0xFFDA70D6).withValues(alpha: 0.2),
                  const Color(0xFF8E44AD).withValues(alpha: 0.15),
                ]
              : [
                  Colors.white.withValues(alpha: 0.05),
                  Colors.white.withValues(alpha: 0.03),
                ],
        ),
        border: Border.all(
          color: count > 0
              ? const Color(0xFFDA70D6).withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            count > 0 ? '🎉' : '📋',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              Text(
                count > 0 ? '빙고 $count줄 완성!' : '빙고 없음',
                style: TextStyle(
                  color: count > 0
                      ? const Color(0xFFDA70D6)
                      : Colors.white.withValues(alpha: 0.6),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '16칸 중 $matchCount개 매칭',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
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
                          builder: (_) => const MegabingoAiPage()),
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
                      Expanded(
                        child: Text(
                          '매칭 ${r.matchedIndices.length}/16',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: r.bingoCount > 0
                              ? const Color(0xFFDA70D6).withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.06),
                        ),
                        child: Text(
                          r.bingoCount > 0
                              ? '빙고 ${r.bingoCount}줄'
                              : '빙고 없음',
                          style: TextStyle(
                            color: r.bingoCount > 0
                                ? const Color(0xFFDA70D6)
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

  Widget _buildConfettiOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: _BingoConfetti(key: ValueKey(_drawCount)),
      ),
    );
  }
}

// ── 버튼 위젯 ──

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
          colors: [Color(0xFFDA70D6), Color(0xFF8E44AD), Color(0xFF7D3C98)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDA70D6).withValues(alpha: 0.35),
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
                  isDrawing ? Icons.hourglass_top : Icons.grid_view_rounded,
                  color: Colors.white.withValues(alpha: enabled ? 1 : 0.5),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  isDrawing ? '추첨 중...' : '빙고 추첨',
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
                Uri.parse('https://el.dhlottery.co.kr/game/TotalGame.jsp?LottoId=LD11'),
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

class _BingoConfetti extends StatefulWidget {
  const _BingoConfetti({super.key});

  @override
  State<_BingoConfetti> createState() => _BingoConfettiState();
}

class _BingoConfettiState extends State<_BingoConfetti>
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
          const Color(0xFFDA70D6),
          const Color(0xFF8E44AD),
          const Color(0xFFFFD700),
          const Color(0xFF4D96FF),
          const Color(0xFFFF6B6B),
          const Color(0xFF2ECC71),
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
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.6),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}
