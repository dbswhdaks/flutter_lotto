import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/lotto_result.dart';
import '../services/sound_service.dart';
import '../widgets/lotto_ball.dart';
import '../widgets/lotto_machine.dart';
import '../widgets/result_panel.dart';
import '../widgets/history_panel.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/traveling_ball.dart';
import 'ai_page.dart';

class LottoHomePage extends StatefulWidget {
  const LottoHomePage({super.key});

  @override
  State<LottoHomePage> createState() => _LottoHomePageState();
}

class _LottoHomePageState extends State<LottoHomePage> {
  int _drawCount = 0;
  bool _isDrawing = false;
  bool _showConfetti = false;
  LottoResult? _currentResult;
  List<int> _revealedNumbers = [];
  bool _showPlus = false;
  bool _showBonus = false;
  final List<LottoResult> _history = [];
  final GlobalKey<LottoMachineState> _machineKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  final SoundService _sound = SoundService();

  int? _travelingNumber;
  Duration _travelDuration = const Duration(milliseconds: 1100);
  Completer<void>? _arrivalCompleter;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _sound.init();
    _sound.setGameType(GameType.lotto);
  }

  static const double _sphereSize = 290;
  static const double _headerHeight = 80;
  static const double _machineAreaTop = _headerHeight;
  static const double _sphereScreenTop = _machineAreaTop + 50;
  static const double _sphereRadius = _sphereSize / 2;
  static const double _sphereCenterY = _sphereScreenTop + _sphereRadius;
  static const double _tubeTopY = _machineAreaTop + 2;

  Path _buildUpwardPath(double screenWidth) {
    final cx = screenWidth / 2;
    return Path()
      ..moveTo(cx, _sphereCenterY)
      ..lineTo(cx, _tubeTopY - 30);
  }

  Future<void> _startDraw() async {
    if (_isDrawing) return;

    setState(() {
      _isDrawing = true;
      _showConfetti = false;
      _drawCount++;
      _revealedNumbers = [];
      _showPlus = false;
      _showBonus = false;
      _currentResult = LottoResult.generate(_drawCount);
    });

    _sound.playStart();

    if (_scrollController.offset > 0) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }

    await Future.delayed(const Duration(milliseconds: 400));

    _sound.playMixing();

    for (int i = 0; i < 6; i++) {
      _sound.playBounce();
      _machineKey.currentState?.boostBalls();
      final waitBefore = 450 + _random.nextInt(250);
      await Future.delayed(Duration(milliseconds: waitBefore));
      if (!mounted) return;

      _sound.playWhoosh();
      _arrivalCompleter = Completer<void>();
      final travelMs = 900 + _random.nextInt(500);
      setState(() {
        _travelingNumber = _currentResult!.mainNumbers[i];
        _travelDuration = Duration(milliseconds: travelMs);
      });

      await _arrivalCompleter!.future;
      if (!mounted) return;

      _sound.playBall(i);

      setState(() {
        _travelingNumber = null;
        _revealedNumbers = List.from(_revealedNumbers)
          ..add(_currentResult!.mainNumbers[i]);
      });

      final waitAfter = 180 + _random.nextInt(180);
      await Future.delayed(Duration(milliseconds: waitAfter));
    }

    await Future.delayed(Duration(milliseconds: 400 + _random.nextInt(200)));

    setState(() {
      _showPlus = true;
    });

    await Future.delayed(Duration(milliseconds: 500 + _random.nextInt(200)));

    _sound.playBounce();
    _machineKey.currentState?.boostBalls();
    await Future.delayed(Duration(milliseconds: 350 + _random.nextInt(200)));

    _sound.playWhoosh();
    _arrivalCompleter = Completer<void>();
    final bonusTravelMs = 900 + _random.nextInt(500);
    setState(() {
      _travelingNumber = _currentResult!.bonusNumber;
      _travelDuration = Duration(milliseconds: bonusTravelMs);
    });

    await _arrivalCompleter!.future;
    if (!mounted) return;

    _sound.playBall(6);

    setState(() {
      _travelingNumber = null;
      _showBonus = true;
    });

    _sound.stopMixing();

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    _sound.playComplete();

    setState(() {
      _isDrawing = false;
      _showConfetti = true;
      _history.insert(0, _currentResult!);
    });

    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) setState(() => _showConfetti = false);
  }

  void _onBallArrived() {
    _arrivalCompleter?.complete();
  }

  void _reset() {
    setState(() {
      _isDrawing = false;
      _drawCount = 0;
      _currentResult = null;
      _revealedNumbers = [];
      _showPlus = false;
      _showBonus = false;
      _history.clear();
      _showConfetti = false;
      _travelingNumber = null;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final upwardPath = _buildUpwardPath(screenWidth);

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
              SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.1),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                            ),
                          ),
                          const Expanded(
                            child: Text(
                              '🎱 6/45 로또 번호 생성기',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 36),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '행운의 번호를 뽑아보세요!',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        LottoMachine(
                          key: _machineKey,
                          isSpinning: _isDrawing,
                          sphereSize: _sphereSize,
                          excludeNumbers: _currentResult != null
                              ? [
                                  ..._currentResult!.mainNumbers,
                                  _currentResult!.bonusNumber,
                                ]
                              : null,
                        ),
                        Positioned(
                          right: (MediaQuery.of(context).size.width - _sphereSize) / 2 - 36,
                          bottom: 40,
                          child: _ResetButton(onPressed: _reset),
                        ),
                      ],
                    ),
                    Transform.translate(
                      offset: const Offset(0, -12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ResultPanel(
                          result: _currentResult,
                          revealedNumbers: _revealedNumbers,
                          showPlus: _showPlus,
                          showBonus: _showBonus,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: _DrawButton(
                              onPressed: _isDrawing ? null : _startDraw,
                              isDrawing: _isDrawing,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _AiButton(
                              onPressed: _isDrawing
                                  ? null
                                  : () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const AiPage()),
                                      );
                                    },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _TodayLuckyNumbers(),
                    const SizedBox(height: 20),
                    HistoryPanel(history: _history),
                    const SizedBox(height: 30),
                  ],
                ),
              ),

              // 위로 올라가는 추첨 공
              if (_travelingNumber != null)
                TravelingBall(
                  key: ValueKey(
                      'ball_${_travelingNumber}_${_revealedNumbers.length}'),
                  number: _travelingNumber!,
                  path: upwardPath,
                  onArrived: _onBallArrived,
                  duration: _travelDuration,
                ),

              Positioned.fill(
                child: IgnorePointer(
                  child: ConfettiOverlay(trigger: _showConfetti),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isDrawing;

  const _DrawButton({required this.onPressed, required this.isDrawing});

  @override
  State<_DrawButton> createState() => _DrawButtonState();
}

class _DrawButtonState extends State<_DrawButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        final glowOpacity = widget.isDrawing ? 0.1 : 0.2 + _pulseAnim.value * 0.25;
        return Container(
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.isDrawing
                  ? [const Color(0xFF5B21B6), const Color(0xFF7C3AED)]
                  : [const Color(0xFF7C3AED), const Color(0xFFA855F7)],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withValues(alpha: glowOpacity),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: const Color(0xFFA855F7).withValues(alpha: glowOpacity * 0.5),
                blurRadius: 40,
                spreadRadius: -4,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: widget.onPressed,
          child: Stack(
            children: [
              Positioned(
                top: -10,
                right: -10,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      child: Icon(
                        widget.isDrawing ? Icons.hourglass_top : Icons.casino_rounded,
                        color: Colors.white.withValues(alpha: enabled ? 1 : 0.5),
                        size: 19,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.isDrawing ? '추첨 중...' : '추첨 시작',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: enabled ? 1 : 0.5),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResetButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _ResetButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.3),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Icon(
          Icons.refresh,
          color: Colors.white.withValues(alpha: enabled ? 0.9 : 0.4),
          size: 27,
        ),
      ),
    );
  }
}

class _AiButton extends StatefulWidget {
  final VoidCallback? onPressed;

  const _AiButton({required this.onPressed});

  @override
  State<_AiButton> createState() => _AiButtonState();
}

class _AiButtonState extends State<_AiButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _shimmerAnim = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;

    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (context, child) {
        return Container(
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0EA5E9), Color(0xFF3B82F6), Color(0xFF6366F1)],
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                blurRadius: 16,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                blurRadius: 30,
                spreadRadius: -4,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: widget.onPressed,
          child: Stack(
            children: [
              Positioned(
                bottom: -8,
                left: -8,
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.2),
                            Colors.white.withValues(alpha: 0.08),
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: Colors.white.withValues(alpha: enabled ? 1 : 0.5),
                        size: 19,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AI 번호 생성기',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: enabled ? 1 : 0.5),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayLuckyNumbers extends StatefulWidget {
  const _TodayLuckyNumbers();

  @override
  State<_TodayLuckyNumbers> createState() => _TodayLuckyNumbersState();
}

class _TodayLuckyNumbersState extends State<_TodayLuckyNumbers>
    with SingleTickerProviderStateMixin {
  late List<int> _luckyNumbers;
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _luckyNumbers = _generateLucky();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  }

  List<int> _generateLucky() {
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    final rng = Random(seed + _random.nextInt(1000));
    final numbers = <int>{};
    while (numbers.length < 6) {
      numbers.add(rng.nextInt(45) + 1);
    }
    return numbers.toList()..sort();
  }

  void _refresh() {
    setState(() {
      _luckyNumbers = _generateLucky();
    });
    _controller.reset();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getTodayDateString() {
    final now = DateTime.now();
    const weekDays = ['월', '화', '수', '목', '금', '토', '일'];
    final wd = weekDays[now.weekday - 1];
    return '${now.year}.${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')} ($wd)';
  }

  String _getLuckyMessage() {
    final messages = [
      '오늘 행운이 함께합니다!',
      '좋은 기운이 넘치는 날이에요!',
      '오늘의 특별한 번호를 확인하세요!',
      '행운의 번호가 당신을 기다려요!',
      '대박의 기운을 느껴보세요!',
    ];
    final now = DateTime.now();
    return messages[(now.day + now.month) % messages.length];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF59E0B).withValues(alpha: 0.12),
              const Color(0xFFF97316).withValues(alpha: 0.08),
              const Color(0xFFEF4444).withValues(alpha: 0.06),
            ],
          ),
          border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.stars_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '오늘의 행운 추천번호',
                          style: TextStyle(
                            color: Color(0xFFFBBF24),
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getTodayDateString(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _refresh,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: const Icon(
                        Icons.refresh_rounded,
                        color: Color(0xFFFBBF24),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < _luckyNumbers.length; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      LottoBall(number: _luckyNumbers[i], size: 42),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: const Color(0xFFFBBF24).withValues(alpha: 0.5),
                    size: 13,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getLuckyMessage(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

